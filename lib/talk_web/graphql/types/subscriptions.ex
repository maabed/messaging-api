defmodule TalkWeb.Type.Subscriptions do
   @moduledoc "Subscriptions types for all app models"

  use Absinthe.Schema.Notation

  alias Talk.Groups

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
  end

  object :messages_marked_as_read_response do
    field :messages, list_of(:message)
  end

  object :messages_marked_as_request_response do
    field :messages, list_of(:message)
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
    subscription do
      @desc "Triggered when a users/messages related event occurs."
      field :user_subscription, :user_subscription_response do
        config fn _, %{context: %{user: user}} ->
          {:ok, topic: user.profile_id}
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
      # field :user_subscription, :user_subscription_response do
      #   arg :user_id, non_null(:id)

      #   config fn %{user_id: id}, %{context: %{user: user}} ->
      #     case Users.get_user(user, id) do
      #       {:ok, user} ->
      #         if user.user_id == user.id do
      #           {:ok, topic: id}
      #         else
      #           {:error, "Not authorized"}
      #         end

      #       err ->
      #         err
      #     end
      #   end
      # end
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
