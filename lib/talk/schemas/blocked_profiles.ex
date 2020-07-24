defmodule Talk.Schemas.BlockedProfile do
  @moduledoc """
  The Follower context.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Talk.Schemas.Profile

  @type t :: %__MODULE__{}
  @primary_key false
  @timestamps_opts [type: :utc_datetime_usec]
  schema "blocked_profiles" do
    field :inserted_at, :utc_datetime_usec, source: :createdAt
    field :updated_at, :utc_datetime_usec, source: :updatedAt

    belongs_to(
      :blocked_profile, Profile,
      foreign_key: :blocked_profile_id,
      type: :string,
      source: :blocked_profile_id,
      references: :id,
      primary_key: true
    )

    belongs_to(
      :blocked_by, Profile,
      foreign_key: :blocked_by_id,
      type: :string,
      source: :blocked_by_id,
      references: :id,
      primary_key: true
    )
  end

  def create_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:blocked_profile_id, :blocked_by_id])
    |> validate_required([:blocked_profile_id, :blocked_profile_id])
  end
end
