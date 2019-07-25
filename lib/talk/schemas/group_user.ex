defmodule Talk.Schemas.GroupUser do
  @moduledoc """
  The GroupUser schema.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Talk.Schemas.{Group, User}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "group_users" do
    field :role, :string
    field :state, :string

    field :group_name, :string, virtual: true # Holds the group name via a join
    field :user_name, :string, virtual: true # Holds the user's name via a join

    belongs_to :group, Group
    belongs_to :user, User, type: :string

    timestamps()
  end

  @doc false
  def changeset(group_user, attrs) do
    group_user
    |> cast(attrs, [:group_id, :user_id])
  end
end

