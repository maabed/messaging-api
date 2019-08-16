defmodule Talk.Loaders.Database do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Talk.Repo
  alias Talk.{Groups, Messages, Users}
  alias Talk.Schemas.{File, Group, GroupUser, Message, MessageUser, MessageReaction, User}

  def source(%{user: _user} = params) do
    Dataloader.Ecto.new(Repo, query: &query/2, default_params: params)
  end

  def source(_), do: raise("unauthorized")

  # def query(User, %{user: _user}), do: User
  def query(User, %{user: user}), do: Users.users_base_query(user)

  def query(Group, %{user: user}), do: Groups.groups_base_query(user)

  def query(GroupUser, %{user: _user}), do: GroupUser

  def query(Message, %{user: user}), do: Messages.messages_base_query(user)

  def query(MessageUser, %{user: _user}), do: MessageUser

  def query(MessageReaction, _), do: MessageReaction

  def query(File, %{user: _user}), do: File

  def query(batch_key, _params), do: raise("query for " <> to_string(batch_key) <> " not defined")
end
