defmodule Talk.Events do
  @moduledoc """
  This module encapsulates behavior for publishing messages to listeners
  """
  require Logger
  alias Talk.Schemas.{Group, Message, MessageReaction, User}

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

  def subscribed_to_group(id, %Group{} = group, %User{} = user) do
    publish_to_group(id, :subscribed_to_group, %{group: group, user: user})
  end

  def unsubscribed_from_group(id, %Group{} = group, %User{} = user) do
    publish_to_group(id, :unsubscribed_from_group, %{group: group, user: user})
  end

  def group_muted(id, %Group{} = group, %User{} = user) do
    publish_to_group(id, :group_muted, %{group: group, user: user})
  end

  def group_archived(id, %Group{} = group, %User{} = user) do
    publish_to_group(id, :group_archived, %{group: group, user: user})
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
    publish_to_user(id, :messages_marked_as_read, %{messages: messages})
  end

  def messages_marked_as_unread(id, messages) do
    publish_to_user(id, :messages_marked_as_unread, %{messages: messages})
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
    Logger.debug "publishing user event topics: #{inspect topics}"
    Logger.debug "publishing user event payload: #{inspect payload}"
    Absinthe.Subscription.publish(TalkWeb.Endpoint, payload, topics)
  end
end
