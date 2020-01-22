defmodule Talk.Loaders.Database do
  @moduledoc false

  import Ecto.Query, warn: false
  require Logger
  alias Talk.Repo
  alias Talk.{Groups, Messages, Users}
  alias Talk.Schemas.{
    BlockedProfile,
    Follower,
    Group,
    GroupUser,
    Media,
    Message,
    MessageReaction,
    Profile,
    User
  }

  def source(%{user: _user} = params) do
    Dataloader.Ecto.new(Repo, query: &query/2, default_params: params)
  end

  def source(_), do: raise("unauthorized")

  def query(User, %{user: user}), do: Users.users_base_query(user)

  def query(Profile, %{user: user}), do: Users.profiles_base_query(user)

  def query(Follower, %{user: user}), do: Users.followers_query(user)

  def query(BlockedProfile, %{user: user}), do: Users.blocked_query(user)

  def query(Group, %{user: user}), do: Groups.groups_base_query(user)

  def query(GroupUser, %{user: %User{profile_id: profile_id}}) do
    from gu in GroupUser,
      join: p in assoc(gu, :profile),
      where: p.id == ^profile_id
  end

  def query(Message, %{user: user}), do: Messages.messages_base_query(user)

  def query(MessageReaction, _), do: MessageReaction

  def query(Media, %{user: _user}), do: Media

  def query(batch_key, _params), do: raise("query for " <> to_string(batch_key) <> " not defined")
end
