defmodule Talk.Schemas.MessageUser do
  @moduledoc """
  The MessageUser schema.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Talk.Schemas.{Group, Message, User}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "message_users" do
    field :state, :string
    field :read_at, :utc_datetime
    field :bookmaked, :boolean, default: false

    belongs_to :group, Group
    belongs_to :user, User, type: :string
    belongs_to :msg, Message, foreign_key: :message_id

    timestamps()
  end

  @doc false
  def changeset(message_user, attrs) do
    message_user
    |> cast(attrs, [:group_id, :user_id, :msg_id])
  end
end
