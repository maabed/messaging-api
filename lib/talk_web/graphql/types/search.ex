defmodule TalkWeb.Type.Search do
  @moduledoc "GraphQL types for search"

  use Absinthe.Schema.Notation

  alias TalkWeb.Resolver.Search, as: Resolver

  object :search_users_result do
    field :id, :id
    field :profile_id, :id
    field :username, :string
    field :display_name, :string
    field :email, :string
    field :avatar, :string
    field :score, :float
  end

  object :search_groups_result do
    field :id, :id
    field :group_name, :string
    field :group_state, :string
    field :bookmarked, :boolean
    field :role, :string
    field :user_id, :id
    field :username, :string
    field :display_name, :string
    field :email, :string
    field :avatar, :string
    field :user_state, :string
    field :score, :float
  end

  object :search_queries do
    field :search_users, list_of(:search_users_result) do
      arg :query, :string
      resolve &Resolver.search_users/2
    end

    field :search_groups, list_of(:search_groups_result) do
      arg :query, :string
      resolve &Resolver.search_groups/2
    end
  end

end
