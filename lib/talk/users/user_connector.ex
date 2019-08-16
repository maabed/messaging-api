defmodule Talk.Users.Connector do
  @moduledoc "A paginated connector for fetching user."

  import Ecto.Query

  alias Talk.Pagination
  alias Talk.Pagination.Args
  alias Talk.Schemas.User
  alias Talk.Users

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            order_by: %{
              field: :username,
              direction: :asc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          order_by: %{field: :username | :inserted_at, direction: :asc | :desc}
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
end
