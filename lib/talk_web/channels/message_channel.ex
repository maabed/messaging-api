defmodule TalkWeb.MessageChannel do
  @moduledoc "Represents the messages channel."

  use TalkWeb, :channel

  alias Talk.Messages
  alias TalkWeb.Presence

  def join("messages:" <> message_id, _payload, socket) do
    join_if_authorized(socket, message_id)
  end

  def handle_info(:after_join, socket) do
    push(socket, "presence_state", Presence.list(socket))

    {:ok, _} =
      Presence.track(socket, socket.assigns.user.id, %{
        typing: true,
        online_at: inspect(System.system_time(:seconds))
      })

    {:noreply, socket}
  end

  def handle_in("meta:update", %{"typing" => typing}, socket) do
    {:ok, _} =
      Presence.update(socket, socket.assigns.user.id, fn meta ->
        Map.put(meta, :typing, typing)
      end)

    {:noreply, socket}
  end

  defp join_if_authorized(socket, message_id) do
    if authorized?(socket, message_id) do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  defp authorized?(%{assigns: %{user: user}}, message_id) do
    case Messages.get_message(user, message_id) do
      {:ok, _message} -> true
      _ -> false
    end
  end
end
