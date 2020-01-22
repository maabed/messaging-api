defmodule Talk.Schemas.Follower do
  @moduledoc """
  The Follower context.
  """
  use Ecto.Schema
  alias Talk.Schemas.Profile

  @type t :: %__MODULE__{}
  @primary_key false
  @timestamps_opts [type: :utc_datetime_usec]
  schema "followers" do
    field :inserted_at, :utc_datetime_usec, source: :createdAt
    field :updated_at, :utc_datetime_usec, source: :updatedAt
    field :deleted_at, :utc_datetime_usec, source: :updatedAt

    belongs_to(
      :following, Profile,
      foreign_key: :following_id,
      type: :string,
      source: :following_id,
      references: :id,
      primary_key: true
    )
    belongs_to(
      :follower, Profile,
      foreign_key: :follower_id,
      type: :string,
      source: :follower_id,
      references: :id,
      primary_key: true
    )

  end
end
