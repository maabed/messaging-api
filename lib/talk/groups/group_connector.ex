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
            status: :open,
            term: :nil,
            order_by: %{
              field: :name,
              direction: :asc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          status: :open | :closed | :deleted | :all,
          term: String.t() | nil,
          order_by: %{
            field: :name | :inserted_at,
            direction: :asc | :desc
          }
        }

  def get(args, %{context: %{user: user}}) do
    user
    |> Groups.Query.base_query()
    |> apply_search_filter(args)
    |> apply_status_filter(args)
    |> Pagination.fetch_result(Args.build(args))
  end

  defp apply_search_filter(query, %{term: nil}), do: query
  defp apply_search_filter(query, %{term: term}) when term === "", do: query
  defp apply_search_filter(query, %{term: term}) when not is_binary(term), do: query

  defp apply_search_filter(query, %{term: term}) do
    Groups.Query.search(query, term)
  end

  defp apply_status_filter(query, %{status: :open}) do
    where(query, status: "OPEN")
  end

  defp apply_status_filter(query, %{status: :closed}) do
    where(query, status: "CLOSED")
  end

  defp apply_status_filter(query, %{status: :deleted}) do
    where(query, status: "DELETED")
  end

  defp apply_status_filter(query, _), do: query
end
