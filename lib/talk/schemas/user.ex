defmodule Talk.Schemas.User do
  @moduledoc """
  The User context.
  id refers to user._id and profile_id for actual profile._id on sapien db.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Talk.Utils
  alias Ecto.Changeset
  alias Talk.Schemas.{File, Follower, BlockedProfile, Group, GroupUser, Message}

  @type t :: %__MODULE__{}
  @primary_key {:id, :string, autogenerate: false}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "users" do
    field :username, :string
    field :display_name, :string
    field :email, :string
    field :avatar, :string
    field :profile_id, :string
    field :time_zone, :string
    field :inserted_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec

    has_many :files, File
    has_many :groups, Group
    has_many :messages, Message
    has_many :group_users, GroupUser

    many_to_many(
      :followers,
      __MODULE__,
      join_through: Follower,
      join_keys: [follower_id: :profile_id, following_id: :profile_id],
      on_replace: :delete
    )

    many_to_many(
      :followings,
      __MODULE__,
      join_through: Follower,
      join_keys: [following_id: :profile_id, follower_id: :profile_id],
      on_replace: :delete
    )
    many_to_many(
      :blocked_by,
      __MODULE__,
      join_through: BlockedProfile,
      join_keys: [blocked_by_id: :profile_id, blocked_profile_id: :profile_id],
      on_replace: :delete
    )

    many_to_many(
      :blocked_profiles,
      __MODULE__,
      join_through: BlockedProfile,
      join_keys: [blocked_profile_id: :profile_id, blocked_by_id: :profile_id],
      on_replace: :delete
    )
  end

  def create_changeset(struct, attrs \\ %{}) do
    now = Timex.now()
    struct
    |> cast(attrs, [:id, :username, :display_name, :email, :profile_id, :avatar, :time_zone, :inserted_at, :updated_at])
    |> validate_required([:id, :username, :display_name, :email, :profile_id])
    |> put_change(:inserted_at, now)
    |> put_change(:updated_at, now)
    |> put_default_time_zone()
    |> validate()
  end

  def update_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:username, :display_name, :email, :avatar, :time_zone])
    |> validate_required([:username, :display_name, :email])
    |> put_updated_at()
    |> validate()
  end

  def validate(changeset) do
    changeset
    |> validate_length(:email, min: 1, max: 254)
    |> validate_length(:display_name, min: 3, max: 255)
    |> validate_length(:username, min: 4, max: 255)
    |> validate_format(:email, email_format(), message: "is invalid")
    |> Utils.validate_format(:username)
    |> validate_inclusion(:time_zone, Timex.timezones())
    |> unique_constraint(:email,
      name: :users_lower_email_index,
      message: "is already taken"
    )
  end

  defp email_format do
    ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
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

  defp put_default_time_zone(changeset) do
    case changeset do
      %Changeset{changes: %{time_zone: ""}} ->
        put_change(changeset, :time_zone, "UTC")

      %Changeset{changes: %{time_zone: _}} ->
        changeset

      _ ->
        put_change(changeset, :time_zone, "UTC")
    end
  end
end
