defmodule Talk.Schemas.BlockedProfile do
  @moduledoc """
  The Follower context.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Ecto.Changeset
  alias Talk.Schemas.User

  @type t :: %__MODULE__{}
  @primary_key false
  @timestamps_opts [type: :utc_datetime_usec]
  schema "blocked_profiles" do
    field :inserted_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec

    belongs_to(
      :blocked_profile, User,
      foreign_key: :blocked_profile_id,
      type: :string,
      source: :blocked_profile_id,
      references: :profile_id,
      primary_key: true
    )

    belongs_to(
      :blocked_by, User,
      foreign_key: :blocked_by_id,
      type: :string,
      source: :blocked_by_id,
      references: :profile_id,
      primary_key: true
    )

  end

  def create_changeset(struct, attrs \\ %{}) do
    now = Timex.now()
    struct
    |> cast(attrs, [:blocked_profile_id, :blocked_by_id])
    |> put_change(:inserted_at, now)
    |> put_change(:updated_at, now)
  end

  def update_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:updated_at])
    |> put_updated_at()
  end

  defp put_updated_at(changeset) do
    now = Timex.now()
    case changeset do
      %Changeset{changes: %{updated_at: ""}} ->
        put_change(changeset, :updated_at, now)

      %Changeset{changes: %{updated_at: _}} ->
        changeset

      _ ->
        put_change(changeset, :updated_at, now)
    end
  end
end
