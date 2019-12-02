defmodule Talk.Messages.CreateMessage do
  @moduledoc false

  import Ecto.Query
  require Logger

  alias Talk.Repo
  alias Ecto.Multi
  alias Talk.{Events, Files, Groups, Messages}
  alias Talk.Schemas.{Group, Message, MessageGroup, User, UserLog}

  @type result :: {:ok, map()} | {:error, any(), any(), map()}

  @spec perform(User.t(), Group.t(), map()) :: result()
  def perform(%User{} = user, %Group{} = group, params) do
    Multi.new()
    |> insert_message(user, params)
    |> set_group(group, user)
    |> attach_files(user, params)
    |> log(user)
    |> Repo.transaction()
    |> after_insert_message(user, group, params)
  end

  # @spec perform(User.t(), map()) :: result()
  # def perform(%User{} = user, params) do
  #   Multi.new()
  #   |> insert_message(user, params)
  #   |> attach_files(user, params)
  #   |> log(user)
  #   |> Repo.transaction()
  #   |> after_insert_message(user, params)
  # end

  defp insert_message(multi, %User{} = user, params) do
    params_with_relations =
      params
      |> Map.put(:user_id, user.id)
    Multi.insert(multi, :message, Message.create_changeset(%Message{}, params_with_relations))
  end

  defp set_group(multi, group, user) do
    Multi.run(multi, :groups, fn _repo, %{message: message} ->
      params = %{
        message_id: message.id,
        group_id: group.id,
        user_id: user.id
      }

      %MessageGroup{}
      |> Ecto.Changeset.change(params)
      |> Repo.insert(on_conflict: :nothing)

      {:ok, group}
    end)
  end

  defp attach_files(multi, user, %{file_ids: file_ids}) do
    Multi.run(multi, :files, fn _repo, %{message: message} ->
      files = Files.get_files(user, file_ids)
      Messages.attach_files(message, files)
    end)
  end

  defp attach_files(multi, _, _) do
    Multi.run(multi, :files, fn _repo, _ -> {:ok, []} end)
  end

  defp log(multi, user) do
    Multi.run(multi, :log, fn _repo, %{message: message} ->
      UserLog.message_created(message, user)
    end)
  end

  defp after_insert_message({:ok, %{message: message} = result}, group, user, params) do
    subscribe_recipients(message, user, group, params)
    subscribe_group_users(message, result)
    send_events(message)

    {:ok, result}
  end

  defp after_insert_message(err, _, _, _), do: err

  defp subscribe_recipients(_message, _group, _user, %{recipient_usernames: []}), do: nil

  defp subscribe_recipients(message, group, _user, %{recipient_usernames: usernames}) do
    query =
      from u in User,
        where: u.username in ^usernames

    recipients = Repo.all(query)

    Enum.each(recipients, fn recipient ->
      Messages.mark_as_unread(recipient, group, [message])
    end)
  end

  defp subscribe_recipients(_message, _group, _user, _params), do: nil

  defp subscribe_group_users(message, %{groups: group}) do
    {:ok, group_users} = Groups.list_members(group)
    group_users = Repo.preload(group_users, :user)

    Enum.each(group_users, fn group_user ->
      Messages.mark_as_unread(group_user.user, group, [message])
    end)
  end

  defp send_events(message) do
    {:ok, user_ids} = Messages.get_accessor_ids(message)
    Events.message_created(user_ids, message)
  end
end
