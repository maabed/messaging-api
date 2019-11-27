defmodule Talk.Messages.Query do
  @moduledoc "Functions for building message queries."

  import Ecto.Query
  require Logger

  alias Talk.Schemas.{GroupUser, Message, MessageGroup, User, UserLog}

  @spec base_query(User.t()) :: Ecto.Query.t()
  def base_query(%User{id: user_id}) do
    query =
      from m in Message,
        join: u in User,
        on: u.id == ^user_id

    base_query_with_user(query, user_id)
  end

  defp base_query_with_user(query, user_id) do
    from [m, u] in query,
      left_join: g in assoc(m, :groups),
      left_join: gu in GroupUser,
      on: gu.user_id == u.id and gu.group_id == g.id,
      left_join: mg in MessageGroup,
      on: mg.user_id == u.id, # and mg.group_id == gu.group_id,
      where: gu.user_id == ^user_id and m.state != "DELETED" and g.is_private == true,
      distinct: m.id
  end

  @spec where_in_group(Ecto.Query.t(), String.t()) :: Ecto.Query.t()
  def where_in_group(query, group_id) do
    from [m, u, g, gu] in query,
      where: g.id == ^group_id
  end

  @spec select_last_activity_at(Ecto.Query.t()) :: Ecto.Query.t()
  def select_last_activity_at(query) do
    from [m, u, g, gu] in query,
      left_join: ul in UserLog,
      on: ul.message_id == m.id,
      group_by: m.id,
      select_merge: %{last_activity_at: max(ul.happen_at)}
  end

  @spec where_last_active_today(Ecto.Query.t(), DateTime.t()) :: Ecto.Query.t()
  def where_last_active_today(query, now) do
    where(
      query,
      [m, u, g, gu, ul],
      fragment(
        "date_trunc('day', timezone(?, ?::timestamptz)) = date_trunc('day', timezone(?, ?))",
        u.time_zone,
        ul.happen_at,
        u.time_zone,
        ^now
      )
    )
  end

  @spec where_last_active_after(Ecto.Query.t(), DateTime.t()) :: Ecto.Query.t()
  def where_last_active_after(query, timestamp) do
    from [m, u, g, gu, ul] in query,
      where: ul.happen_at >= ^timestamp
  end

  @spec where_valid(Ecto.Query.t()) :: Ecto.Query.t()
  def where_valid(query) do
    where(query, [m, u, g, gu], m.state == "VALID")
  end

  @spec where_expired(Ecto.Query.t()) :: Ecto.Query.t()
  def where_expired(query) do
    where(query, [m, u, g, gu], m.state == "EXPIRED")
  end

  @spec where_deleted(Ecto.Query.t()) :: Ecto.Query.t()
  def where_deleted(query) do
    where(query, [m, u, g, gu], m.state == "DELETED")
  end

  @spec where_read(Ecto.Query.t()) :: Ecto.Query.t()
  def where_read(query) do
    where(query, [m, u, g, gu, mg], mg.read_state == "READ")
  end

  @spec where_unread(Ecto.Query.t()) :: Ecto.Query.t()
  def where_unread(query) do
    where(query, [m, u, g, gu, mg], mg.read_state == "UNREAD")
  end

  @spec where_is_follower(Ecto.Query.t()) :: Ecto.Query.t()
  def where_is_follower(query) do
    where(query, [m, u, g, gu], m.is_request == false)
  end

  @spec where_is_request(Ecto.Query.t()) :: Ecto.Query.t()
  def where_is_request(query) do
    where(query, [m, u, g, gu], m.is_request == true)
  end

  @spec where_subscribed(Ecto.Query.t()) :: Ecto.Query.t()
  def where_subscribed(query) do
    from [m, u, g, gu] in query,
      where: gu.state == "SUBSCRIBED",
      group_by: m.id
  end

  @spec where_unsubscribed(Ecto.Query.t()) :: Ecto.Query.t()
  def where_unsubscribed(query) do
    from [m, u, g, gu] in query,
      where: gu.state == "UNSUBSCRIBED",
      group_by: m.id
  end

  @spec where_sent_by(Ecto.Query.t(), String.t()) :: Ecto.Query.t()
  def where_sent_by(query, username) do
    from m in query,
      left_join: u in assoc(m, :user),
      where: u.username == ^username
  end

  @spec where_specific_recipients(Ecto.Query.t(), [String.t()]) :: Ecto.Query.t()
  def where_specific_recipients(query, usernames) do
    base_query =
      from [m, u, g, gu] in query,
        inner_join: mg2 in MessageGroup,
        on: mg2.message_id == m.id,
        left_join: u2 in User,
        on: u2.id == mg2.user_id,
        where: g.id == mg2.group_id,
        group_by: m.id,
        select_merge: %{recipient_username: fragment("array_agg(?)", u2.username)}

    from m in subquery(base_query),
      where: fragment("? @> ?::citext[]", m.recipient_username, ^usernames),
      where: fragment("? <@ ?::citext[]", m.recipient_username, ^usernames)
  end

  @spec where_type_direct(Ecto.Query.t()) :: Ecto.Query.t()
  def where_type_direct(query) do
    from g in query,
      where: is_nil(g.id)
  end

  @spec where_type_group(Ecto.Query.t()) :: Ecto.Query.t()
  def where_type_group(query) do
    from g in query,
      where: not is_nil(g.id)
  end

  @spec where_type_all(Ecto.Query.t()) :: Ecto.Query.t()
  def where_type_all(query) do
    from g in query,
      where: is_nil(g.id)
  end

  @spec count(Ecto.Query.t()) :: Ecto.Query.t()
  def count(query) do
    from p in subquery(query),
      select: fragment("count(*)")
  end
end
