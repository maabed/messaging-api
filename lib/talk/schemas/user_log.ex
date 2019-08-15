defmodule Talk.Schemas.UserLog do
  @moduledoc """
  The UserLog schema.
  """
  use Ecto.Schema

  alias Talk.Repo
  alias Talk.Schemas.{Message, User}

  @type t :: %__MODULE__{}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "user_log" do
    field :event, :string

    belongs_to :user, User, type: :string
    belongs_to :message, Message

    timestamps(inserted_at: :happen_at, updated_at: false)
  end

  def message_created(%Message{} = message, %User{} = user) do
    insert(message, user, "MSG_CREATED")
  end

  def message_edited(%Message{} = message, %User{} = user) do
    insert(message, user, "MSG_EDITED")
  end

  def message_deleted(%Message{} = message, %User{} = user) do
    insert(message, user, "MSG_DELETED")
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

  def message_reaction_created(%Message{} = message, %User{} = user) do
    insert(message, user, "MSG_REACTION_CREATED")
  end


  def message_reaction_deleted(%Message{} = message, %User{} = user) do
    insert(message, user, "MSG_REACTION_DELETED")
  end

  defp insert(message, user, event) do
    params = %{
      event: event,
      message_id: message.id,
      user_id: user.id
    }

    %__MODULE__{}
    |> Ecto.Changeset.change(params)
    |> Repo.insert()
  end
end
