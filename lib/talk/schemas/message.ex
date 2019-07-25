defmodule Talk.Schemas.Message do
  @moduledoc """
  The Message context.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Talk.Schemas.{MessageUser, User}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "messages" do
    field :body, :string
    field :is_request, :boolean, default: false
    field :state, :string
    field :type, :string

    belongs_to :user, User, type: :string
    has_many :message_users, MessageUser

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:user_id, :body])
    |> validate_required([:body])
  end
end
