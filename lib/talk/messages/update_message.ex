defmodule Talk.Messages.UpdateMessage do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Talk.Repo
  alias Ecto.Multi
  alias Talk.{Events, Messages}
  alias Talk.Schemas.{Message, MessageLog, User}

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
end
