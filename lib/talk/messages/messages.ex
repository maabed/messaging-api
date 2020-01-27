defmodule Talk.Messages do
  @moduledoc "The Messages context."

  import Ecto.Query, warn: false
  require Logger

  alias Talk.Repo
  alias Ecto.Changeset
  alias Talk.{Events, Messages}
  alias Talk.Messages.{CreateMessage, UpdateMessage}
  alias Talk.Schemas.{
    Group,
    GroupUser,
    Media,
    Message,
    MessageGroup,
    MessageReaction,
    MessageLog,
    Profile,
    Report,
    User
  }

  @type create_message_result :: {:ok, map()} | {:error, any(), any(), map()}
  @type reaction_result :: {:ok, MessageReaction.t()} | {:error, Changeset.t()}

  @spec messages_base_query(User.t()) :: Ecto.Query.t()
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
    |> where([m], m.id in ^ids)
    |> Repo.all()
    |> handle_messages_query()
  end

  defp handle_messages_query(messages) do
    {:ok, messages}
  end

  # @spec get_subscribers(Message.t()) :: {:ok, [User.t()]}
  # def get_subscribers(%Message{id: message_id}) do
  #   query =
  #     from p in Profile,
  #       join: mu in assoc(p, :message_users),
  #       on: mu.message_id == ^message_id and mu.status == "SUBSCRIBED"

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

  @spec create_message(User.t(), Group.t(), map()) :: create_message_result()
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
    |> Changeset.change(status: "DELETED")
    |> Repo.update()
    |> after_delete_message()
  end

  defp after_delete_message({:ok, message} = result) do
    {:ok, profile_ids} = Messages.get_accessor_ids(message)
    _ = Events.message_deleted(profile_ids, message)
    result
  end

  @spec mark_as_unread(Profile.t(), Group.t(), [Message.t()]) :: {:ok, [Message.t()]}
  def mark_as_unread(%Profile{} = profile, group, messages) do
    profile.id
    |> update_users_read_statuss(group, messages, %{read_status: "UNREAD"})
    |> after_mark_as_unread(profile)
  end

  defp after_mark_as_unread({:ok, messages} = result, profile) do
    Enum.each(messages, fn m ->
      MessageLog.marked_as_unread(m, profile)
    end)

    Events.messages_marked_as_unread(profile.id, messages)
    result
  end

  @spec mark_as_read(Profile.t(), Group.t(), [Message.t()]) :: {:ok, [Message.t()]}
  def mark_as_read(%Profile{} = profile, group, messages) do
    profile.id
    |> update_users_read_statuss(group, messages, %{read_status: "READ"})
    |> after_mark_as_read(profile)
  end

  defp after_mark_as_read({:ok, messages} = result, profile) do
    Enum.each(messages, fn m ->
      MessageLog.marked_as_read(m, profile)
    end)

    {:ok, profile_ids} = Messages.get_accessor_ids(Enum.at(messages, 0))
    Events.messages_marked_as_read(profile_ids, messages)
    result
  end

  def can_access_message?(user, message_id) do
    case Messages.get_message(user, message_id) do
      {:ok, _} -> true
      _ -> false
    end
  end

  @spec can_edit?(User.t(), Message.t()) :: boolean()
  def can_edit?(%User{} = user, %Message{} = message) do
    user.profile_id == message.profile_id
  end

  @spec can_edit?(User.t(), User.t()) :: boolean()
  def can_edit?(%User{} = user, %User{} = message_sender) do
    user.id == message_sender.id
  end

  @spec attach_medias(Message.t(), [Media.t()]) :: {:ok, [Media.t()]} | no_return()
  def attach_medias(%Message{} = message, medias) do
    results =
      Enum.map(medias, fn media ->
        media
        |> Media.update_changeset(%{message_id: message.id}) # set mo_for_object_id
        |> Repo.update()
        |> handle_media_attached(media)
      end)

    {:ok, Enum.reject(results, &is_nil/1)}
  end

  def handle_media_attached({:ok, _}, media), do: media
  def handle_media_attached(_, _), do: nil

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
          from p in Profile,
            left_join: mg in MessageGroup,
            on: mg.message_id == ^message_id and mg.profile_id == p.id,
            left_join: gu in GroupUser,
            on: gu.group_id == mg.group_id and gu.profile_id == p.id,
            where: not is_nil(gu.id),
            distinct: p.id,
            select: p.id

        _ ->
          from p in Profile,
            select: p.id
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
      from ml in MessageLog,
        where: ml.message_id == ^message_id,
        order_by: [desc: ml.happen_at],
        limit: 1

    case Repo.one(query) do
      %MessageLog{happen_at: happen_at} ->
        {:ok, happen_at}

      _ ->
        {:ok, message.inserted_at}
    end
  end

  @spec create_message_reaction(User.t(), Message.t(), String.t()) :: reaction_result()
  def create_message_reaction(%User{} = user, %Message{} = message, value) do
    params = %{
      profile_id: user.profile_id,
      message_id: message.id,
      value: value
    }

    %MessageReaction{}
    |> MessageReaction.create_changeset(params)
    |> Repo.insert(on_conflict: :nothing, returning: true)
    |> after_create_message_reaction(user, message)
  end

  defp after_create_message_reaction({:ok, reaction}, user, message) do
    {:ok, profile_ids} = get_accessor_ids(message)

    MessageLog.message_reaction_created(message, user.profile)
    Events.message_reaction_created(profile_ids, message, reaction)

    # Notify the message author if the author is not a bot
    Repo.preload(message, :profile)
    {:ok, reaction}
  end

  defp after_create_message_reaction(err, _, _), do: err

  @spec delete_message_reaction(User.t(), Message.t(), String.t()) :: reaction_result() | {:error, String.t()}
  def delete_message_reaction(%User{profile_id: profile_id} = user, %Message{id: message_id} = message, value) do
    query =
      from mr in MessageReaction,
        where: mr.profile_id == ^profile_id,
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
    {:ok, profile_ids} = get_accessor_ids(message)
    Events.message_reaction_deleted(profile_ids, message, reaction)
    {:ok, reaction}
  end

  defp after_delete_message_reaction(err, _, _), do: err

  defp update_users_read_statuss(profile_id, group, messages, params) do
    updated_messages =
      Enum.filter(messages, fn msg ->
        :ok == update_user_status(profile_id, group, msg, params)
      end)

    {:ok, updated_messages}
  end

  defp update_user_status(profile_id, group, message, params) do
    full_params =
      params
      |> Map.put(:message_id, message.id)
      |> Map.put(:group_id, group.id)
      |> Map.put(:profile_id, profile_id)

    %MessageGroup{}
    |> Changeset.change(full_params)
    |> Repo.insert(
      on_conflict: :replace_all,
      conflict_target: [:message_id, :group_id, :profile_id]
    )
    |> after_update_user_status()
  end

  defp after_update_user_status({:ok, _}), do: :ok
  defp after_update_user_status(_), do: :error

  @spec get_message_read_status(Group.t(), String.t(), String.t()) :: {:ok, MessageGroup.t() | nil}
  def get_message_read_status(%Group{id: group_id}, message_id, _profile_id) do
    query = from mg in MessageGroup,
      join: p in assoc(mg, :profile),
      where: mg.group_id == ^group_id,
      where: mg.message_id == ^message_id,
      select: %{
        profile_id: p.id,
        user_id: p.user_id,
        username: p.username,
        read_status: mg.read_status
      }

    query
      |> Repo.all
      |> handle_get_message_read_status
  end

  defp handle_get_message_read_status(message_groups), do: {:ok, message_groups}

  @spec create_report(User.t(), Message.t(), map()) :: create_message_result()
  def create_report(%User{} = user, %Message{} = message, %{author_id: author_id, reason: reason, type: type}) do
    params = %{
      reporter_id: user.profile_id,
      author_id: author_id,
      message_id: message.id,
      reason: reason,
      type: type
    }

    %Report{}
    |> Report.create_changeset(params)
    |> Repo.insert(on_conflict: :nothing, returning: true)
    |> after_create_report(user)
  end

  defp after_create_report({:ok, report}, _user) do
    {:ok, report}
  end

  defp after_create_report(err, _), do: err
end
