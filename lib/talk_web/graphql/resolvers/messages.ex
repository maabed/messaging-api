defmodule TalkWeb.Resolver.Messages do
  @moduledoc "Resolver module for messages queries and mutations"

  import Ecto.Query, warn: false
  import Absinthe.Resolution.Helpers
  require Logger

  alias Ecto.Changeset
  alias Talk.{Groups, Messages, Users}
  alias Talk.Schemas.{Group, Message, User}
  alias TalkWeb.Resolver.Helpers
  alias Talk.Messages.Connector
  alias Talk.Reactions.Connector, as: ReactionConnector

  @type info :: %{context: %{user: User.t(), loader: Dataloader.t()} | nil}
  @type paginated_result :: {:ok, Pagination.Result.t()} | {:error, String.t()}
  @type dataloader_result :: {:middleware, any(), any()}
  @type message_mutation_result :: {:ok, %{success: boolean(), message: Message.t() | nil,
      errors: [%{attribute: String.t(), message: String.t()}]}} | {:error, String.t()}
  @type message_reaction_result :: {:ok, %{
              success: boolean(),
              errors: [%{attribute: String.t(), message: String.t()}],
              message: Message.t() | nil,
              reaction: MessageReaction.t() | nil
          }} | {:error, String.t()}

  def messages(%Group{} = group, args, info) do
    Logger.warn("messages here ")
    Connector.get(group, struct(Connector, args), info)
  end

  @spec messages(map(), info()) :: paginated_result()
  def messages(args, info) do
    Logger.warn("messages here 1")

    Connector.get(nil, struct(Connector, args), info)
  end

  @spec message_sender(Message.t(), map(), info()) :: dataloader_result()
  def message_sender(%Message{user_id: user_id} = _message, _args, _info) when is_binary(user_id) do
    Users.get_user_by_id(user_id)
  end

  @spec can_edit_message(Message.t(), map(), info()) :: dataloader_result()
  def can_edit_message(%Message{} = message, _, %{context: %{loader: loader, user: user}}) do
    batch_key = User
    item_key = message.user_id

    loader
    |> Dataloader.load(:db, batch_key, item_key)
    |> on_load(fn loader ->
      loader
      |> Dataloader.get(:db, batch_key, item_key)
      |> check_edit_message_permissions(user)
    end)
  end

  defp check_edit_message_permissions(%User{} = message_sender, user) do
    {:ok, Messages.can_edit?(user, message_sender)}
  end

  defp check_edit_message_permissions(_, _user) do
    {:ok, false}
  end

  @spec reactions(Message.t(), map(), info()) :: paginated_result()
  def reactions(message, args, info) do
    ReactionConnector.get(message, struct(ReactionConnector, args), info)
  end

  @spec create_message(map(), info()) :: message_mutation_result()
  def create_message(%{group_id: _} = args, %{context: %{user: user}}) do
    with {:ok, group} <- Groups.get_group(user, args.group_id),
         {:ok, %{message: message}} <- Messages.create_message(user, group, args) do
      {:ok, %{success: true, message: message, errors: []}}
    else
      {:error, :message, changeset, _} ->
        {:ok, %{success: false, message: nil, errors: Helpers.format_errors(changeset)}}

      err ->
        err
    end
  end

  @spec list_recipients(Message.t(), map(), info()) :: message_mutation_result()
  def list_recipients(%Message{id: id, user_id: user_id} = _message, _args, _info) do
    with {:ok, group} <- Groups.get_group_by_message_id(user_id, id),
         {:ok, users} <- Groups.list_recipients(group, id) do
      {:ok, users}
    else
      {:error, changeset} ->
        {:ok, %{success: false, message: nil, errors: Helpers.format_errors(changeset)}}

      err ->
        err
    end
  end

  # def create_message(args, %{context: %{user: user}}) do
  #   with {:ok, user} <- Users.get_user_by_id(user.id),
  #        {:ok, %{message: message}} <- Messages.create_message(user, args) do
  #     {:ok, %{success: true, message: message, errors: []}}
  #   else
  #     {:error, :message, changeset, _} ->
  #       {:ok, %{success: false, message: nil, errors: Helpers.format_errors(changeset)}}

  #     err ->
  #       err
  #   end
  # end

  @spec update_message(map(), info()) :: message_mutation_result()
  def update_message(args, %{context: %{user: user}}) do
    with {:ok, message} <- Messages.get_message(user, args.message_id),
         {:ok, %{updated_message: updated_message}} <- Messages.update_message(user, message, args) do
      {:ok, %{success: true, message: updated_message, errors: []}}
    else
      {:error, :updated_message, changeset, _} ->
        {:ok, %{success: false, message: nil, errors: Helpers.format_errors(changeset)}}
      err ->
        err
    end
  end

  @spec delete_message(map(), info()) :: message_mutation_result()
  def delete_message(args, %{context: %{user: user}}) do
    with {:ok, message} <- Messages.get_message(user, args.message_id),
         {:ok, deleted_message} <- Messages.delete_message(user, message) do
      {:ok, %{success: true, message: deleted_message, errors: []}}
    else
      {:error, changeset} ->
        {:ok, %{success: false, message: nil, errors: Helpers.format_errors(changeset)}}
      err ->
        err
    end
  end

  @spec mark_as_unread(map(), info()) :: message_mutation_result()
          | {:error, String.t()}
  def mark_as_unread(args, %{context: %{user: user}}) do
    with {:ok, group} <- Groups.get_group(user, args.group_id),
         {:ok, messages} <- Messages.get_messages(user, args.message_ids),
         {:ok, unread_messages} <- Messages.mark_as_unread(user, group, messages) do
      {:ok, %{success: true, messages: unread_messages, errors: []}}
    else
      {:error, changeset} ->
        {:ok, %{success: false, message: nil, errors: Helpers.format_errors(changeset)}}
      err ->
        err
    end
  end

  @spec mark_as_read(map(), info()) :: message_mutation_result()
  def mark_as_read(args, %{context: %{user: user}}) do
    with {:ok, group} <- Groups.get_group(user, args.group_id),
         {:ok, messages} <- Messages.get_messages(user, args.message_ids),
         {:ok, read_messages} <- Messages.mark_as_read(user, group, messages) do
      {:ok, %{success: true, messages: read_messages, errors: []}}
    else
      {:error, changeset} ->
        {:ok, %{success: false, message: nil, errors: Helpers.format_errors(changeset)}}
      err ->
        err
    end
  end

  @spec create_message_reaction(map(), info()) :: message_reaction_result()
  def create_message_reaction(args, %{context: %{user: user}}) do
    with {:ok, message} <- Messages.get_message(user, args.message_id),
         {:ok, reaction} <- Messages.create_message_reaction(user, message, args.value) do
      {:ok, %{success: true, errors: [], message: message, reaction: reaction}}
    else
      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, errors: Helpers.format_errors(changeset), message: nil}}

      err ->
        err
    end
  end

  @spec delete_message_reaction(map(), info()) :: message_reaction_result()
  def delete_message_reaction(args, %{context: %{user: user}}) do
    with {:ok, message} <- Messages.get_message(user, args.message_id),
         {:ok, reaction} <- Messages.delete_message_reaction(user, message, args.value) do
      {:ok, %{success: true, errors: [], message: message, reaction: reaction}}
    else
      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, errors: Helpers.format_errors(changeset), message: nil, reaction: nil}}

      err ->
        err
    end
  end
end
