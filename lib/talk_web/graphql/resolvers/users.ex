defmodule TalkWeb.Resolver.Users do
  @moduledoc "Resolver module for users queries and mutations"

  import Ecto.Query, warn: false

  alias Talk.Users
  alias Talk.AssetStore
  alias Talk.Schemas.User
  alias Talk.Users.Connector
  require Logger

  @type info :: %{context: %{user: User.t(), loader: Dataloader.t()}}
  @type paginated_result :: {:ok, Pagination.Result.t()} | {:error, String.t()}
  @type user_mutation_result ::
      {:ok, %{success: boolean(), user: User.t() | nil,
      errors: [%{attribute: String.t(), message: String.t()}]}} | {:error, String.t()}

  @spec user(map(), info()) :: {:ok, User.t()} | {:error, String.t()}
  def user(%{id: user_id} = _args, %{context: %{user: user}} = _info) do
    case Users.get_user_by_id(user, user_id) do
      {:ok, %{user: user}} ->
        {:ok, user}

      error ->
        error
    end
  end

  def user(%{email: email} = _args, %{context: %{user: user}} = _info) do
    case Users.get_user_by_email(user, email) do
      {:ok, %{user: user}} ->
        {:ok, user}

      error ->
        error
    end
  end

  def user(%{profile_id: profile_id} = _args, %{context: %{user: user}} = _info) do
    case Users.get_user_by_profile_id(user, profile_id) do
      {:ok, %{user: user}} ->
        {:ok, user}

      error ->
        error
    end
  end

  def user(_args, _info), do: {:error, "You must provide an argument by which to look up the user."}

  @spec users(User.t(), map(), info()) :: paginated_result()
  def users(%User{} = user, args, %{context: %{user: _user}} = info) do
    Connector.get(user, struct(Connector, args), info)
  end

  @spec avatar_url(User.t(), map(), info()) :: paginated_result()
  def avatar_url(%User{avatar: avatar} = user, _args, _info) do
    Logger.warn("avatar 1111 [user] #{inspect user, pretty: true}")
    if avatar do
      Logger.warn("avatar 1111 #{inspect avatar}")
      {:ok, AssetStore.avatar_url(avatar)}
    else
      Logger.warn("avatar 1111 nil")
      {:ok, nil}
    end
  end

  @spec avatar_url(map(), map(), info()) :: paginated_result()
  def avatar_url(%{avatar: avatar} = profile, _args,  _info) do
    Logger.warn("avatar 2222 [profile] #{inspect profile, pretty: true}")
    if avatar do
      Logger.warn("avatar 2222 #{inspect avatar}")
      {:ok, AssetStore.avatar_url(avatar)}
    else
      Logger.warn("avatar 2222 nil")
      {:ok, nil}
    end
  end

  @spec search(map(), info()) :: paginated_result()
  def search(args, info) do
    Connector.search(struct(Connector, args), info)
  end

  @spec is_following(map(), map(), info()) :: paginated_result()
  def is_following(profile, _,  %{context: %{user: user}} = _info) do
    {:ok, Users.is_following?(user, profile.id)}
  end

  @spec followers(User.t(), map(), info()) :: paginated_result()
  def followers(%User{} = user, args, info) do
    Connector.get_followers(user, struct(Connector, args), info)
  end
end
