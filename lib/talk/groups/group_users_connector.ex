defmodule Talk.GroupUsers.Connector do
  @moduledoc "A paginated connection for fetching a group's users"

  import Ecto.Query

  alias Talk.Pagination
  alias Talk.Pagination.Args
  alias Talk.Schemas.{Group, GroupUser}

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
          order_by: %{
            field: :username | :inserted_at,
            direction: :asc | :desc
          }
        }

  def get(group, args, %{context: %{user: _user}} = _info) do
    base_query =
      from gu in GroupUser,
        where: gu.group_id == ^group.id,
        join: u in assoc(gu, :user),
        select: %{gu | username: u.username}

    wrapped_query = from(gu in subquery(base_query))
    Pagination.fetch_result(wrapped_query, Args.build(args))
  end

  def get_by_user(user, args, %{context: %{user: current_user}} = _info) do
    if current_user == user do
      base_query =
        from gu in GroupUser,
          where: gu.user_id == ^user.id,
          join: g in Group,
          on: g.id == gu.group_id,
          select: %{gu | name: g.name}

      wrapped_query = from(gu in subquery(base_query))
      Pagination.fetch_result(wrapped_query, Args.build(args))
    else
      {:error, "Require authenticated user"}
    end
  end
end
