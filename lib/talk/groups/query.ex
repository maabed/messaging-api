defmodule Talk.Groups.Query do
  @moduledoc "The Groups context."

  import Ecto.Query, warn: false
  require Logger
  alias Talk.Schemas.{Group, GroupUser, User}

  @spec base_query(User.t()) :: Ecto.Query.t()
  def base_query(%User{id: user_id}) do
    from g in Group,
      join: u in User,
      on: u.id == ^user_id,
      left_join: gu in GroupUser,
      on: gu.group_id == g.id and gu.user_id == u.id,
      where: gu.user_id == ^user_id,
      where: g.state != "DELETED"
  end

  @spec members_base_query(Group.t()) :: Ecto.Query.t()
  def members_base_query(%Group{id: group_id}) do
    from gu in GroupUser,
      join: u in assoc(gu, :user),
      where: gu.group_id == ^group_id,
      select: %{gu | username: u.username}
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
      join: u2 in assoc(gu2, :user),
      on: u2.id == gu2.user_id and u2.username in ^usernames,
      # where: gu2.user_id in ^usernames,
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
    #     where: gu.user_id in ^ids,
    #     distinct: gu.user_id,
    #     select: gu.user_id
  end

  @spec search_query(User.t(), [String.t()]) :: Ecto.Query.t()
  def search_query(query, search_term) do
    term = "%" <> search_term <> "%"

    from [g, u, gu] in query,
      join: gu2 in GroupUser,
      on: gu.id != gu2.id and gu.group_id == gu2.group_id,
      join: u2 in assoc(gu2, :user),
      on: u2.id == gu2.user_id,
      where: ilike(u2.display_name, ^term) or ilike(u2.username, ^term),
      distinct: true
  end
end
