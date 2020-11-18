defmodule Talk.Events do
  @moduledoc """
  This module encapsulates behavior for publishing messages to listeners
  """
  require Logger
  alias Talk.Schemas.{Group, Message, MessageReaction, Profile}

  # group events
  def group_created(ids, %Group{} = group) do
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
  def message_created(ids, %Message{} = message) do
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

  def send_notification(payload) do
    api_url = 'https://onesignal.com/api/v1/notifications'
    players = [] # Need to get the player ids from devices table using payload.messeage.recipients
    notification = %{
      headings: %{
        en: 'Sapien'
      },
      contents: %{
        en: 'sent you a message' # Need to get the name of the sender
      },
      include_player_ids: players,
      app_id: '095b0cbc-640d-4d07-ba61-a9fb02439af6',
      excluded_segments: ['Banned Users']
    }
    app_auth_key = 'NDFjNDVmYTQtNTcwYi00ZmZlLThjMmEtNGNkMjE3NWQ1ZmYx'
    headers = [
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Basic #{app_auth_key}'
    ]
    options = []
    HTTPoison.post(api_url, notification, headers, options)
  end

  defp publish(payload, topics) do
    Absinthe.Subscription.publish(TalkWeb.Endpoint, payload, topics)
    send_notification(payload)
  end
end
