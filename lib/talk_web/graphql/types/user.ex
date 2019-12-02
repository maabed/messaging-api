defmodule TalkWeb.Type.User do
  @moduledoc "GraphQL types for users"

  use Absinthe.Schema.Notation

  alias Talk.AssetStore
  alias TalkWeb.Resolver.Users, as: UserResolver
  alias Talk.Groups

  object :user do
    field :id, non_null(:id)
    field :display_name, non_null(:string)
    field :email, non_null(:string)
    field :username, non_null(:string)
    field :profile_id, non_null(:string)
    field :inserted_at, non_null(:timestamp)
    field :updated_at, non_null(:timestamp)

    field :followers, non_null(:user_pagination) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :timestamp
      arg :after, :timestamp
      arg :order_by, :user_order
      resolve &UserResolver.followers/3
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

    field :avatar, :string do
      resolve fn user, _, _ ->
        if user.avatar do
          {:ok, AssetStore.avatar_url(user.avatar)}
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
      arg :display_name, :string
      arg :username, :string
      arg :email, :string
      arg :time_zone, :string
      resolve &UserResolver.update_user/2
    end

    field :update_user_avatar, type: :update_user_response do
      arg :data, non_null(:string)
      resolve &UserResolver.update_user_avatar/2
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
