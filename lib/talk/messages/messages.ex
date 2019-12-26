defmodule Talk.Messages do
  @moduledoc "The Messages context."

  import Ecto.Query, warn: false
  require Logger

  alias Talk.Repo
  alias Ecto.Changeset
  alias Talk.{Events, Messages}
  alias TalkWeb.Resolver.Helpers
  alias Talk.Messages.{CreateMessage, UpdateMessage}
  alias Talk.Schemas.{
    File,
    Group,
    GroupUser,
    Message,
    MessageFile,
    MessageGroup,
    MessageReaction,
    UserLog,
    User
  }

  @type create_message_result :: {:ok, map()} | {:error, any(), any(), map()}
  @type reaction_result :: {:ok, MessageReaction.t()} | {:error, Changeset.t()}

  @spec messages_base_query(User.t() | User.t()) :: Ecto.Query.t()
  def messages_base_query(user) do
    Messages.Query.base_query(user)
  end

  @spec get_message(User.t(), String.t()) :: {:ok, Message.t()} | {:error, String.t()}
  def get_message(%User{} = user, id) do
    user
    |> messages_base_query()
    |> Repo.get_by(id: id)
    |> handle_message_query()
  end

  defp handle_message_query(%Message{} = message) do
    {:ok, message}
  end

  defp handle_message_query(_) do
    {:error, nil}
  end

  @spec get_messages(User.t(), [String.t()]) :: {:ok, [Message.t()]} | no_return()
  def get_messages(%User{} = user, ids) do
    user
    |> messages_base_query()
    |> where([p], p.id in ^ids)
    |> Repo.all()
    |> handle_messages_query()
  end

  defp handle_messages_query(messages) do
    {:ok, messages}
  end

  # @spec get_subscribers(Message.t()) :: {:ok, [User.t()]}
  # def get_subscribers(%Message{id: message_id}) do
  #   query =
  #     from u in User,
  #       join: mu in assoc(u, :message_users),
  #       on: mu.message_id == ^message_id and mu.state == "SUBSCRIBED"

  #   query
  #   |> Repo.all()
  #   |> handle_get_subscribers()
  # end

  # defp handle_get_subscribers(subscribers) do
  #   {:ok, subscribers}
  # end

  # @spec create_message(User.t(), map()) :: create_message_result()
  # def create_message(user, params) do
  #   CreateMessage.perform(user, params)
  # end

  @spec create_message(User.t(), Group.t() | User.t(), map()) :: create_message_result()
  def create_message(user, group, params) do
    CreateMessage.perform(user, group, params)
  end

  @spec update_message(User.t(), Message.t(), map()) ::
          {:ok, %{updated_message: Message.t()}}
          | {:error, :unauthorized}
          | {:error, atom(), any(), map()}
  def update_message(%User{} = user, %Message{} = message, params) do
    UpdateMessage.perform(user, message, params)
  end

  @spec delete_message(User.t(), Message.t()) :: {:ok, Message.t()} | {:error, Changeset.t()}
  def delete_message(_user, message) do
    message
    |> Changeset.change(state: "DELETED")
    |> Repo.update()
    |> after_delete_message()
  end

  defp after_delete_message({:ok, message} = result) do
    {:ok, user_ids} = Messages.get_accessor_ids(message)
    _ = Events.message_deleted(user_ids, message)
    result
  end

  @spec mark_as_unread(User.t(), Group.t(), [Message.t()]) :: {:ok, [Message.t()]}
  def mark_as_unread(%User{} = user, group, messages) do
    user
    |> update_users_read_states(group, messages, %{read_state: "UNREAD"})
    |> after_mark_as_unread(user)
  end

  defp after_mark_as_unread({:ok, messages} = result, user) do
    Enum.each(messages, fn m ->
      UserLog.marked_as_unread(m, user)
    end)

    Events.messages_marked_as_unread(user.id, messages)
    result
  end

  @spec mark_as_read(User.t(), Group.t(), [Message.t()]) :: {:ok, [Message.t()]}
  def mark_as_read(%User{} = user, group, messages) do
    user
    |> update_users_read_states(group, messages, %{read_state: "READ"})
    |> after_mark_as_read(user)
  end

  defp after_mark_as_read({:ok, messages} = result, user) do
    Enum.each(messages, fn m ->
      UserLog.marked_as_read(m, user)
    end)

    Events.messages_marked_as_read(user.id, messages)
    result
  end

  # @spec get_user_state(Message.t(), User.t()) :: %{state: String.t()}
  # def get_user_state(%Message{id: message_id}, %User{id: user_id}) do
  #   case Repo.get_by(MessageUser, %{message_id: message_id, user_id: user_id}) do
  #     %MessageUser{state: state} ->
  #       %{state: state}

  #     _ ->
  #       %{state: "UNSUBSCRIBED"}
  #   end
  # end

  def can_access_message?(user, message_id) do
    case Messages.get_message(user, message_id) do
      {:ok, _} -> true
      _ -> false
    end
  end

  @spec can_edit?(User.t(), Message.t()) :: boolean()
  def can_edit?(%User{} = user, %Message{} = message) do
    user.id == message.user_id
  end

  @spec can_edit?(User.t(), User.t()) :: boolean()
  def can_edit?(%User{} = user, %User{} = message_sender) do
    user.id == message_sender.id
  end

  @spec attach_files(Message.t(), [File.t()]) :: {:ok, [File.t()]} | no_return()
  def attach_files(%Message{} = message, files) do
    results =
      Enum.map(files, fn file ->
        params = %{
          message_id: message.id,
          file_id: file.id
        }

        %MessageFile{}
        |> MessageFile.create_changeset(params)
        |> Repo.insert()
        |> handle_file_attached(file)
      end)

    {:ok, Enum.reject(results, &is_nil/1)}
  end

  def handle_file_attached({:ok, _}, file), do: file
  def handle_file_attached(_, _), do: nil

  @spec private?(Message.t()) :: {:ok, boolean()}
  def private?(%Message{} = message) do
    is_public =
      message
      |> Ecto.assoc(:groups)
      |> where([g], g.is_private == false)
      |> limit(1)
      |> Repo.all()

    {:ok, Enum.empty?(is_public)}
  end

  @spec get_accessor_ids(Message.t()) :: {:ok, [String.t()]} | no_return()
  def get_accessor_ids(%Message{id: message_id} = message) do
    query =
      case private?(message) do
        {:ok, true} ->
          from u in User,
            left_join: mg in MessageGroup,
            on: mg.message_id == ^message_id and mg.user_id == u.id,
            left_join: gu in GroupUser,
            on: gu.group_id == mg.group_id and gu.user_id == u.id,
            where: not is_nil(gu.id),
            distinct: u.id,
            select: u.id

        _ ->
          from u in User,
            select: u.id
      end

    query
    |> Repo.all()
    |> after_get_accessors()
  end

  defp after_get_accessors(ids) do
    {:ok, ids}
  end

  @spec last_activity_at(Message.t()) :: {:ok, DateTime.t()} | no_return()
  def last_activity_at(%Message{id: message_id} = message) do
    query =
      from pl in UserLog,
        where: pl.message_id == ^message_id,
        order_by: [desc: pl.happen_at],
        limit: 1

    case Repo.one(query) do
      %UserLog{happen_at: happen_at} ->
        {:ok, happen_at}

      _ ->
        {:ok, message.inserted_at}
    end
  end

  @spec create_message_reaction(User.t(), Message.t(), String.t()) :: reaction_result()
  def create_message_reaction(%User{} = user, %Message{} = message, value) do
    params = %{
      user_id: user.id,
      message_id: message.id,
      value: value
    }

    %MessageReaction{}
    |> MessageReaction.create_changeset(params)
    |> Repo.insert(on_conflict: :nothing, returning: true)
    |> after_create_message_reaction(user, message)
  end

  defp after_create_message_reaction({:ok, reaction}, user, message) do
    {:ok, user_ids} = get_accessor_ids(message)

    UserLog.message_reaction_created(message, user)
    Events.message_reaction_created(user_ids, message, reaction)

    # Notify the message author if the author is not a bot
    Repo.preload(message, :user)
    {:ok, reaction}
  end

  defp after_create_message_reaction(err, _, _), do: err

  @spec delete_message_reaction(User.t(), Message.t(), String.t()) :: reaction_result() | {:error, String.t()}
  def delete_message_reaction(%User{id: user_id} = user, %Message{id: message_id} = message, value) do
    query =
      from mr in MessageReaction,
        where: mr.user_id == ^user_id,
        where: mr.message_id == ^message_id,
        where: mr.value == ^value

    case Repo.one(query) do
      %MessageReaction{} = reaction ->
        reaction
        |> Repo.delete()
        |> after_delete_message_reaction(user, message)

      _ ->
        {:error, nil}
    end
  end

  defp after_delete_message_reaction({:ok, reaction}, _user, message) do
    {:ok, user_ids} = get_accessor_ids(message)
    Events.message_reaction_deleted(user_ids, message, reaction)
    {:ok, reaction}
  end

  defp after_delete_message_reaction(err, _, _), do: err

  defp update_users_read_states(user, group, messages, params) do
    updated_messages =
      Enum.filter(messages, fn msg ->
        :ok == update_user_state(user, group, msg, params)
      end)

    {:ok, updated_messages}
  end

  defp update_user_state(user, group, message, params) do
    full_params =
      params
      |> Map.put(:message_id, message.id)
      |> Map.put(:group_id, group.id)
      |> Map.put(:user_id, user.id)

    %MessageGroup{}
    |> Changeset.change(full_params)
    |> Repo.insert(
      on_conflict: :replace_all,
      conflict_target: [:message_id, :group_id, :user_id]
    )
    |> after_update_user_state()
  end

  defp after_update_user_state({:ok, _}), do: :ok
  defp after_update_user_state(_), do: :error

  @spec get_read_state(Group.t(), String.t(), String.t()) :: :message_user_state | nil
  def get_read_state(group, id, user_id) do
    get_message_read_state(group, id, user_id) |> IO.inspect
    with {:ok, message_groups} <- get_message_read_state(group, id, user_id) do
      {:ok, message_groups}
    else
      {:error, changeset} ->
        {:ok, %{success: false, message: nil, errors: Helpers.format_errors(changeset)}}

      err ->
        err
    end
  end

  @spec get_message_read_state(Group.t(), String.t(), String.t()) :: {:ok, MessageGroup.t() | nil}
  def get_message_read_state(%Group{id: group_id}, message_id, _user_id) do
    query = from mg in MessageGroup,
      join: u in assoc(mg, :user),
      where: mg.group_id == ^group_id,
      where: mg.message_id == ^message_id

    query
      |> Repo.all
      |> IO.inspect
      |> handle_get_message_read_state
  end

  defp handle_get_message_read_state(message_groups), do: {:ok, message_groups}
end
