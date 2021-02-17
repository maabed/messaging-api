defmodule TalkWeb.Type.Subscriptions do
   @moduledoc "Subscriptions types for all app models"

  use Absinthe.Schema.Notation

  alias Talk.{Groups, Users}
  require Logger
  @desc "The users and messages topic response."
  union :user_subscription_response do
    types [
      :group_created_response,
      :group_updated_response,
      :message_created_response,
      :message_updated_response,
      :message_closed_response,
      :message_deleted_response,
      :group_bookmarked_response,
      :group_unbookmarked_response,
      :messages_marked_as_read_response,
      :messages_marked_as_unread_response,
      :messages_marked_all_as_read_response,
      :user_total_unread_updated_response,
      :message_reaction_created_response,
      :message_reaction_deleted_response,
      :messages_marked_as_request_response,
      :messages_marked_as_not_request_response,
    ]
    resolve_type &type_resolver/2
  end

  @desc "The groups topic response."
  union :group_subscription_response do
    types [
      :subscribed_to_group_response,
      :unsubscribed_from_group_response
    ]
    resolve_type &type_resolver/2
  end

  # Objects
  object :group_updated_response do
    field :group, non_null(:group)
  end

  object :group_bookmarked_response do
    field :group, non_null(:group)
  end

  object :group_unbookmarked_response do
    field :group, non_null(:group)
  end

  object :group_created_response do
    field :group, non_null(:group)
  end

  object :message_created_response do
    field :message, :message
  end

  object :message_updated_response do
    field :message, :message
  end

  object :message_closed_response do
    field :message, :message
  end

  object :message_deleted_response do
    field :message, :message
  end

  object :messages_marked_as_unread_response do
    field :messages, list_of(:message)
    field :unread, :integer
  end

  object :messages_marked_as_read_response do
    field :messages, list_of(:message)
    field :read, :integer
  end

  object :messages_marked_all_as_read_response do
    field :group_id, :id
    field :read, non_null(:integer)
  end

  object :messages_marked_as_request_response do
    field :messages, list_of(:message)
  end

  object :user_total_unread_updated_response do
    field :total_unread, non_null(:integer)
  end

  object :messages_marked_as_not_request_response do
    field :messages, list_of(:message)
  end

  object :subscribed_to_group_response do
    field :group, non_null(:group)
    field :user, non_null(:user)
  end

  object :unsubscribed_from_group_response do
    field :group, non_null(:group)
    field :user, non_null(:user)
  end

  object :message_reaction_created_response do
    field :message, :message
    field :reaction, :message_reaction
  end

  object :message_reaction_deleted_response do
    field :message, :message
    field :reaction, :message_reaction
  end

  # subscriptions
  object :subscriptions do
    @desc "Triggered when a users/messages related event occurs."
    field :user_subscription, :user_subscription_response do
      arg :profile_id, non_null(:id)

      config fn %{profile_id: id}, %{context: %{user: user}} ->
        case Users.get_user_by_profile_id(user, id) do
          {:ok, current_user} ->
            if current_user.profile_id == user.profile_id do
              {:ok, topic: id}
            else
              {:error, "Not authorized"}
            end

          err ->
            err
        end
      end

      resolve fn user_subscription_response, _, _ ->
        {:ok, user_subscription_response}
      end
    end

    @desc "Triggered when a groups related event occurs."
    field :group_subscription, :group_subscription_response do
      arg :group_id, non_null(:id)

      config fn %{group_id: id}, %{context: %{user: user}} ->
        case Groups.get_group(user, id) do
          {:ok, group} ->
            {:ok, topic: group.id}

          err ->
            err
        end
      end
    end
  end

  defp type_resolver(%{type: type}, _) do
    type
    |> Atom.to_string()
    |> concat("_response")
    |> String.to_atom()
  end

  defp concat(a, b) do
    a <> b
  end
end
