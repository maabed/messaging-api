# defmodule Talk.Search do
#   import Ecto.Query, warn: false
#   require Logger

#   alias Talk.Repo
#   alias Talk.Schemas.User
#   alias Talk.Schemas.Profile
#   alias Ecto.Adapters.SQL

#   @sim_limit 0.05

#   # When query is empty, just return an array
#   def users(query, _user) when byte_size(query) == 0, do: []

#   # When queries are 1-2 characters, we can't use trigram search so we check
#   # if any items start with the query and assign them a score of 1.0, and then
#   # we check if any items contain but don't start with the query and assign
#   # them a score of 0.5
#   def users(%User{profile_id: profile_id}, query) when byte_size(query) < 3 do
#     sql = """
#       SELECT * FROM
#       (
#         (SELECT DISTINCT on(id) * FROM
#           (
#             (
#               SELECT id, profile_id, username, display_name, email, avatar, 1.0::float AS score
#               FROM users
#               LEFT JOIN followers f ON f.follower_id = $3
#               LEFT JOIN blocked_profiles b ON b.blocked_by_id = $3 AND b.blocked_profile_id = profile_id
#               WHERE (username ILIKE $1 OR display_name ILIKE $1) AND b.blocked_by_id IS NULL
#             )
#             UNION
#             (
#               SELECT id, profile_id, username, display_name, email, avatar, 0.5::float AS score
#               FROM users
#               LEFT JOIN followers f ON f.follower_id = $3
#               LEFT JOIN blocked_profiles b ON b.blocked_by_id = $3 AND b.blocked_profile_id = profile_id
#               WHERE (username ~* $2 OR display_name ~* $2) AND b.blocked_by_id IS NULL
#             )
#           ) u ORDER BY id, score DESC
#         )
#       ) a
#       ORDER BY score DESC
#       LIMIT 10
#     """

#     result = SQL.query!(Repo, sql, ["#{query}%", query, profile_id])
#     to_json(result)
#   end

#   # When queries are 3+ characters, we can use Postgres trigram search
#   def users(%User{profile_id: profile_id} = _user, query) when byte_size(query) >= 3 do
#     sql = """
#       SELECT * FROM
#       (
#         (SELECT DISTINCT on(id) * FROM
#           (
#             SELECT id, profile_id, username, display_name, email, avatar, score
#             FROM (
#               SELECT *, SIMILARITY(username || ' ' || display_name, $1) AS score
#               FROM users
#               LEFT JOIN followers f ON f.follower_id = $2
#               LEFT JOIN blocked_profiles b ON b.blocked_by_id = $2 AND b.blocked_profile_id = profile_id
#               WHERE b.blocked_by_id IS NULL
#               ORDER BY score DESC
#             ) AS u
#             WHERE score > $3
#           ) a
#         )
#       ) z
#       ORDER BY score DESC
#       LIMIT 10
#     """

#     result = SQL.query!(Repo, sql, [query, profile_id, @sim_limit])
#     to_json(result)
#   end

#   def groups(query, _user) when byte_size(query) == 0, do: []

#   def groups(query, %User{profile_id: profile_id} = _user) when byte_size(query) < 3 do
#     sql = """
#       SELECT * FROM
#       (
#         (SELECT DISTINCT on(id) * FROM
#           (
#             (
#               SELECT g.id, g.name as group_name, g.status as group_status,
#                      u.id as user_id, u.username, u.display_name, u.email, u.avatar,
#                      gu.role, gu.status as user_status, gu.bookmarked, 1.0::float AS score
#               FROM groups AS g
#               JOIN group_users AS gu ON gu.profile_id = $3
#               JOIN group_users AS gu2 ON gu2.group_id = g.id AND gu.id != gu2.id
#               JOIN users AS u ON u.username ILIKE $1 OR u.display_name ILIKE $1
#               where g.status != 'DELETED' AND u.id = gu2.profile_id AND gu.group_id = g.id
#             )
#             UNION
#             (
#               SELECT g.id as id, g.name as group_name, g.status as group_status,
#                      u.id as user_id, u.username, u.display_name, u.email, u.avatar,
#                      gu.role, gu.status as user_status, gu.bookmarked, 0.5::float AS score
#               FROM groups AS g
#               JOIN group_users AS gu ON gu.profile_id = $3
#               JOIN group_users AS gu2 ON gu2.group_id = g.id AND gu.id != gu2.id
#               JOIN users AS u ON u.username ~* $2 OR u.display_name ~* $2
#               where g.status != 'DELETED' AND u.id = gu2.profile_id AND gu.group_id = g.id
#             )
#           ) u ORDER BY id, score DESC
#         )
#       ) a
#       ORDER BY score DESC
#       LIMIT 10
#     """

#     result = SQL.query!(Repo, sql, ["%#{query}%", query, profile_id ])
#     to_json(result)
#   end

#   def groups(query, %User{profile_id: profile_id}) when byte_size(query) >= 3 do
#     sql = """
#     (SELECT *
#       FROM(
#         SELECT g.id as id, g.name as group_name, g.status as group_status,
#                u.id as user_id, u.username, u.display_name, u.email, u.avatar,
#                gu.role, gu.status as user_status, gu.bookmarked, SIMILARITY(username || ' ' || display_name, $1) AS score
#         FROM groups AS g
#         JOIN group_users AS gu ON gu.profile_id = $2
#         JOIN group_users AS gu2 ON gu2.group_id = g.id AND gu.id != gu2.id
#         JOIN users AS u ON u.username IS NOT NULL || u.display_name IS NOT NULL
#         WHERE g.status != 'DELETED' AND u.id = gu2.profile_id AND gu.group_id = g.id
#       ) AS u
#       WHERE score > $3
#     )
#     ORDER BY username DESC
#     LIMIT 10
#     """

#     result = SQL.query!(Repo, sql, [query, profile_id, @sim_limit])
#     to_json(result)
#   end

#   def to_json(%Postgrex.Result{columns: columns, rows: rows}) do
#     results =
#       rows
#       |> Enum.map(fn row ->
#         columns
#         |> Enum.zip(row)
#         |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), v} end)
#       end)

#     {:ok, results}
#   end
# end
