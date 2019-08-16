defmodule Talk.Schemas.User do
  @moduledoc """
  The Message context.
  id refers to user._id and profile_id for actual profile._id on sapien db.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Talk.Handles
  alias Ecto.Changeset
  alias Talk.Schemas.{Group, GroupUser, Message, MessageUser}

  @type t :: %__MODULE__{}
  @primary_key {:id, :string, autogenerate: false}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "users" do
    field :username, :string
    field :name, :string
    field :email, :string
    field :thumbnail, :string
    field :profile_id, :string

    has_many :groups, Group
    has_many :messages, Message
    has_many :group_users, GroupUser
    has_many :message_users, MessageUser
  end

  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:username, :name, :email, :thumbnail, :profile_id, :time_zone])
    |> validate_required([:username, :name, :email, :profile_id])
    |> put_default_time_zone()
    |> validate()
  end

  def update_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:username, :name, :email, :thumbnail, :profile_id, :time_zone])
    |> validate_required([:username, :name, :email, :profile_id])
    |> validate()
  end

  def validate(changeset) do
    changeset
    |> validate_length(:email, min: 1, max: 254)
    |> validate_length(:name, min: 3, max: 255)
    |> validate_length(:username, min: 4, max: 255)
    |> validate_format(:email, email_format(), message: "is invalid")
    |> Handles.validate_format(:username)
    |> validate_inclusion(:time_zone, Timex.timezones())
    |> unique_constraint(:email,
      name: :users_lower_email_index,
      message: "is already taken"
    )
  end

  defp email_format do
    ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
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
