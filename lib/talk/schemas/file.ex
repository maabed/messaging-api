defmodule Talk.Schemas.File do
  @moduledoc """
  The File schema.
  """

  use Ecto.Schema
  require Logger
  import Ecto.Changeset

  alias Talk.Schemas.{MessageFile, User}

  @type t :: %__MODULE__{}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "files" do
    field :filename, :string
    field :content_type, :string
    field :size, :integer
    field :url, :string

    belongs_to :user, User, type: :string
    has_many :message_files, MessageFile
    has_many :messages, through: [:message_files, :message]

    timestamps()
  end

  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:user_id, :filename, :content_type, :size])
  end

  def update_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:filename, :url])
    |> validate_required([:filename, :url])
  end
end
