defmodule Talk.Events do
  @moduledoc """
  This module encapsulates behavior for publishing messages to listeners
  """
  alias Talk.Schemas.{Group, Message, MessageReaction, Profile, User}
  alias Talk.{Users, Groups, OneSignal}
  # alias Talk.Redix

  # group events
  def group_created(ids, %Group{} = group, %User{} = sender) do
    {:ok, recipients} = Groups.list_recipients(group)
    send_push_notification(recipients, "#{sender.profile.username} start new conversation")
    publish_to_many_users(ids, :group_created, %{group: group})
  end

  def group_updated(ids, %Group{} = group) do
    publish_to_many_users(ids, :group_updated, %{group: group})
  end

  def group_closed(ids, %Group{} = group) do
    publish_to_many_users(ids, :group_closed, %{group: group})
  end

  def group_bookmarked(id, %Group{} = group) do
    publish_to_user(id, :group_bookmarked, %{group: group})
  end

  def group_unbookmarked(id, %Group{} = group) do
    publish_to_user(id, :group_unbookmarked, %{group: group})
  end

  def subscribed_to_group(id, %Group{} = group, %Profile{} = profile) do
    publish_to_group(id, :subscribed_to_group, %{group: group, profile: profile})
  end

  def unsubscribed_from_group(id, %Group{} = group, %Profile{} = profile) do
    publish_to_group(id, :unsubscribed_from_group, %{group: group, profile: profile})
  end

  def group_muted(id, %Group{} = group, %Profile{} = profile) do
    publish_to_group(id, :group_muted, %{group: group, profile: profile})
  end

  def group_archived(id, %Group{} = group, %Profile{} = profile) do
    publish_to_group(id, :group_archived, %{group: group, profile: profile})
  end

  # message events
  def message_created(ids, %Message{} = message, %Group{} = group, %User{} = sender) do
    # ws trigger
    # Redix.command(["PUBLISH", "chat:profileId", Jason.encode!(%{name: "marco", message: message.content})])
    {:ok, recipients} = Groups.list_recipients(group, message.id)
    send_push_notification(recipients, "#{sender.profile.username} sent you a message")

    publish_to_many_users(ids, :message_created, %{message: message})
  end

  def message_updated(ids, %Message{} = message) do
    publish_to_many_users(ids, :message_updated, %{message: message})
  end

  def message_deleted(ids, %Message{} = message) do
    publish_to_many_users(ids, :message_deleted, %{message: message})
  end

  def messages_marked_as_read(id, messages) do
    msgs_count = length(messages)
    publish_to_user(id, :messages_marked_as_read, %{messages: messages, read: msgs_count})
  end

  def messages_marked_as_unread(id, messages) do
    msgs_count = length(messages)
    publish_to_user(id, :messages_marked_as_unread, %{messages: messages, unread: msgs_count})
  end

  def user_total_unread_updated(id, total) do
    publish_to_user(id, :user_total_unread_updated, %{total_unread: total})
  end

  def messages_marked_all_as_read(id, group_id, count) do
    publish_to_user(id, :messages_marked_all_as_read, %{group_id: group_id, read: count})
  end

  def messages_marked_all_as_read(id, count) do
    publish_to_user(id, :messages_marked_all_as_read, %{read: count})
  end

  def messages_marked_as_request(ids, messages) do
    publish_to_many_users(ids, :messages_marked_as_request, %{messages: messages})
  end

  def messages_marked_as_not_request(ids, messages) do
    publish_to_many_users(ids, :messages_marked_as_not_request, %{messages: messages})
  end

  def message_reaction_created(ids, %Message{} = message, %MessageReaction{} = reaction) do
    publish_to_many_users(ids, :message_reaction_created, %{message: message, reaction: reaction})
  end

  def message_reaction_deleted(ids, %Message{} = message, %MessageReaction{} = reaction) do
    publish_to_many_users(ids, :message_reaction_deleted, %{message: message, reaction: reaction})
  end

  defp publish_to_user(id, type, payload) do
    publish(Map.merge(payload, %{type: type}), user_subscription: id)
  end

  defp publish_to_many_users(ids, type, payload) do
    topics = Enum.map(ids, fn id -> {:user_subscription, id} end)
    publish(Map.merge(payload, %{type: type}), topics)
  end

  defp publish_to_group(id, type, payload) do
    publish(Map.merge(payload, %{type: type}), group_subscription: id)
  end

  defp publish(payload, topics) do
    Absinthe.Subscription.publish(TalkWeb.Endpoint, payload, topics)
  end

  def send_push_notification(recipients, message) do
    Enum.each recipients, fn r ->
      {:ok, recipient} = Users.get_user_by_profile_id(r.profile_id)
      case OneSignal.get_player_id(recipient.id, true) do
        {:ok, player_id} ->
          OneSignal.post(message, player_id)
        _ -> nil
      end
    end
  end
end
