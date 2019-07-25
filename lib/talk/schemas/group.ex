defmodule Talk.Schemas.Group do
  @moduledoc """
  The Group schema.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Talk.Schemas.{GroupUser, User}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "groups" do
    field :name, :string
    field :description, :string
    field :picture, :string
    field :state, :string
    field :is_private, :boolean, default: true
    field :last_msg_id, :binary_id

    belongs_to :user, User, type: :string
    has_many :group_users, GroupUser

    timestamps()
  end

  @doc false
  def changeset(group, attrs) do
    group
    |> cast(attrs, [:user_id, :name])
    |> validate_required([:name])
  end
end
