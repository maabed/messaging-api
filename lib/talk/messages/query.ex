defmodule Talk.Messages.Query do
  @moduledoc "Functions for building message queries."

  import Ecto.Query
  require Logger

  alias Talk.Schemas.{GroupUser, Message, MessageGroup, MessageLog, Profile, User}

  @spec base_query(User.t()) :: Ecto.Query.t()
  def base_query(%User{profile_id: profile_id}) do
    query =
      from m in Message,
        join: p in Profile,
        on: p.id == ^profile_id

    base_query_with_user(query, profile_id)
  end

  defp base_query_with_user(query, profile_id) do
    from [m, p] in query,
      left_join: g in assoc(m, :groups),
      left_join: gu in GroupUser,
      on: gu.profile_id == p.id and gu.group_id == g.id,
      left_join: mg in assoc(m, :message_groups),
      on: mg.profile_id == p.id,
      where: gu.profile_id == ^profile_id and m.status != "DELETED" and g.is_private == true,
      distinct: m.id
  end

  @spec where_in_group(Ecto.Query.t(), String.t()) :: Ecto.Query.t()
  def where_in_group(query, group_id) do
    from [m, p, g, gu] in query,
      where: g.id == ^group_id
  end

  @spec select_last_activity_at(Ecto.Query.t()) :: Ecto.Query.t()
  def select_last_activity_at(query) do
    from [m, p, g, gu] in query,
      left_join: ml in MessageLog,
      on: ml.message_id == m.id,
      group_by: m.id,
      select_merge: %{last_activity_at: max(ml.happen_at)}
  end

  @spec where_last_active_today(Ecto.Query.t(), DateTime.t()) :: Ecto.Query.t()
  def where_last_active_today(query, now) do
    where(
      query,
      [m, p, g, gu, ml],
      fragment(
        "date_trunc('day', timezone(?, ?::timestamptz)) = date_trunc('day', timezone(?, ?))",
        p.time_zone,
        ml.happen_at,
        p.time_zone,
        ^now
      )
    )
  end

  @spec where_last_active_after(Ecto.Query.t(), DateTime.t()) :: Ecto.Query.t()
  def where_last_active_after(query, timestamp) do
    from [m, p, g, gu, ml] in query,
      where: ml.happen_at >= ^timestamp
  end

  @spec where_valid(Ecto.Query.t()) :: Ecto.Query.t()
  def where_valid(query) do
    where(query, [m, p, g, gu], m.status == "VALID")
  end

  @spec where_expired(Ecto.Query.t()) :: Ecto.Query.t()
  def where_expired(query) do
    where(query, [m, p, g, gu], m.status == "EXPIRED")
  end

  @spec where_deleted(Ecto.Query.t()) :: Ecto.Query.t()
  def where_deleted(query) do
    where(query, [m, p, g, gu], m.status == "DELETED")
  end

  @spec where_read(Ecto.Query.t()) :: Ecto.Query.t()
  def where_read(query) do
    where(query, [m, p, g, gu, mg], mg.read_status == "READ")
  end

  @spec where_unread(Ecto.Query.t()) :: Ecto.Query.t()
  def where_unread(query) do
    where(query, [m, p, g, gu, mg], mg.read_status == "UNREAD")
  end

  @spec where_read_and_unread(Ecto.Query.t()) :: Ecto.Query.t()
  def where_read_and_unread(query) do
    where(query, [m, p, g, gu, mg], mg.read_status in ["UNREAD", "READ"])
  end

  @spec where_is_follower(Ecto.Query.t()) :: Ecto.Query.t()
  def where_is_follower(query) do
    where(query, [m, p, g, gu, mg], m.is_request == false)
  end

  @spec where_is_request(Ecto.Query.t()) :: Ecto.Query.t()
  def where_is_request(query) do
    where(query, [m, p, g, gu, mg], m.is_request == true)
  end

  @spec where_subscribed(Ecto.Query.t()) :: Ecto.Query.t()
  def where_subscribed(query) do
    from [m, p, g, gu, mg] in query,
      where: gu.status == "SUBSCRIBED",
      group_by: m.id
  end

  @spec where_unsubscribed(Ecto.Query.t()) :: Ecto.Query.t()
  def where_unsubscribed(query) do
    from [m, p, g, gu, mg] in query,
      where: gu.status == "UNSUBSCRIBED",
      group_by: m.id
  end

  @spec where_muted(Ecto.Query.t()) :: Ecto.Query.t()
  def where_muted(query) do
    from [m, p, g, gu, mg] in query,
      where: gu.status == "MUTED",
      group_by: m.id
  end

  @spec where_archived(Ecto.Query.t()) :: Ecto.Query.t()
  def where_archived(query) do
    from [m, p, g, gu, mg] in query,
      where: gu.status == "ARCHIVED",
      group_by: m.id
  end

  @spec where_sent_by(Ecto.Query.t(), String.t()) :: Ecto.Query.t()
  def where_sent_by(query, username) do
    from m in query,
      left_join: p in assoc(m, :profile),
      where: p.username == ^username
  end

  @spec where_type_text(Ecto.Query.t()) :: Ecto.Query.t()
  def where_type_text(query) do
    where(query, [m, p, g, gu, mg], m.type == "TEXT")
  end

  @spec where_type_image(Ecto.Query.t()) :: Ecto.Query.t()
  def where_type_image(query) do
    where(query, [m, p, g, gu, mg], m.type == "IMAGE")
  end

  @spec where_type_video(Ecto.Query.t()) :: Ecto.Query.t()
  def where_type_video(query) do
    where(query, [m, p, g, gu, mg], m.type == "VIDEO")
  end

  @spec where_specific_recipients(Ecto.Query.t(), [String.t()]) :: Ecto.Query.t()
  def where_specific_recipients(query, usernames) do
    base_query =
      from [m, p, g, gu, mg] in query,
        join: mg2 in MessageGroup,
        on: mg2.message_id == m.id,
        left_join: p2 in Profile,
        on: p2.id == mg2.profile_id,
        where: g.id == mg2.group_id,
        where: m.profile_id != mg2.profile_id,
        group_by: m.id,
        select_merge: %{recipient_username: fragment("array_agg(?)", p2.username)}

    from m in subquery(base_query),
      # where: fragment("? @> ?::varchar[]", m.recipient_username, ^usernames)
      where: fragment("? <@ ?::varchar[]", m.recipient_username, ^usernames)
  end

  # @spec where_type_direct(Ecto.Query.t()) :: Ecto.Query.t()
  # def where_type_direct(query) do
  #   from g in query,
  #     where: is_nil(g.id)
  # end

  # @spec where_type_group(Ecto.Query.t()) :: Ecto.Query.t()
  # def where_type_group(query) do
  #   from g in query,
  #     where: not is_nil(g.id)
  # end

  @spec count(Ecto.Query.t()) :: Ecto.Query.t()
  def count(query) do
    from p in subquery(query),
      select: fragment("count(*)")
  end
end
