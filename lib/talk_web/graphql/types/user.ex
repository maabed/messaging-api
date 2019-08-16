defmodule TalkWeb.Type.User do
  @moduledoc "GraphQL types for users"

  use Absinthe.Schema.Notation

  alias Talk.AssetStore
  alias TalkWeb.Resolver.Users, as: UserResolver
  alias TalkWeb.Resolver.Groups, as: GroupResolver
  alias Talk.Groups

  object :user do
    field :id, non_null(:id)
    field :name, non_null(:string)
    field :email, non_null(:string)
    field :username, non_null(:string)
    field :profile_id, non_null(:string)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)

    field :users, non_null(:user_pagination) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :user_order
      resolve &UserResolver.users/3
    end

    field :group_users, non_null(:group_user_pagination) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :group_order
      resolve &GroupResolver.group_users/3
    end

    field :bookmarks, list_of(:group) do
      resolve fn user, _args, %{context: %{user: user}} ->
        if user.user_id == user.id do
          {:ok, Groups.list_bookmarks(user)}
        else
          {:ok, nil}
        end
      end
    end

    field :thumbnail, :string do
      resolve fn user, _, _ ->
        if user.thumbnail do
          {:ok, AssetStore.thumbnail_url(user.thumbnail)}
        else
          {:ok, nil}
        end
      end
    end
  end

  object :user_queries do
    field :user, :user do
      arg :id, :id
      arg :email, :string
      arg :profile_id, :string
      resolve &UserResolver.user/2
    end
  end

  object :user_mutations do
    field :update_user, type: :update_user_response do
      arg :name, :string
      arg :username, :string
      arg :email, :string
      arg :time_zone, :string
      resolve &UserResolver.update_user/2
    end

    field :update_user_thumbnail, type: :update_user_response do
      arg :data, non_null(:string)
      resolve &UserResolver.update_user_thumbnail/2
    end
  end

  object :update_user_response do
    interface :response
    field :success, non_null(:boolean)
    field :errors, list_of(:error)
    field :user, :user
  end

  input_object :user_order do
    field :field, non_null(:user_order_field)
    field :direction, non_null(:order_direction)
  end
end
