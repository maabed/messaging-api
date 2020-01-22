defmodule Talk.Users.Connector do
  @moduledoc "A paginated connector for fetching user."

  import Ecto.Query

  alias Talk.Pagination
  alias Talk.Pagination.Args
  alias Talk.Schemas.User
  alias Talk.Users
  require Logger

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            term: nil,
            order_by: %{
              field: :username,
              direction: :asc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          term: String.t() | nil,
          order_by: %{
            field: :username | :inserted_at | :rank,
            direction: :asc | :desc
          }
        }

  def get(%User{} = user, args, %{context: %{user: current_user}} = _info) do
    if current_user == user do
      base_query =
        user
        |> Users.users_base_query()

      wrapped_query = from(su in subquery(base_query))
      Pagination.fetch_result(wrapped_query, Args.build(args))
    else
      {:error, "unauthorized"}
    end
  end

  def get_followers(%User{} = user, args, %{context: %{user: current_user}} = _info) do
    if current_user == user do
      base_query =
        user
        |> Users.followers_query()

      wrapped_query = from(su in subquery(base_query))
      Pagination.fetch_result(wrapped_query, Args.build(args))
    else
      {:error, "unauthorized"}
    end
  end

  def search(args, %{context: %{user: user}}) do
    user
    |> process_args(args)
  end

  defp process_args(_user, %{term: nil}), do: {:error, :no_results}
  defp process_args(_user, %{term: term}) when term === "", do: {:error, :no_results}
  defp process_args(_user, %{term: term} = _args) when not is_binary(term), do: {:error, :no_results}
  defp process_args(user, %{term: term} = args) do
    base_query =
      "%" <> term <> "%"
      |> Users.users_search_base_query(user)

    wrapped_query = from(su in subquery(base_query))
    Pagination.fetch_result(wrapped_query, Args.build(args))
  end
end
