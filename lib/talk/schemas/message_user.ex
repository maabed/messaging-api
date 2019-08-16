defmodule Talk.Schemas.MessageUser do
  @moduledoc """
  The MessageUser schema.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Talk.Schemas.{Group, Message, User}

  @type t :: %__MODULE__{}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "message_users" do
    field :state, :string, read_after_writes: true

    belongs_to :group, Group
    belongs_to :user, User, type: :string
    belongs_to :message, Message

    timestamps()
  end

  def create_changeset(message_user, attrs) do
    message_user
    |> cast(attrs, [:group_id, :user_id, :message_id])
  end
end
