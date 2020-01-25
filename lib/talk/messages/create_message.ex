defmodule Talk.Messages.CreateMessage do
  @moduledoc false

  import Ecto.Query
  require Logger

  alias Talk.Repo
  alias Ecto.Multi
  alias Talk.{Events, Medias, Groups, Messages}
  alias Talk.Schemas.{Group, Message, MessageGroup, MessageLog, Profile, User}

  @type result :: {:ok, map()} | {:error, any(), any(), map()}

  @spec perform(User.t(), Group.t(), map()) :: result()
  def perform(%User{} = user, %Group{} = group, params) do
    Multi.new()
    |> insert_message(user, params)
    |> set_group(group, user)
    |> attach_medias(user, params)
    |> log(user)
    |> Repo.transaction()
    |> after_insert_message(user, group, params)
  end

  defp insert_message(multi, %User{} = user, params) do
    params_with_relations =
      params
      |> Map.put(:profile_id, user.profile_id)

    Multi.insert(multi, :message, Message.create_changeset(%Message{}, params_with_relations))
  end

  defp set_group(multi, group, user) do
    Multi.run(multi, :groups, fn _repo, %{message: message} ->
      params = %{
        message_id: message.id,
        group_id: group.id,
        profile_id: user.profile_id,
        read_status: "READ"
      }
      %MessageGroup{}
      |> Ecto.Changeset.change(params)
      |> Repo.insert(on_conflict: :nothing)

      {:ok, group}
    end)
  end

  defp attach_medias(multi, user, %{media: %Plug.Upload{} = upload}) do
    Multi.run(multi, :media, fn _repo, %{message: message} ->
      Medias.upload_media(user, upload, message)
    end)
  end

  defp attach_medias(multi, user, %{media_id: media_id}) do
    Multi.run(multi, :media, fn _repo, %{message: message} ->
      Medias.upload_media(user, media_id, message)
    end)
  end

  defp attach_medias(multi, _, _) do
    Multi.run(multi, :media, fn _repo, _ -> {:ok, []} end)
  end

  defp log(multi, user) do
    Multi.run(multi, :log, fn _repo, %{message: message} ->
      MessageLog.message_created(message, user.profile)
    end)
  end

  defp after_insert_message({:ok, %{message: message} = result}, user, group, params) do
    subscribe_recipients(message, group, user, params)
    subscribe_group_users(message, result, user)
    send_events(message)
    {:ok, result}
  end

  defp after_insert_message(err, _, _, _), do: err

  defp subscribe_recipients(_message, _group, _user, %{recipient_usernames: []}), do: nil

  defp subscribe_recipients(message, group, user, %{recipient_usernames: usernames}) do
    query =
      from p in Profile,
        where: p.username in ^usernames

    recipients = Repo.all(query)
    Enum.each(recipients, fn recipient ->
      if recipient.user_id === user.id do
        Messages.mark_as_read(recipient, group, [message])
      else
        Messages.mark_as_unread(recipient, group, [message])
      end
    end)
  end

  defp subscribe_recipients(_message, _group, _user, _params), do: nil

  defp subscribe_group_users(message, %{groups: group}, user) do
    {:ok, group_users} = Groups.list_members(group)
    group_users = Repo.preload(group_users, :profile)

    Enum.each(group_users, fn group_user ->
      if group_user.profile.user_id === user.id do
        Messages.mark_as_read(group_user.profile, group, [message])
      else
        Messages.mark_as_unread(group_user.profile, group, [message])
      end
    end)
  end

  defp send_events(message) do
    {:ok, profile_ids} = Messages.get_accessor_ids(message)
    Events.message_created(profile_ids, message)
  end
end
