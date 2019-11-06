defmodule Talk.Groups.Query do
  @moduledoc "The Groups context."

  import Ecto.Query, warn: false

  alias Talk.Schemas.{Group, GroupUser, User}

  @spec base_query(User.t()) :: Ecto.Query.t()
  def base_query(%User{id: user_id} = _user) do
    from g in Group,
      left_join: gu in GroupUser,
      on: gu.group_id == g.id,
      join: u in User,
      on: u.id == ^user_id,
      where: g.state != "DELETED"
  end

  @spec members_base_query(Group.t()) :: Ecto.Query.t()
  def members_base_query(%Group{id: group_id}) do
    from gu in GroupUser,
      join: u in assoc(gu, :user),
      where: gu.group_id == ^group_id,
      select: %{gu | username: u.username}
  end
end
