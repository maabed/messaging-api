defmodule Talk.Schemas.Follower do
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
  schema "followers" do
    field :inserted_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec

    belongs_to(
      :following, User,
      foreign_key: :following_id,
      type: :string,
      source: :following_id,
      references: :profile_id,
      primary_key: true
    )
    belongs_to(
      :follower, User,
      foreign_key: :follower_id,
      type: :string,
      source: :follower_id,
      references: :profile_id,
      primary_key: true
    )

  end

  def create_changeset(struct, attrs \\ %{}) do
    now = Timex.now()
    struct
    |> cast(attrs, [:following_id, :follower_id])
    |> put_change(:inserted_at, now)
    |> put_change(:updated_at, now)
  end

  def update_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:updated_at])
    |> validate_required([:updated_at])
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
