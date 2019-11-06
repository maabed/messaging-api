defmodule TalkWeb.Type.Group do
  @moduledoc "GraphQL types for groups"

  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers

  alias Talk.Groups
  alias Talk.Schemas.GroupUser
  alias TalkWeb.Resolver.Helpers
  alias TalkWeb.Resolver.Messages, as: MessageResolver
  alias TalkWeb.Resolver.Groups, as: GroupResolver

  import_types TalkWeb.Type.Custom

  object :group do
    field :id, non_null(:id)
    field :name, non_null(:string)
    field :description, :string
    field :state, non_null(:group_state)
    field :is_private, non_null(:boolean)
    field :inserted_at, non_null(:timestamp)
    field :updated_at, non_null(:timestamp)
    field :user, non_null(:user), resolve: dataloader(:db)

    field :messages, non_null(:message_pagination) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :timestamp
      arg :after, :timestamp
      arg :filter, :message_filters
      arg :order_by, :message_order
      resolve &MessageResolver.messages/3
    end

    field :group_users, non_null(:group_user_pagination) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :timestamp
      arg :after, :timestamp
      arg :order_by, :user_order
      resolve &GroupResolver.group_users/3
    end

    @desc "Group owner."
    field :owners, list_of(:group_user) do
      resolve fn group, _, _ -> Groups.list_owners(group) end
    end

    @desc "The group users."
    field :members, :group_user do
      resolve fn group, _, %{context: %{loader: loader}} ->
        Helpers.loader_with_handler(%{
          loader: loader,
          source_name: :db,
          batch_key: {:one, GroupUser},
          item_key: [group_id: group.id],
          handler_fn: fn record -> {:ok, record} end
        })
      end
    end

    field :is_bookmarked, non_null(:boolean) do
      resolve fn group, _, %{context: %{loader: loader}} ->
        Helpers.loader_with_handler(%{
          loader: loader,
          source_name: :db,
          batch_key: {:one, GroupUser},
          item_key: [group_id: group.id],
          handler_fn: &Groups.is_bookmarked?/1
        })
      end
    end

    field :can_manage_permissions, non_null(:boolean) do
      resolve fn group, _, %{context: %{loader: loader}} ->
        Helpers.loader_with_handler(%{
          loader: loader,
          source_name: :db,
          batch_key: {:one, GroupUser},
          item_key: [group_id: group.id],
          handler_fn: &Groups.can_manage_permissions?/1
        })
      end
    end
  end

  object :group_user do
    field :group, non_null(:group), resolve: dataloader(:db)
    field :user, non_null(:user), resolve: dataloader(:db)
    field :state, non_null(:group_user_state)
    field :role, non_null(:group_user_role)
  end

  object :group_mutation_response do
    interface :response
    field :success, non_null(:boolean)
    field :errors, list_of(:error)
    field :group, :group
  end

  object :delete_group_response do
    field :success, non_null(:boolean)
    field :errors, list_of(:error)
    interface :response
  end

  object :unsubscribe_from_group_response do
    field :success, non_null(:boolean)
    field :errors, list_of(:error)
    interface :response
  end

  object :bookmark_group_response do
    field :is_bookmarked, non_null(:boolean)
    field :group, non_null(:group)
  end

  @desc "group queries"
  object :group_queries do
    field :group, :group do
      arg :id, :id
      arg :name, :string
      resolve &GroupResolver.group/2
    end

    field :groups, non_null(:group_pagination) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :timestamp
      arg :after, :timestamp
      arg :order_by, :group_order
      arg :state, :group_state_filter, default_value: :open
      resolve &GroupResolver.groups/2
    end
  end

  @desc "group mutations"
  object :group_mutations do
    field :create_group, type: :group_mutation_response do
      arg :name, non_null(:string)
      arg :description, :string
      arg :is_private, :boolean, default_value: true
      resolve &GroupResolver.create_group/2
    end

    field :update_group, type: :group_mutation_response do
      arg :group_id, non_null(:id)
      arg :name, :string
      arg :description, :string
      resolve &GroupResolver.update_group/2
    end

    field :delete_group, type: :delete_group_response do
      arg :group_id, non_null(:id)
      resolve &GroupResolver.delete_group/2
    end

    field :bookmark_group, type: :bookmark_group_response do
      arg :group_id, non_null(:id)
      resolve &GroupResolver.bookmark_group/2
    end

    field :unbookmark_group, type: :bookmark_group_response do
      arg :group_id, non_null(:id)
      resolve &GroupResolver.unbookmark_group/2
    end

    field :privatize_group, type: :group_mutation_response do
      arg :group_id, non_null(:id)
      resolve &GroupResolver.privatize_group/2
    end

    field :publicize_group, type: :group_mutation_response do
      arg :group_id, non_null(:id)
      resolve &GroupResolver.publicize_group/2
    end

    field :close_group, type: :group_mutation_response do
      arg :group_id, non_null(:id)
      resolve &GroupResolver.close_group/2
    end

    field :reopen_group, type: :group_mutation_response do
      arg :group_id, non_null(:id)
      resolve &GroupResolver.reopen_group/2
    end

    field :subscribe_to_group, type: :group_mutation_response do
      arg :group_id, non_null(:id)
      resolve &GroupResolver.subscribe_to_group/2
    end

    field :unsubscribe_from_group, type: :unsubscribe_from_group_response do
      arg :group_id, non_null(:id)
      resolve &GroupResolver.unsubscribe_from_group/2
    end
  end

  input_object :group_order do
    field :field, non_null(:group_order_field)
    field :direction, non_null(:order_direction)
  end
end
