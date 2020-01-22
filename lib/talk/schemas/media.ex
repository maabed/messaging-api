defmodule Talk.Schemas.Media do
  @moduledoc """
  The Media schema.
  """

  use Ecto.Schema
  require Logger
  import Ecto.Changeset
  alias Talk.Schemas.{Message, Profile}

  @type t :: %__MODULE__{}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "media_object" do
    field :size, :integer, source: :mo_size
    field :type, :string, source: :mo_type, default: "IMAGE" # VIDEO. AUDIO, IMAGE, PDF, PRESENTATION, DOCUMENT, RECORDING.
    field :status, :string, source: :mo_status, default: "ACTIVE" # Active, Deleted
    field :extension, :string, source: :mo_extension
    field :description, :string, source: :mo_description, default: nil
    field :for_object_type, :string, source: :mo_for_object_type, default: "MESSAGE" # table name that this media object is related to.
    field :filename, :string, source: :mo_reference_id
    belongs_to :profile, Profile, type: :string, foreign_key: :created_by, source: :mo_created_by
    belongs_to :message, Message, foreign_key: :message_id, type: :string, source: :mo_for_object_id

    timestamps()
  end

  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:created_by, :extension, :filename, :message_id, :size])
  end

  def update_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:description, :status, :filename, :message_id, :size])
    |> validate_required([:filename, :message_id])
  end
end
