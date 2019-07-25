defmodule Talk.Schemas.UserLog do
  @moduledoc """
  The UserLog schema.
  """
  use Ecto.Schema

  alias Talk.Repo
  alias Talk.Schemas.{Message, User}

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_log" do
    field :event, :string

    belongs_to :user, User
    belongs_to :msg, Message, foreign_key: :message_id

    timestamps(inserted_at: :happen_at, updated_at: false)
  end

  def marked_as_read(%Message{} = message, %User{} = user) do
    insert(message, user, "MARKED_AS_READ")
  end

  def marked_as_unread(%Message{} = message, %User{} = user) do
    insert(message, user, "MARKED_AS_UNREAD")
  end

  def subscribed(%Message{} = message, %User{} = user) do
    insert(message, user, "SUBSCRIBED")
  end

  def unsubscribed(%Message{} = message, %User{} = user) do
    insert(message, user, "UNSUBSCRIBED")
  end

  defp insert(message, user, event) do
    params = %{
      event: event,
      msg_id: message.id,
      user_id: user.id
    }

    %__MODULE__{}
    |> Ecto.Changeset.change(params)
    |> Repo.insert()
  end
end
