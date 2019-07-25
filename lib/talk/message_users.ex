defmodule Talk.MessageUsers do
  @moduledoc """
  The Message_users context.
  """

  import Ecto.Query, warn: false
  alias Talk.Repo

  alias Talk.Schemas.MessageUser

  def list_message_users do
    Repo.all(Message_user)
  end

  def get_message_user!(id), do: Repo.get!(MessageUser, id)

  def create_message_user(attrs \\ %{}) do
    %MessageUser{}
    |> MessageUser.changeset(attrs)
    |> Repo.insert()
  end

  def update_message_user(%MessageUser{} = message_user, attrs) do
    message_user
    |> MessageUser.changeset(attrs)
    |> Repo.update()
  end

  def delete_message_user(%MessageUser{} = message_user) do
    Repo.delete(message_user)
  end

  def change_message_user(%MessageUser{} = message_user) do
    MessageUser.changeset(message_user, %{})
  end
end
