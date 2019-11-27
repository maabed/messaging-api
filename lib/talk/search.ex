defmodule Talk.Search do
  import Ecto.Query, warn: false
  require Logger

  alias Talk.Repo
  alias Talk.Schemas.User
  alias Ecto.Adapters.SQL

  @sim_limit 0.05

  # When query is empty, just return an array
  def users(query, _user) when byte_size(query) == 0, do: []

  # When queries are 1-2 characters, we can't use trigram search so we check
  # if any items start with the query and assign them a score of 1.0, and then
  # we check if any items contain but don't start with the query and assign
  # them a score of 0.5
  def users(query, %User{profile_id: profile_id}) when byte_size(query) < 3 do
    sql = """
      SELECT * FROM
      (
        (SELECT DISTINCT on(id) * FROM
          (
            (
              SELECT id, profile_id, username, display_name, email, avatar, 1.0::float AS score
              FROM users
              LEFT JOIN followers f ON f.follower_id = $3
              LEFT JOIN blocked_profiles b ON b.blocked_by_id = $3
              WHERE username ILIKE $1 OR display_name ILIKE $1
            )
            UNION
            (
              SELECT id, profile_id, username, display_name, email, avatar, 0.5::float AS score
              FROM users
              LEFT JOIN followers f ON f.follower_id = $3
              LEFT JOIN blocked_profiles b ON b.blocked_by_id = $3
              WHERE username ~* $2 OR display_name ~* $2
            )
          ) u ORDER BY id, score DESC
        )
      ) a
      ORDER BY score DESC
      LIMIT 10
    """

    result = SQL.query!(Repo, sql, ["#{query}%", query, profile_id])
    to_json(result)
  end

  # When queries are 3+ characters, we can use Postgres trigram search
  def users(query, %User{profile_id: profile_id}) when byte_size(query) >= 3 do
    sql = """
    (
      SELECT id, profile_id, username, display_name, email, avatar, score
      FROM (
        SELECT *, SIMILARITY(username || ' ' || display_name, $1) AS score
        FROM users
        LEFT JOIN followers f ON f.follower_id = $2
        LEFT JOIN blocked_profiles b ON b.blocked_by_id = $2
        ORDER BY score DESC
      ) AS u
      WHERE score > $3
    )
    ORDER BY score DESC
    LIMIT 10
    """
    result = SQL.query!(Repo, sql, [query, profile_id, @sim_limit])
    to_json(result)
  end

  def groups(query, _user) when byte_size(query) == 0, do: []

  def groups(query, %User{id: user_id} = _user) when byte_size(query) < 3 do
    sql = """
      SELECT * FROM
      (
        (SELECT DISTINCT on(id) * FROM
          (
            (
              SELECT g.id, g.name as group_name, g.state as group_state,
                     u.id as user_id, u.username, u.display_name, u.email, u.avatar,
                     gu.role, gu.state as user_state, gu.bookmarked, 1.0::float AS score
              FROM groups AS g
              JOIN group_users AS gu ON gu.user_id = $3
              JOIN group_users AS gu2 ON gu2.group_id = g.id AND gu.id != gu2.id
              JOIN users AS u ON u.username ILIKE $1 OR u.display_name ILIKE $1
              where g.state != 'DELETED' AND u.id = gu2.user_id AND gu.group_id = g.id
            )
            UNION
            (
              SELECT g.id as id, g.name as group_name, g.state as group_state,
                     u.id as user_id, u.username, u.display_name, u.email, u.avatar,
                     gu.role, gu.state as user_state, gu.bookmarked, 0.5::float AS score
              FROM groups AS g
              JOIN group_users AS gu ON gu.user_id = $3
              JOIN group_users AS gu2 ON gu2.group_id = g.id AND gu.id != gu2.id
              JOIN users AS u ON u.username ~* $2 OR u.display_name ~* $2
              where g.state != 'DELETED' AND u.id = gu2.user_id AND gu.group_id = g.id
            )
          ) u ORDER BY id, score DESC
        )
      ) a
      ORDER BY score DESC
      LIMIT 10
    """

    result = SQL.query!(Repo, sql, ["%#{query}%", query, user_id ])
    to_json(result)
  end

  def groups(query, %User{id: user_id}) when byte_size(query) >= 3 do
    sql = """
    (SELECT *
      FROM(
        SELECT g.id as id, g.name as group_name, g.state as group_state,
               u.id as user_id, u.username, u.display_name, u.email, u.avatar,
               gu.role, gu.state as user_state, gu.bookmarked, SIMILARITY(username || ' ' || display_name, $1) AS score
        FROM groups AS g
        JOIN group_users AS gu ON gu.user_id = $2
        JOIN group_users AS gu2 ON gu2.group_id = g.id AND gu.id != gu2.id
        JOIN users AS u ON u.username IS NOT NULL || u.display_name IS NOT NULL
        WHERE g.state != 'DELETED' AND u.id = gu2.user_id AND gu.group_id = g.id
      ) AS u
      WHERE score > $3
    )
    ORDER BY username DESC
    LIMIT 10
    """

    result = SQL.query!(Repo, sql, [query, user_id, @sim_limit])
    to_json(result)
  end

  def to_json(%Postgrex.Result{columns: columns, rows: rows}) do
    rows
    |> Enum.map(fn row ->
      columns
      |> Enum.zip(row)
      |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), v} end)
    end)
  end
end
