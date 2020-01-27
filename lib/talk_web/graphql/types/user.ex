defmodule TalkWeb.Type.User do
  @moduledoc "GraphQL types for users"

  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers

  alias Talk.Groups
  alias TalkWeb.Resolver.Users, as: UserResolver

  object :user do
    field :id, non_null(:id)
    field :display_name, non_null(:string)
    field :email, non_null(:string)
    field :username, non_null(:string)
    field :profile_id, non_null(:string)
    field :inserted_at, non_null(:timestamp)
    field :updated_at, non_null(:timestamp)
    field :profile, non_null(:profile), resolve: dataloader(:db)
    field :avatar, :string, resolve: &UserResolver.avatar_url/3
    field :bookmarks, list_of(:group) do
      resolve fn user, _, %{context: %{user: current_user}} ->
        Groups.list_bookmarks(user, current_user)
      end
    end

    field :followers, non_null(:follower_pagination) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :timestamp
      arg :after, :timestamp
      arg :order_by, :user_order
      resolve &UserResolver.followers/3
    end
  end

  object :profile do
    field :id, non_null(:id)
    field :user_id, non_null(:id)
    field :username, non_null(:string)
    field :display_name, non_null(:string)
    field :avatar, :string, resolve: &UserResolver.avatar_url/3
  end

  object :user_queries do
    field :user, :user do
      arg :id, :id
      arg :email, :string
      arg :profile_id, :string
      resolve &UserResolver.user/2
    end

    field :users_search, list_of(:user_search_result) do
        arg :term, non_null(:string)
      resolve &UserResolver.search/2
    end
  end

  object :user_search_result do
    field :profile_id, non_null(:id)
    field :user_id, non_null(:id)
    field :username, non_null(:string)
    field :display_name, non_null(:string)
    field :avatar, :string, resolve: &UserResolver.avatar_url/3
    field :is_following, :boolean, resolve: &UserResolver.is_following/3
    field :rank, :float
  end

  input_object :user_order do
    field :field, non_null(:user_order_field)
    field :direction, non_null(:order_direction)
  end
end
