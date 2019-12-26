defmodule Talk.Groups.Connector do
  @moduledoc "A paginated connector for fetching groups."

  import Ecto.Query

  alias Talk.Groups
  alias Talk.Pagination
  alias Talk.Pagination.Args

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            state: :open,
            search_term: :nil,
            order_by: %{
              field: :name,
              direction: :asc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          state: :open | :closed | :deleted | :all,
          search_term: String.t() | nil,
          order_by: %{
            field: :name | :inserted_at,
            direction: :asc | :desc
          }
        }

  def get(args, %{context: %{user: user}}) do
    user
    |> Groups.Query.base_query()
    |> apply_search_filter(args)
    |> apply_state_filter(args)
    |> Pagination.fetch_result(Args.build(args))
  end

  defp apply_search_filter(query, %{search_term: nil}), do: query
  defp apply_search_filter(query, %{search_term: search_term}) when search_term === "", do: query
  defp apply_search_filter(query, %{search_term: search_term}) when not is_binary(search_term), do: query

  defp apply_search_filter(query, %{search_term: search_term}) do
    Groups.Query.search_query(query, search_term)
  end

  defp apply_state_filter(query, %{state: :open}) do
    where(query, state: "OPEN")
  end

  defp apply_state_filter(query, %{state: :closed}) do
    where(query, state: "CLOSED")
  end

  defp apply_state_filter(query, %{state: :deleted}) do
    where(query, state: "DELETED")
  end

  defp apply_state_filter(query, _), do: query
end
