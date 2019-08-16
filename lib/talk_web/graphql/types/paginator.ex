defmodule TalkWeb.Type.Paginator do
  @moduledoc false

  use Absinthe.Schema.Notation

  @desc "Data for pagination."
  object :page_info do
    @desc "The cursor correspodning to the first node."
    field :start_cursor, :cursor

    @desc "The cursor corresponding to the last node."
    field :end_cursor, :cursor

    @desc "A boolean indicating whether there are more items going forward."
    field :has_next_page, non_null(:boolean)

    @desc "A boolean indicating whether there are more items going backward."
    field :has_previous_page, non_null(:boolean)
  end

  @desc "An edge in the user."
  object :user_edge do
    @desc "The item at the edge of the node."
    field :node, :user

    @desc "A cursor for use in pagination."
    field :cursor, non_null(:cursor)
  end

  @desc "A list of users"
  object :user_pagination do
    @desc "A list of edges."
    field :edges, list_of(:user_edge)

    @desc "Pagination data."
    field :page_info, non_null(:page_info)

    @desc "The total count of items."
    field :total_count, non_null(:integer)
  end

  @desc "group edge."
  object :group_edge do
    field :node, :group
    field :cursor, non_null(:cursor)
  end

  @desc "A list of groups"
  object :group_pagination do
    field :edges, list_of(:group_edge)
    field :page_info, non_null(:page_info)
    field :total_count, non_null(:integer)
  end

  @desc "group users edge."
  object :group_user_edge do
    field :node, :group_user
    field :cursor, non_null(:cursor)
  end

  object :group_user_pagination do
    field :edges, list_of(:group_user_edge)
    field :page_info, non_null(:page_info)
    field :total_count, non_null(:integer)
  end

  @desc "message edge."
  object :message_edge do
    field :node, :message
    field :cursor, non_null(:cursor)
  end

  object :message_pagination do
    field :edges, list_of(:message_edge)
    field :page_info, non_null(:page_info)
    field :total_count, non_null(:integer)
  end

  @desc "reactions edge."
  object :message_reaction_edge do
    field :node, :message_reaction
    field :cursor, non_null(:cursor)
  end

  object :message_reaction_pagination do
    field :edges, list_of(:message_reaction_edge)
    field :page_info, non_null(:page_info)
    field :total_count, non_null(:integer)
  end
end
