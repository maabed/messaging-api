defmodule Talk.Messages.Connector do
  @moduledoc "Resolver module for messages queries and mutations"

  import Ecto.Query, warn: false
  require Logger

  alias Talk.Pagination
  alias Talk.Pagination.Args
  alias Talk.Messages
  alias Talk.Schemas.Group

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            filter: %{
              subscribe_status: :all,
              read_status: :all,
              status: :all,
              last_activity: :all,
              request_status: :all,
              type: :all,
              recipients: []
            },
            order_by: %{
              field: :inserted_at,
              direction: :desc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          filter: %{
            subscribe_status: :subscribed | :subscribed | :muted | :archived | :all,
            read_status: :read | :unread | :all,
            status: :valid | :expired | :deleted | :all,
            last_activity: :today | :all,
            request_status: :follower | :request | :all,
            type: :text | :image | :video | :all,
            sender: String.t(),
            recipients: [String.t()],
            group_id: String.t()
          },
          order_by: %{
            field: :inserted_at | :last_activity_at,
            direction: :asc | :desc
          }
        }

  @doc "Executes a paginated query for messages."
  @spec get(nil | Group.t(), map(), map()) :: {:ok, Pagination.Result.t()} | {:error, String.t()}
  def get(parent, args, %{context: %{user: user}}) do
    base_query =
      user
      |> Messages.Query.base_query()
      |> build_base_query(parent)
      |> apply_order_fields(args)
      |> apply_request_status(args)
      |> where_in_specific_group(args)
      |> apply_subscribe_status(args)
      |> apply_read_status(args)
      |> apply_status(args)
      |> apply_last_activity(args)
      |> apply_sender(args)
      |> apply_recipients(args)
      |> apply_type(args)

    pagination_args =
      args
      |> process_args()
      |> Args.build()

    query = from(p in subquery(base_query))
    Pagination.fetch_result(query, pagination_args)
  end

  defp build_base_query(query, %Group{id: group_id}) do
    Messages.Query.where_in_group(query, group_id)
  end

  defp build_base_query(query, _), do: query

  defp process_args(%{order_by: %{field: :inserted_at} = order_by} = args) do
    %{args | order_by: %{order_by | field: :inserted_at}}
  end

  defp process_args(args), do: args

  defp apply_order_fields(base_query, %{order_by: %{field: :last_activity_at}}) do
    Messages.Query.select_last_activity_at(base_query)
  end

  defp apply_order_fields(base_query, _), do: base_query

  defp apply_request_status(base_query, %{filter: %{request_status: :follower}}) do
    Messages.Query.where_is_follower(base_query)
  end

  defp apply_request_status(base_query, %{filter: %{request_status: :request}}) do
    Messages.Query.where_is_request(base_query)
  end

  defp apply_request_status(base_query, _), do: base_query

  defp apply_subscribe_status(base_query, %{filter: %{subscribe_status: :subscribed}}) do
    Messages.Query.where_subscribed(base_query)
  end

  defp apply_subscribe_status(base_query, %{filter: %{subscribe_status: :unsubscribed}}) do
    Messages.Query.where_unsubscribed(base_query)
  end

  defp apply_subscribe_status(base_query, %{filter: %{subscribe_status: :muted}}) do
    Messages.Query.where_muted(base_query)
  end

  defp apply_subscribe_status(base_query, %{filter: %{subscribe_status: :archived}}) do
    Messages.Query.where_archived(base_query)
  end

  defp apply_subscribe_status(base_query, _), do: base_query

  defp apply_status(base_query, %{filter: %{status: :valid}}) do
    Messages.Query.where_valid(base_query)
  end

  defp apply_status(base_query, %{filter: %{status: :expired}}) do
    Messages.Query.where_expired(base_query)
  end

  defp apply_status(base_query, %{filter: %{status: :deleted}}) do
    Messages.Query.where_deleted(base_query)
  end

  defp apply_status(base_query, _), do: base_query

  defp apply_read_status(base_query, %{filter: %{read_status: :read}}) do
    Messages.Query.where_read(base_query)
  end

  defp apply_read_status(base_query, %{filter: %{read_status: :unread}}) do
    Messages.Query.where_unread(base_query)
  end

  defp apply_read_status(base_query, _), do: base_query

  defp apply_last_activity(base_query, %{
         filter: %{last_activity: :today},
         order_by: %{field: :last_activity_at}
       }) do
    Messages.Query.where_last_active_today(base_query, DateTime.utc_now())
  end

  defp apply_last_activity(base_query, _) do
    base_query
  end

  defp apply_sender(base_query, %{filter: %{sender: username}}) do
    Messages.Query.where_sent_by(base_query, username)
  end

  defp apply_sender(base_query, _), do: base_query

  defp apply_recipients(base_query, %{filter: %{recipients: []}}), do: base_query

  defp apply_recipients(base_query, %{filter: %{recipients: usernames}}) do
    Messages.Query.where_specific_recipients(base_query, usernames)
  end

  defp apply_recipients(base_query, _), do: base_query

  defp where_in_specific_group(base_query, %{filter: %{group_id: group_id}}) do
    Messages.Query.where_in_group(base_query, group_id)
  end

  defp where_in_specific_group(base_query, _), do: base_query

  defp apply_type(base_query, %{filter: %{type: :text}}) do
    Messages.Query.where_type_text(base_query)
  end

  defp apply_type(base_query, %{filter: %{type: :image}}) do
    Messages.Query.where_type_image(base_query)
  end

  defp apply_type(base_query, %{filter: %{type: :video}}) do
    Messages.Query.where_type_video(base_query)
  end

  defp apply_type(base_query, _), do: base_query
end
