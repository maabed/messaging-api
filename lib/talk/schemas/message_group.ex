defmodule Talk.Schemas.MessageGroup do
  @moduledoc "The MessageGroup schema."

  use Ecto.Schema
  import Ecto.Changeset
  alias Talk.Schemas.{Group, Message, User}

  @type t :: %__MODULE__{}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "message_groups" do
    field :read_state, :string, read_after_writes: true

    belongs_to :message, Message
    belongs_to :group, Group
    belongs_to :user, User, type: :string

    timestamps()
  end

  def create_changeset(message_group, attrs) do
    message_group
    |> cast(attrs, [:message_id, :group_id, :user_id])
  end
end
