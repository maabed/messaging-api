defmodule Talk.Messages.UpdateMessage do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Talk.Repo
  alias Ecto.Multi
  alias Talk.{Events, Messages}
  alias Talk.Schemas.{Message, MessageLog, User}
  require Logger

  @spec perform(User.t(), Message.t(), map()) :: {:ok, %{message: Message.t()}}
      | {:error, :unauthorized} | {:error, atom(), any(), map()}
  def perform(%User{} = user, %Message{} = msg, params) do
    user
    |> Messages.can_edit?(msg)
    |> perform_edit(user, msg, params)
  end

  defp perform_edit(true, user, msg, params) do
    Multi.new()
    |> fetch_message(msg.id)
    |> update_message(params)
    |> log(user)
    |> Repo.transaction()
    |> after_update_message()
  end

  defp perform_edit(false, _, _, _), do: {:error, :unauthorized}

  defp fetch_message(multi, message_id) do
    Multi.run(multi, :message, fn _repo, _ ->
      query =
        from m in Message,
          where: m.id == ^message_id,
          lock: "FOR UPDATE"

      query
      |> Repo.one()
      |> handle_fetch()
    end)
  end

  defp handle_fetch(%Message{} = message), do: {:ok, message}
  defp handle_fetch(_), do: {:error, "message not found"}

  defp update_message(multi, params) do
    Multi.run(multi, :updated_message, fn _repo, %{message: message} ->
      message
      |> Message.update_changeset(params)
      |> Repo.update()
    end)
  end

  defp log(multi, user) do
    Multi.run(multi, :log, fn _repo, %{updated_message: message} ->
      MessageLog.message_edited(message, user.profile)
    end)
  end

  defp after_update_message({:ok, %{updated_message: message} = result}) do
    {:ok, profile_ids} = Messages.get_accessor_ids(message)
    Events.message_updated(profile_ids, message)
    {:ok, result}
  end

  defp after_update_message(err), do: err

  @spec mark_as_request(User.t(), [Message.t()]) :: {:ok, [Message.t()]}
  def mark_as_request(%User{} = _user, messages) do
    update_messages_request_status(messages, %{is_request: true})
    |> after_mark_as_request()
  end

  defp after_mark_as_request({:ok, messages} = result) do
    {:ok, profile_ids} = Messages.get_accessor_ids(Enum.at(messages, 0))
    Events.messages_marked_as_request(profile_ids, messages)
    result
  end

  @spec mark_as_not_request(User.t(), [Message.t()]) :: {:ok, [Message.t()]}
  def mark_as_not_request(%User{} = _user, messages) do
    update_messages_request_status(messages, %{is_request: false})
    |> after_mark_as_not_request()
  end

  defp after_mark_as_not_request({:ok, messages} = result) do
    {:ok, profile_ids} = Messages.get_accessor_ids(Enum.at(messages, 0))
    Events.messages_marked_as_not_request(profile_ids, messages)

    result
  end

  defp update_messages_request_status(messages, params) do
    updated_messages =
      Enum.filter(messages, fn msg ->
        :ok == update_request_status(msg, params)
      end)

    {:ok, updated_messages}
  end

  defp update_request_status(message, params) do
    message
    |> Message.update_changeset(params)
    |> Repo.update()
    |> after_update_request_status()
  end

  defp after_update_request_status({:ok, _}), do: :ok
  defp after_update_request_status(_), do: :error
end
