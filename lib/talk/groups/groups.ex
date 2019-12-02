defmodule Talk.Groups do
  @moduledoc "The Groups context."

  import Ecto.Query, warn: false
  require Logger

  alias Talk.Repo
  alias Ecto.Changeset
  alias Talk.{Groups, Events, Users}
  alias Talk.Schemas.{Group, GroupUser, Message, MessageGroup, User}

  @spec groups_base_query(User.t()) :: Ecto.Query.t()
  def groups_base_query(user), do: Groups.Query.base_query(user)

  @spec group_members_base_query(Group.t()) :: Ecto.Query.t()
  def group_members_base_query(group), do: Groups.Query.members_base_query(group)

  @spec group_recipients_base_query(User.t(), [String.t()]) :: Ecto.Query.t()
  def group_recipients_base_query(user, recipient_usernames), do: Groups.Query.recipients_base_query(user, recipient_usernames)

  @spec get_accessor_ids(Group.t()) :: {:ok, [String.t()]} | no_return()
  def get_accessor_ids(%Group{id: group_id, is_private: is_private}) do
    query =
      if is_private do
        from u in User,
          join: gu in assoc(u, :group_users),
          where: gu.group_id == ^group_id,
          select: u.id
      else
        from u in User,
          select: u.id
      end

    {:ok, Repo.all(query)}
  end


  @spec get_group(User.t(), String.t()) :: {:ok, Group.t()} | {:error, String.t()}
  def get_group(%User{} = user, id) do
    case Repo.get_by(groups_base_query(user), id: id) do
      %Group{} = group ->
        {:ok, group}

      _ ->
        {:error, nil}
    end
  end

  @spec get_group_by_name(User.t(), String.t()) :: {:ok, Group.t()} | {:error, String.t()}
  def get_group_by_name(%User{} = user, name) do
    query =
      from g in groups_base_query(user),
        where: g.name == ^name,
        limit: 1

    case Repo.one(query) do
      %Group{} = group ->
        {:ok, group}

      _ ->
        {:error, nil}
    end
  end

  @spec get_group_by_recipients(User.t(), [String.t()]) :: {:ok, Group.t()} | {:error, String.t()}
  def get_group_by_recipients(%User{} = user, recipient_usernames) do
    query =
      from g in group_recipients_base_query(user, recipient_usernames),
        limit: 1

    case Repo.one(query) do
      %Group{} = group ->
        {:ok, group}

      _ ->
        {:error, nil}
    end
  end

  @spec get_group_by_message_id(String.t(), String.t()) :: {:ok, Group.t()} | {:error, String.t()}
  def get_group_by_message_id(user_id, message_id) do
    {:ok, user} = Users.get_user_by_id(user_id)

    query =
      from g in groups_base_query(user),
        join: mg in MessageGroup,
        on: mg.message_id == ^message_id,
        where: mg.group_id == g.id,
        limit: 1

      case Repo.one(query) do
        %Group{} = group ->
          {:ok, group}

        _ ->
          {:error, nil}
      end
  end

  @spec group_exists?(User.t(), [String.t()]) :: {:ok, boolean()} | {:error, String.t()}
  def group_exists?(%User{} = user, recipient_usernames) do
    groups =
      group_recipients_base_query(user, recipient_usernames)
      |> Repo.all()

    {:ok, length(groups) >= 1, groups}
  end

  def group_exists?(nil), do: {:ok, false}

  @spec get_group_user(Group.t(), User.t()) :: {:ok, GroupUser.t() | nil}
  def get_group_user(%Group{id: group_id}, %User{id: user_id}) do
    GroupUser
    |> Repo.get_by(user_id: user_id, group_id: group_id)
    |> handle_get_group_user()
  end

  defp handle_get_group_user(%GroupUser{} = group_user), do: {:ok, group_user}
  defp handle_get_group_user(_), do: {:ok, nil}

  @spec create_group(User.t(), map()) :: {:ok, %{group: Group.t()}} | {:error, Changeset.t()}
  def create_group(user, %{recipient_usernames: recipient_usernames} = params \\ %{}) do
    usernames = Enum.uniq([user.username | recipient_usernames])

    query =
      from u in User,
        where: u.username in ^usernames

    case Repo.all(query) do
      [] -> {:error, :recipients_not_found}
      recipients ->
        case length(recipients) do
          1 -> {:error, :one_recipient} # saved messages?
          2 ->
            group_name =
              recipients
              |> Enum.map(fn recipient ->
                recipient.username
                |> String.downcase()
                |> String.replace(~r/\s+/, "_")
              end)
              |> Enum.uniq()
              |> Enum.sort()
              |> Enum.join("||")

            params_with_relations =
              params
              |> Map.delete(:recipient_usernames)
              |> Map.put(:user_id, user.id)
              |> Map.put(:name, "d-#{group_name}")

            %Group{}
            |> Group.create_changeset(params_with_relations)
            |> Repo.insert()
            |> after_create_group(user, recipients)

          # change when add support for groups > 2 users
          len when len > 2 -> {:error, :more_than_two_recipients}
          _ -> {:error, :error}
        end
    end
  end

  defp after_create_group({:ok, group}, _user, recipients) do
    Enum.each(recipients, fn recipient ->
      set_owner_role(group, recipient)
      subscribe(group, recipient)
    end)

    {:ok, accessor_ids} = get_accessor_ids(group)
    _ = Events.group_created(accessor_ids, group)

    {:ok, %{group: group}}
  end

  defp after_create_group(err, _, _), do: err

  @spec update_group(Group.t(), map()) :: {:ok, Group.t()} | {:error, Changeset.t()}
  def update_group(group, params) do
    group
    |> Group.update_changeset(params)
    |> Repo.update()
    |> after_update_group()
  end

  defp after_update_group({:ok, group} = result) do
    {:ok, accessor_ids} = get_accessor_ids(group)
    _ = Events.group_updated(accessor_ids, group)
    result
  end

  defp after_update_group(err), do: err

  @spec list_recipients(Group.t(), String.t()) :: {:ok, [GroupUser.t()]} | no_return()
  def list_recipients(group, msg_id) do
    base_query = group_members_base_query(group)

    query =
      from gu in subquery(base_query),
        left_join: m in Message,
        on: m.id == ^msg_id,
        where: m.user_id != gu.user_id,
        order_by: {:asc, gu.username}

    {:ok, Repo.all(query)}
  end

  @spec list_members(Group.t()) :: {:ok, [GroupUser.t()]} | no_return()
  def list_members(group) do
    base_query = group_members_base_query(group)

    query =
      from gu in subquery(base_query),
        where: gu.state in ["SUBSCRIBED", "UNSUBSCRIBED"],
        order_by: {:asc, gu.username}

    {:ok, Repo.all(query)}
  end

  @spec list_owners(Group.t()) :: {:ok, [GroupUser.t()]} | no_return()
  def list_owners(group) do
    base_query = group_members_base_query(group)

    query =
      from gu in subquery(base_query),
        where: gu.role == "OWNER",
        order_by: {:asc, gu.username}

    {:ok, Repo.all(query)}
  end

  @spec bookmark_group(Group.t(), User.t()) :: :ok | {:error, String.t()}
  def bookmark_group(group, user) do
    changeset =
      Changeset.change(%GroupUser{}, %{
        user_id: user.id,
        group_id: group.id,
        bookmarked: true
      })

    opts = [
      on_conflict: [set: [bookmarked: true]],
      conflict_target: [:user_id, :group_id]
    ]

    changeset
    |> Repo.insert(opts)
    |> after_bookmarked(group, user)
  end

  defp after_bookmarked({:ok, _}, group, user) do
    Events.group_bookmarked(user.id, group)
    :ok
  end

  defp after_bookmarked(err, _, _), do: err

  @spec unbookmark_group(Group.t(), User.t()) :: :ok | no_return()
  def unbookmark_group(group, user) do
    changeset =
      Changeset.change(%GroupUser{}, %{
        user_id: user.id,
        group_id: group.id,
        bookmarked: false
      })

    opts = [
      on_conflict: [set: [bookmarked: false]],
      conflict_target: [:user_id, :group_id]
    ]

    changeset
    |> Repo.insert(opts)
    |> after_unbookmark(group, user)
  end

  defp after_unbookmark({:ok, _}, group, user) do
    Events.group_unbookmarked(user.id, group)
    :ok
  end

  defp after_unbookmark(err, _, _), do: err

  @spec list_bookmarks(User.t()) :: [Group.t()] | no_return()
  def list_bookmarks(user) do
    base_query = groups_base_query(user)

    query =
      from gu in subquery(base_query),
        where: gu.bookmarked == true,
        order_by: {:asc, gu.inserted_at}

    {:ok, Repo.all(query)}
  end

  @spec is_bookmarked?(GroupUser.t() | nil) :: {:ok, boolean()}
  def is_bookmarked?(%GroupUser{} = group_user) do
    {:ok, group_user.bookmarked == true}
  end

  def is_bookmarked?(nil), do: {:ok, false}

  @spec close_group(Group.t()) :: {:ok, Group.t()} | {:error, Changeset.t()}
  def close_group(group) do
    group
    |> Changeset.change(state: "CLOSED")
    |> Repo.update()
    |> after_update_group()
  end

  @spec reopen_group(Group.t()) :: {:ok, Group.t()} | {:error, Changeset.t()}
  def reopen_group(group) do
    group
    |> Changeset.change(state: "OPEN")
    |> Repo.update()
    |> after_update_group()
  end

  @spec delete_group(User.t(), Group.t()) ::
          {:ok, Group.t()} | {:error, Changeset.t() | String.t()}
  def delete_group(current_user, group) do
    case get_user_role(group, current_user) do
      :owner ->
        group
        |> Changeset.change(state: "DELETED")
        |> Repo.update()
        |> after_update_group()

      _ ->
        {:error, "You are not authorized to perform this action."}
    end
  end

  @spec subscribe(Group.t(), User.t()) :: :ok | {:error, Changeset.t()}
  def subscribe(%Group{} = group, %User{} = user) do
    changeset =
      Changeset.change(%GroupUser{}, %{
        user_id: user.id,
        group_id: group.id,
        state: "SUBSCRIBED"
      })

    opts = [
      on_conflict: [set: [state: "SUBSCRIBED"]],
      conflict_target: [:user_id, :group_id]
    ]

    changeset
    |> Repo.insert(opts)
    |> after_subscribe(group, user)
  end

  defp after_subscribe({:ok, _}, group, user) do
    Events.subscribed_to_group(group.id, group, user)
    :ok
  end

  defp after_subscribe(err, _, _), do: err

  @spec unsubscribe(Group.t(), User.t()) :: :ok | {:error, Changeset.t()}
  def unsubscribe(%Group{} = group, %User{} = user) do
    changeset =
      Changeset.change(%GroupUser{}, %{
        user_id: user.id,
        group_id: group.id,
        state: "UNSUBSCRIBED"
      })

    opts = [
      on_conflict: [set: [state: "UNSUBSCRIBED"]],
      conflict_target: [:user_id, :group_id]
    ]

    changeset
    |> Repo.insert(opts)
    |> after_unsubscribe(group, user)
  end

  defp after_unsubscribe({:ok, _}, group, user) do
    Events.unsubscribed_from_group(group.id, group, user)
    :ok
  end

  defp after_unsubscribe(err, _, _), do: err

  @spec mute(Group.t(), User.t()) :: :ok | {:error, Changeset.t()}
  def mute(%Group{} = group, %User{} = user) do
    changeset =
      Changeset.change(%GroupUser{}, %{
        user_id: user.id,
        group_id: group.id,
        state: "MUTED"
      })

    opts = [
      on_conflict: [set: [state: "MUTED"]],
      conflict_target: [:user_id, :group_id]
    ]

    changeset
    |> Repo.insert(opts)
    |> after_mute(group, user)
  end

  defp after_mute({:ok, _}, group, user) do
    Events.group_muted(group.id, group, user)
    :ok
  end

  defp after_mute(err, _, _), do: err

  @spec archive(Group.t(), User.t()) :: :ok | {:error, Changeset.t()}
  def archive(%Group{} = group, %User{} = user) do
    changeset =
      Changeset.change(%GroupUser{}, %{
        user_id: user.id,
        group_id: group.id,
        state: "ARCHIVED"
      })

    opts = [
      on_conflict: [set: [state: "ARCHIVED"]],
      conflict_target: [:user_id, :group_id]
    ]

    changeset
    |> Repo.insert(opts)
    |> after_archive(group, user)
  end

  defp after_archive({:ok, _}, group, user) do
    Events.group_archived(group.id, group, user)
    :ok
  end

  defp after_archive(err, _, _), do: err

  @spec publicize(Group.t()) :: {:ok, Group.t()} | {:error, Changeset.t()}
  def publicize(%Group{} = group) do
    group
    |> Changeset.change(%{is_private: false})
    |> Repo.update()
  end

  @spec privatize(Group.t()) :: {:ok, Group.t()} | {:error, Changeset.t()}
  def privatize(%Group{} = group) do
    group
    |> Changeset.change(%{is_private: true})
    |> Repo.update()
  end

  @spec get_user_state(Group.t(), User.t()) :: :subscribed | :unsubscribed | :muted | :archived | nil
  def get_user_state(%Group{} = group, user) do
    case get_group_user(group, user) do
      {:ok, %GroupUser{state: "SUBSCRIBED"}} -> :subscribed
      {:ok, %GroupUser{state: "UNSUBSCRIBED"}} -> :unsubscribed
      {:ok, %GroupUser{state: "MUTED"}} -> :muted
      {:ok, %GroupUser{state: "ARCHIVED"}} -> :archived
      _ -> nil
    end
  end

  @spec get_user_role(Group.t(), User.t()) :: :owner | :admin | :member | nil
  def get_user_role(%Group{} = group, user) do
    case get_group_user(group, user) do
      {:ok, %GroupUser{role: "OWNER"}} -> :owner
      {:ok, %GroupUser{role: "ADMIN"}} -> :admin
      {:ok, %GroupUser{role: "MEMBER"}} -> :member
      _ -> nil
    end
  end

  @spec set_owner_role(Group.t(), User.t()) :: :ok | {:error, Changeset.t()}
  def set_owner_role(%Group{} = group, %User{} = user) do
    changeset =
      Changeset.change(%GroupUser{}, %{
        user_id: user.id,
        group_id: group.id,
        role: "OWNER"
      })

    opts = [
      on_conflict: [set: [role: "OWNER"]],
      conflict_target: [:user_id, :group_id]
    ]

    case Repo.insert(changeset, opts) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec set_admin_role(Group.t(), User.t()) :: :ok | {:error, Changeset.t()}
  def set_admin_role(%Group{} = group, %User{} = user) do
    changeset =
      Changeset.change(%GroupUser{}, %{
        user_id: user.id,
        group_id: group.id,
        role: "ADMIN"
      })

    opts = [
      on_conflict: [set: [role: "ADMIN"]],
      conflict_target: [:user_id, :group_id]
    ]

    case Repo.insert(changeset, opts) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec set_member_role(Group.t(), User.t()) :: :ok | {:error, Changeset.t()}
  def set_member_role(%Group{} = group, %User{} = user) do
    changeset =
      Changeset.change(%GroupUser{}, %{
        user_id: user.id,
        group_id: group.id,
        role: "MEMBER"
      })

    opts = [
      on_conflict: [set: [role: "MEMBER"]],
      conflict_target: [:user_id, :group_id]
    ]

    case Repo.insert(changeset, opts) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  def can_access_group?(user, group_id) do
    case get_group(user, group_id) do
      {:ok, _} -> true
      _ -> false
    end
  end

  def can_access_group?(nil), do: {:ok, false}

  @spec can_manage_permissions?(GroupUser.t() | nil) :: {:ok, boolean()}
  def can_manage_permissions?(%GroupUser{} = group_user) do
    {:ok, group_user.role == "OWNER"}
  end

  def can_manage_permissions?(nil), do: {:ok, false}
end
