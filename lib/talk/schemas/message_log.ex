defmodule Talk.Schemas.MessageLog do
  @moduledoc """
  The MessageLog schema.
  """
  use Ecto.Schema

  alias Talk.Repo
  alias Talk.Schemas.{Message, Profile}

  @type t :: %__MODULE__{}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "message_logs" do
    field :event, :string

    belongs_to :profile, Profile, type: :string
    belongs_to :message, Message

    timestamps(inserted_at: :happen_at, updated_at: false)
  end

  def message_created(%Message{} = message, %Profile{} = profile) do
    insert(message, profile, "MSG_CREATED")
  end

  def message_edited(%Message{} = message, %Profile{} = profile) do
    insert(message, profile, "MSG_EDITED")
  end

  def message_deleted(%Message{} = message, %Profile{} = profile) do
    insert(message, profile, "MSG_DELETED")
  end

  def marked_as_read(%Message{} = message, %Profile{} = profile) do
    insert(message, profile, "MARKED_AS_READ")
  end

  def marked_as_unread(%Message{} = message, %Profile{} = profile) do
    insert(message, profile, "MARKED_AS_UNREAD")
  end

  def subscribed(%Message{} = message, %Profile{} = profile) do
    insert(message, profile, "SUBSCRIBED")
  end

  def unsubscribed(%Message{} = message, %Profile{} = profile) do
    insert(message, profile, "UNSUBSCRIBED")
  end

  def message_reaction_created(%Message{} = message, %Profile{} = profile) do
    insert(message, profile, "MSG_REACTION_CREATED")
  end


  def message_reaction_deleted(%Message{} = message, %Profile{} = profile) do
    insert(message, profile, "MSG_REACTION_DELETED")
  end

  defp insert(message, profile, event) do
    params = %{
      event: event,
      message_id: message.id,
      profile_id: profile.id
    }

    %__MODULE__{}
    |> Ecto.Changeset.change(params)
    |> Repo.insert()
  end
end
