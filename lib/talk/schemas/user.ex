defmodule Talk.Schemas.User do
  @moduledoc """
  The Message context.
  """
  use Ecto.Schema

  alias Talk.Schemas.{Group, GroupUser, Message, MessageUser}
  # id refers to profile._id and user_id for actual user._id on sapien db
  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :binary_id

  schema "users" do
    field :username, :string
    field :name, :string
    field :thumbnail, :string
    field :user_id, :string

    has_many :groups, Group
    has_many :messages, Message
    has_many :group_users, GroupUser
    has_many :message_users, MessageUser
  end
end
