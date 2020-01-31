defmodule TalkWeb.Type.Message do
  @moduledoc "GraphQL types for messages"

  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers

  alias Talk.Schemas.Message
  alias Talk.Messages
  alias TalkWeb.Resolver.Messages, as: Resolver

  object :message do
    field :id, non_null(:id)
    field :content, :string
    field :media, :media do
      resolve fn message, _, _ ->
        if message.media do
          {:ok, message.media}
        else
          {:ok, nil}
        end
      end
    end
    field :status, non_null(:message_status)
    field :groups, list_of(:group), resolve: dataloader(:db)
    field :sender, non_null(:user), resolve: &Resolver.message_sender/3
    field :is_request, non_null(:boolean)
    field :recipients, list_of(:group_user), resolve: &Resolver.list_recipients/3
    field :updated_at, non_null(:timestamp)
    field :inserted_at, non_null(:timestamp)
    field :can_edit, non_null(:boolean), resolve: &Resolver.can_edit_message/3
    field :readers, list_of(:reader), resolve: &Resolver.read_status/3
    field :last_activity_at, non_null(:timestamp) do
      resolve fn
        %Message{last_activity_at: last_activity_at}, _, _ when not is_nil(last_activity_at) ->
          {:ok, last_activity_at}

        message, _, _ ->
          Messages.last_activity_at(message)
      end
    end

    field :reactions, non_null(:message_reaction_pagination) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :timestamp
      arg :after, :timestamp
      arg :order_by, :reaction_order
      resolve &Resolver.reactions/3
    end
  end

  object :media do
    field :id, :id
    field :url, :string
    field :size, :integer
    field :type, :string
    field :filename, :string
    field :extension, :string
    field :inserted_at, :time
  end

  object :reader do
    field :read_status, non_null(:string)
    field :profile_id, non_null(:string)
    field :user_id, non_null(:string)
    field :username, non_null(:string)
  end

  object :message_reaction do
    field :id, non_null(:id)
    field :profile, non_null(:profile), resolve: dataloader(:db)
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

  object :report do
    field :message_id, non_null(:id)
    field :reporter_id, non_null(:id)
    field :author_id, non_null(:id)
    field :status, :string
    field :reason, :string
    field :type, :string
  end

  object :report_mutation_response do
    interface :response
    field :success, non_null(:boolean)
    field :errors, list_of(:error)
    field :report, :report
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
      arg :content, :string
      arg :group_id, non_null(:id)
      arg :is_request, :boolean
      arg :media, :upload
      arg :media_id, :string
      arg :recipient_usernames, list_of(:string)
      resolve &Resolver.create_message/2
    end

    field :update_message, type: :message_mutation_response do
      arg :message_id, non_null(:id)
      arg :content, :string
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

    field :mark_as_request, type: :mark_as_unread_response do
      arg :message_ids, non_null(list_of(:id))
      arg :group_id, non_null(:id)
      resolve &Resolver.mark_as_request/2
    end

    field :mark_as_not_request, type: :mark_as_unread_response do
      arg :message_ids, non_null(list_of(:id))
      arg :group_id, non_null(:id)
      resolve &Resolver.mark_as_not_request/2
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

    field :create_report, :report_mutation_response do
      arg :type, :string
      arg :reason, non_null(:id)
      arg :message_id, non_null(:id)
      arg :author_id, non_null(:id)
      resolve &Resolver.create_report/2
    end
  end

  input_object :message_order do
    field :field, non_null(:message_order_field), default_value: :inserted_at
    field :direction, non_null(:order_direction), default_value: :desc
  end

  @desc "Filtering criteria for message connector."
  input_object :message_filters do
    @desc "Filter by subscription status."
    field :subscribe_status, :subscribe_status_filter, default_value: :all

    @desc "Filter by read status."
    field :read_status, :read_status_filter, default_value: :all

    @desc "Filter by message status."
    field :status, :message_status_filter, default_value: :all

    @desc "Filter by last activity."
    field :last_activity, :last_activity_filter, default_value: :all

    @desc "Filter by whether the message is a request."
    field :request_status, :request_status_filter, default_value: :all

    @desc "Filter by group type."
    field :type, :type_filter, default_value: :all

    @desc "Filter by sender."
    field :sender, :string

    @desc "Filter by recipients username."
    field :recipients, list_of(:string), default_value: []

    @desc "Filter by group id."
    field :group_id, :id
  end

  input_object :reaction_order do
    field :field, non_null(:reaction_order_field)
    field :direction, non_null(:order_direction)
  end
end
