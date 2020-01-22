defmodule Talk.Schemas.Message do
  @moduledoc """
  The Message context.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Talk.Schemas.{Group, Media, MessageGroup, MessageReaction, Profile}

  @type t :: %__MODULE__{}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "messages" do
    field :content, :string
    field :is_request, :boolean, default: false
    field :status, :string, read_after_writes: true
    field :type, :string, read_after_writes: true

    field :recipient_username, {:array, :string}, virtual: true
    field :last_activity_at, :utc_datetime, virtual: true

    belongs_to :profile, Profile, type: :string
    has_one :media, Media, foreign_key: :message_id
    has_many :message_groups, MessageGroup
    has_many :recipients, through: [:message_groups, :profile]
    has_many :message_reactions, MessageReaction
    many_to_many :groups, Group, join_through: MessageGroup

    timestamps()
  end

  def create_changeset(message, attrs) do
    message
    |> cast(attrs, [:profile_id, :content, :is_request])
  end

  def update_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:content, :is_request])
  end
end
