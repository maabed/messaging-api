defmodule TalkWeb.Resolver.Groups do
  @moduledoc "Resolver module for groups queries and mutations"

  import Ecto.Query, warn: false

  alias Talk.Groups
  alias Talk.Schemas.{Group, User}
  alias Ecto.Changeset
  alias TalkWeb.Resolver.Helpers
  alias Talk.Groups.Connector, as: GroupsConnector
  alias Talk.GroupUsers.Connector, as: GroupUsersConnector


  @type info :: %{context: %{user: User.t(), loader: Dataloader.t()} | nil}
  @type paginated_result :: {:ok, Pagination.Result.t()} | {:error, String.t()}
  @type group_mutation_result :: {:ok, %{success: boolean(), group: Group.t() | nil,
    errors: [%{attribute: String.t(), message: String.t()}]}} | {:error, String.t()}
  @type subscribe_to_group_response :: {:ok, %{success: boolean(), group: Group.t(),
    errors: [%{attribute: String.t(), message: String.t()}]}} | {:error, String.t()}
  @type bookmark_group_response :: {:ok, %{is_bookmarked: boolean(), group: Group.t()}}
    | {:error, String.t()}

  @spec group(map(), info()) :: {:ok, Group.t()} | {:error, String.t()}
  def group(%{id: id} = _args, %{context: %{user: user}}) do
    Groups.get_group(user, id)
  end

  def group(%{name: name} = _args, %{context: %{user: user}}) do
    Groups.get_group_by_name(user, name)
  end

  def group(%{recipient_ids: recipient_ids} = _args, %{context: %{user: user}}) do
    Groups.get_group_by_recipients(user, recipient_ids)
  end

  def group(_args, _), do: {:error, "You must provide an `id`, `name` or `recipient ids`."}

  @spec groups(map(), info()) :: paginated_result()
  def groups(args, %{context: %{user: _user}} = info) do
    GroupsConnector.get(struct(GroupsConnector, args), info)
  end

  @spec group_users(User.t(), map(), info()) :: paginated_result()
  def group_users(%User{} = user, args, %{context: %{user: _user}} = info) do
    GroupUsersConnector.get_by_user(user, struct(GroupUsersConnector, args), info)
  end

  @spec group_users(Group.t(), map(), info()) :: paginated_result()
  def group_users(%Group{} = user, args, %{context: %{user: _user}} = info) do
    GroupUsersConnector.get(user, struct(GroupUsersConnector, args), info)
  end

  @spec create_group(map(), info()) :: group_mutation_result()
  def create_group(args, %{context: %{user: user}}) do
    with {:ok, false} <- Groups.group_exists?(user, args.recipient_ids),
         {:ok, %{group: group}} <- Groups.create_group(user, args) do
      {:ok, %{success: true, group: group, errors: []}}
    else
      {:error, changeset} ->
        %{success: false, group: nil, errors: Helpers.format_errors(changeset)}

      {:ok, true} ->
        with {:ok, [group]} = Groups.get_group_by_recipients(user, args.recipient_ids) do
          {:ok, %{success: true, group: group, errors: []}}
        end

      err ->
        err
    end
  end

  @spec update_group(map(), info()) :: group_mutation_result()
  def update_group(args, %{context: %{user: user}}) do
    with {:ok, group} <- Groups.get_group(user, args.group_id),
         {:ok, updated_group} <- Groups.update_group(group, args) do
      {:ok, %{success: true, group: updated_group, errors: []}}
    else
      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, group: nil, errors: Helpers.format_errors(changeset)}}

      err ->
        err
    end
  end

  @spec delete_group(map(), info()) :: group_mutation_result()
  def delete_group(args, %{context: %{user: user}}) do
    with {:ok, group} <- Groups.get_group(user, args.group_id),
         {:ok, _} <- Groups.delete_group(user, group) do
      {:ok, %{success: true, errors: []}}
    else
      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, group: nil, errors: Helpers.format_errors(changeset)}}

      err ->
        err
    end
  end

  @spec close_group(map(), info()) :: group_mutation_result()
  def close_group(args, %{context: %{user: user}}) do
    with {:ok, group} <- Groups.get_group(user, args.group_id),
         {:ok, updated_group} <- Groups.close_group(group) do
      {:ok, %{success: true, group: updated_group, errors: []}}
    else
      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, group: nil, errors: Helpers.format_errors(changeset)}}

      err ->
        err
    end
  end

  @spec reopen_group(map(), info()) :: group_mutation_result()
  def reopen_group(args, %{context: %{user: user}}) do
    with {:ok, group} <- Groups.get_group(user, args.group_id),
         {:ok, updated_group} <- Groups.reopen_group(group) do
      {:ok, %{success: true, group: updated_group, errors: []}}
    else
      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, group: nil, errors: Helpers.format_errors(changeset)}}

      err ->
        err
    end
  end

  @spec bookmark_group(map(), info()) :: bookmark_group_response()
  def bookmark_group(args, %{context: %{user: user}}) do
    with {:ok, group} <- Groups.get_group(user, args.group_id),
         :ok <- Groups.bookmark_group(group, user) do
      {:ok, %{is_bookmarked: true, group: group}}
    else
      err ->
        err
    end
  end

  @spec unbookmark_group(map(), info()) :: bookmark_group_response()
  def unbookmark_group(args, %{context: %{user: user}}) do
    with {:ok, group} <- Groups.get_group(user, args.group_id),
         :ok <- Groups.unbookmark_group(group, user) do
      {:ok, %{is_bookmarked: false, group: group}}
    else
      err ->
        err
    end
  end

  @spec subscribe_to_group(map(), info()) :: subscribe_to_group_response()
  def subscribe_to_group(args, %{context: %{user: user}}) do
    with {:ok, group} <- Groups.get_group(user, args.group_id),
         :ok <- Groups.subscribe(group, user) do
      {:ok, %{success: true, group: group, errors: []}}
    else
      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, group: nil, errors: Helpers.format_errors(changeset)}}

      err ->
        err
    end
  end

  @spec unsubscribe_from_group(map(), info()) :: subscribe_to_group_response()
  def unsubscribe_from_group(args, %{context: %{user: user}}) do
    with {:ok, group} <- Groups.get_group(user, args.group_id),
         :ok <- Groups.unsubscribe(group, user) do
      {:ok, %{success: true, group: group, errors: []}}
    else
      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, group: nil, errors: Helpers.format_errors(changeset)}}

      err ->
        err
    end
  end

  @spec mute_group(map(), info()) :: group_mutation_result()
  def mute_group(args, %{context: %{user: user}}) do
    with {:ok, group} <- Groups.get_group(user, args.group_id),
         :ok <- Groups.mute(group, user) do
      {:ok, %{success: true, group: group, errors: []}}
    else
      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, group: nil, errors: Helpers.format_errors(changeset)}}

      err ->
        err
    end
  end

  @spec archive_group(map(), info()) :: group_mutation_result()
  def archive_group(args, %{context: %{user: user}}) do
    with {:ok, group} <- Groups.get_group(user, args.group_id),
         :ok <- Groups.archive(group, user) do
      {:ok, %{success: true, group: group, errors: []}}
    else
      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, group: nil, errors: Helpers.format_errors(changeset)}}

      err ->
        err
    end
  end

  @spec privatize_group(map(), info()) :: group_mutation_result()
  def privatize_group(args, %{context: %{user: user}}) do
    with {:ok, group} <- Groups.get_group(user, args.group_id),
         {:ok, group_user} <- Groups.get_group_user(group, user),
         {:ok, true} <- Groups.can_manage_permissions?(group_user),
         {:ok, updated_group} <- Groups.privatize(group) do
      {:ok, %{success: true, group: updated_group, errors: []}}
    else
      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, group: nil, errors: Helpers.format_errors(changeset)}}

      {:ok, false} ->
        {:error, "You are not authorized to perform this action."}

      err ->
        err
    end
  end

  @spec publicize_group(map(), info()) :: group_mutation_result()
  def publicize_group(args, %{context: %{user: user}}) do
    with {:ok, group} <- Groups.get_group(user, args.group_id),
         {:ok, group_user} <- Groups.get_group_user(group, user),
         {:ok, true} <- Groups.can_manage_permissions?(group_user),
         {:ok, updated_group} <- Groups.publicize(group) do
      {:ok, %{success: true, group: updated_group, errors: []}}
    else
      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, group: nil, errors: Helpers.format_errors(changeset)}}

      {:ok, false} ->
        {:error, "You are not authorized to perform this action."}

      err ->
        err
    end
  end
end
