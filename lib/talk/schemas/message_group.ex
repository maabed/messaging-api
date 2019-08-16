defmodule Talk.Schemas.MessageGroup do
  @moduledoc "The MessageGroup schema."

  use Ecto.Schema

  alias Talk.Schemas.{Group, Message}

  @type t :: %__MODULE__{}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "message_groups" do
    belongs_to :message, Message
    belongs_to :group, Group

    timestamps()
  end
end
