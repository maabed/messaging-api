defmodule Talk.Schemas.GroupUser do
  @moduledoc """
  The GroupUser schema.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Talk.Schemas.{Group, Profile}

  @type t :: %__MODULE__{}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "group_users" do
    field :role, :string , read_after_writes: true
    field :status, :string, read_after_writes: true
    field :bookmarked, :boolean, default: false

    field :name, :string, virtual: true # Holds the group name via a join
    field :username, :string, virtual: true # Holds the user's name via a join

    belongs_to :group, Group
    belongs_to :profile, Profile, type: :string

    timestamps()
  end

  def create_changeset(group_user, attrs) do
    group_user
    |> cast(attrs, [:group_id, :profile_id])
  end
end

