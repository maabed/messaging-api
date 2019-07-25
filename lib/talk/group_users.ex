defmodule Talk.GroupUsers do
  @moduledoc """
  The Group_users context.
  """

  import Ecto.Query, warn: false
  alias Talk.Repo

  alias Talk.Schemas.GroupUser

  def list_group_users do
    Repo.all(GroupUser)
  end

  def get_group_user!(id), do: Repo.get!(GroupUser, id)

  def create_group_user(attrs \\ %{}) do
    %GroupUser{}
    |> GroupUser.changeset(attrs)
    |> Repo.insert()
  end

  def update_group_user(%GroupUser{} = group_user, attrs) do
    group_user
    |> GroupUser.changeset(attrs)
    |> Repo.update()
  end

  def delete_group_user(%GroupUser{} = group_user) do
    Repo.delete(group_user)
  end

  def change_group_user(%GroupUser{} = group_user) do
    GroupUser.changeset(group_user, %{})
  end
end
