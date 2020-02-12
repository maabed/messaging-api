defmodule Talk.Groups.Query do
  @moduledoc "The Groups context."

  import Ecto.Query, warn: false
  require Logger
  alias Talk.Schemas.{Group, GroupUser, MessageGroup, Profile, User}

  @spec base_query(User.t()) :: Ecto.Query.t()
  def base_query(%User{profile_id: profile_id}) do
    from g in Group,
      join: p in Profile,
      on: p.id == ^profile_id,
      left_join: gu in GroupUser,
      on: gu.group_id == g.id and gu.profile_id == p.id,
      where: gu.profile_id == ^profile_id,
      where: g.status != "DELETED"
  end

  @spec members_base_query(Group.t()) :: Ecto.Query.t()
  def members_base_query(%Group{id: group_id}) do
    from gu in GroupUser,
      join: p in assoc(gu, :profile),
      where: gu.group_id == ^group_id,
      select: %{gu | username: p.username}
  end

  @spec recipients_base_query(User.t(), [String.t()]) :: Ecto.Query.t()
  def recipients_base_query(%User{} = user, recipient_usernames) do
    usernames =
      recipient_usernames
      |> Enum.uniq()
      |> Enum.take(1) # change when add support for groups > 2 users

    from [g, u, gu] in base_query(user),
      join: gu2 in GroupUser,
      on: gu.id != gu2.id and gu.group_id == gu2.group_id,
      join: p2 in assoc(gu2, :profile),
      on: p2.id == gu2.profile_id and p2.username in ^usernames,
      # where: gu2.profile_id in ^usernames,
      distinct: true

    # sub_query =
    #   from g in groups_base_query(user),
    #     join: gu2 in GroupUser,
    #     group_by: gu2.group_id,
    #     having: count(0) > 1,
    #     select: gu2.group_id
    # query =
    #   from gu in GroupUser,
    #     join: gu2 in subquery(sub_query),
    #     on: gu2.group_id == gu.group_id,
    #     where: gu.profile_id in ^ids,
    #     distinct: gu.profile_id,
    #     select: gu.profile_id
  end

  @spec select_recent_messages(Ecto.Query.t()) :: Ecto.Query.t()
  def select_recent_messages(query) do
    from [g, _p, gu] in query,
      left_join: mg in MessageGroup,
      on: mg.group_id == g.id,
      group_by: g.id,
      select_merge: %{recent_message: max(mg.inserted_at)}
  end

  @spec search(Ecto.Query.t(), String.t()) :: Ecto.Query.t()
  def search(query, term) do
    term = "%" <> term <> "%"

    from [g, _p, gu] in query,
      join: gu2 in GroupUser,
      on: gu.id != gu2.id and gu.group_id == gu2.group_id,
      join: p2 in assoc(gu2, :profile),
      on: p2.id == gu2.profile_id,
      where: ilike(p2.display_name, ^term) or ilike(p2.username, ^term),
      distinct: true
  end
end
