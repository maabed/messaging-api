defmodule Talk.Schemas.MessageFile do
  @moduledoc """
  The MessageFile schema.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Talk.Schemas.{File, Message}

  @type t :: %__MODULE__{}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "message_files" do
    belongs_to :message, Message
    belongs_to :file, File

    timestamps(updated_at: false)
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:message_id, :file_id])
  end
end
