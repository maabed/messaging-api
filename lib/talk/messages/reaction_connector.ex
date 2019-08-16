defmodule Talk.Reactions.Connector do
  @moduledoc "paginated connector for fetching a message reactions."

  alias Talk.Pagination
  alias Talk.Pagination.Args
  alias Talk.Schemas.Message

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            order_by: %{
              field: :inserted_at,
              direction: :asc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          order_by: %{field: :inserted_at, direction: :asc | :desc}
        }

  @doc "Executes a paginated query for reactions."
  def get(%Message{} = message, args, _info) do
    query = Ecto.assoc(message, :message_reactions)
    Pagination.fetch_result(query, Args.build(args))
  end
end
