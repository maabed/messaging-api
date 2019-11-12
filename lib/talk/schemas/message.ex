defmodule Talk.Schemas.Message do
  @moduledoc """
  The Message context.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Talk.Schemas.{Group, MessageGroup, MessageFile, MessageReaction, User}

  @type t :: %__MODULE__{}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "messages" do
    field :body, :string
    field :is_request, :boolean, default: false
    field :state, :string, read_after_writes: true
    field :type, :string, read_after_writes: true

    field :recipient_username, {:array, :string}, virtual: true
    field :last_activity_at, :utc_datetime, virtual: true

    belongs_to :user, User, type: :string
    has_many :message_groups, MessageGroup
    has_many :recipients, through: [:message_groups, :user]
    has_many :message_files, MessageFile
    has_many :message_reactions, MessageReaction
    has_many :files, through: [:message_files, :file]
    many_to_many :groups, Group, join_through: MessageGroup

    timestamps()
  end

  def create_changeset(message, attrs) do
    message
    |> cast(attrs, [:user_id, :body])
    |> validate_required([:body])
  end

  def update_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:body, :is_request])
    |> validate_required([:body, :is_request])
  end
end
