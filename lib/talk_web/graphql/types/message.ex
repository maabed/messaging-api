defmodule TalkWeb.Type.Message do
  @moduledoc "GraphQL types for messages"

  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers

  alias Talk.Schemas.Message
  alias Talk.Messages
  alias TalkWeb.Resolver.Messages, as: Resolver

  object :message do
    field :id, non_null(:id)
    field :body, non_null(:string)
    field :files, list_of(:file), resolve: dataloader(:db)
    field :state, non_null(:message_state)
    field :groups, list_of(:group), resolve: dataloader(:db)
    field :sender, non_null(:user), resolve: &Resolver.message_sender/3
    field :is_request, non_null(:boolean)
    field :recipients, list_of(:group_user), resolve: &Resolver.list_recipients/3
    field :updated_at, non_null(:timestamp)
    field :inserted_at, non_null(:timestamp)

    field :reactions, non_null(:message_reaction_pagination) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :timestamp
      arg :after, :timestamp
      arg :order_by, :reaction_order
      resolve &Resolver.reactions/3
    end

    field :can_edit, non_null(:boolean) do
      resolve &Resolver.can_edit_message/3
    end

    field :last_activity_at, non_null(:timestamp) do
      resolve fn
        %Message{last_activity_at: last_activity_at}, _, _ when not is_nil(last_activity_at) ->
          {:ok, last_activity_at}

        message, _, _ ->
          Messages.last_activity_at(message)
      end
    end
  end

  object :message_reaction do
    field :id, non_null(:id)
    field :user, non_null(:user), resolve: dataloader(:db)
    field :message, :message, resolve: dataloader(:db)
    field :value, :string
  end

  object :message_mutation_response do
    interface :response
    field :success, non_null(:boolean)
    field :errors, list_of(:error)
    field :message, :message
  end

  object :mark_as_unread_response do
    interface :response
    field :success, non_null(:boolean)
    field :errors, list_of(:error)
    field :messages, list_of(:message)
  end

  object :message_reaction_mutation_response do
    interface :response
    field :success, non_null(:boolean)
    field :errors, list_of(:error)
    field :message, :message
    field :reaction, :message_reaction
  end

  # message queries
  object :message_queries do
    field :messages, non_null(:message_pagination) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :timestamp
      arg :after, :timestamp
      arg :order_by, :message_order
      arg :filter, :message_filters
      resolve &Resolver.messages/2
    end
  end

  # message mutations
  object :message_mutations do
    field :create_message, type: :message_mutation_response do
      arg :body, non_null(:string)
      arg :group_id, non_null(:id)
      arg :file_ids, list_of(:id)
      arg :is_request, :boolean
      arg :recipient_usernames, list_of(:string)
      resolve &Resolver.create_message/2
    end

    field :update_message, type: :message_mutation_response do
      arg :message_id, non_null(:id)
      arg :body, :string
      arg :is_request, :boolean
      resolve &Resolver.update_message/2
    end

    field :delete_message, type: :message_mutation_response do
      arg :message_id, non_null(:id)
      resolve &Resolver.delete_message/2
    end

    field :mark_as_unread, type: :mark_as_unread_response do
      arg :message_ids, non_null(list_of(:id))
      arg :group_id, non_null(:id)
      resolve &Resolver.mark_as_unread/2
    end

    field :mark_as_read, type: :mark_as_unread_response do
      arg :message_ids, non_null(list_of(:id))
      arg :group_id, non_null(:id)
      resolve &Resolver.mark_as_read/2
    end

    field :create_message_reaction, :message_reaction_mutation_response do
      arg :message_id, non_null(:id)
      arg :value, non_null(:string)
      resolve &Resolver.create_message_reaction/2
    end

    field :delete_message_reaction, :message_reaction_mutation_response do
      arg :message_id, non_null(:id)
      arg :value, non_null(:string)
      resolve &Resolver.delete_message_reaction/2
    end
  end

  input_object :message_order do
    field :field, non_null(:message_order_field), default_value: :inserted_at
    field :direction, non_null(:order_direction), default_value: :desc
  end

  @desc "Filtering criteria for message connector."
  input_object :message_filters do
    @desc "Filter by subscription states."
    field :subscribe_state, :subscribe_state_filter, default_value: :all

    @desc "Filter by read states."
    field :read_state, :read_state_filter, default_value: :all

    @desc "Filter by message states."
    field :state, :message_state_filter, default_value: :all

    @desc "Filter by last activity."
    field :last_activity, :last_activity_filter, default_value: :all

    @desc "Filter by whether the message is a request."
    field :request_state, :request_state_filter, default_value: :all

    @desc "Filter by group type."
    field :type, :type_filter, default_value: :all

    @desc "Filter by sender."
    field :sender, :string

    @desc "Filter by recipients username."
    field :recipients, list_of(:string), default_value: []
  end

  input_object :reaction_order do
    field :field, non_null(:reaction_order_field)
    field :direction, non_null(:order_direction)
  end
end
