defmodule Talk.Schemas.Group do
  @moduledoc """
  The Group schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Talk.Handles
  alias Talk.Schemas.{GroupUser, Message, MessageGroup, User}

  @type t :: %__MODULE__{}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "groups" do
    field :name, :string
    field :description, :string
    field :picture, :string
    field :state, :string, read_after_writes: true
    field :is_private, :boolean, default: true
    field :last_message_id, :binary_id

    belongs_to :user, User, type: :string
    has_many :group_users, GroupUser
    many_to_many :messages, Message, join_through: MessageGroup

    timestamps()
  end

  def create_changeset(%__MODULE__{} = group, attrs) do
    group
    |> cast(attrs, [:user_id, :name, :description, :picture, :is_private])
    |> validate_required([:user_id, :name])
    |> validate()
  end

  def update_changeset(%__MODULE__{} = group, attrs) do
    group
    |> cast(attrs, [:name, :description])
    |> validate()
  end

  defp validate(changeset) do
    changeset
    |> validate_required([:name])
    |> Handles.validate_format(:name)
  end
end
