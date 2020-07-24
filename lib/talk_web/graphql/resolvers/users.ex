defmodule TalkWeb.Resolver.Users do
  @moduledoc "Resolver module for users queries and mutations"

  import Ecto.Query, warn: false

  alias Talk.{Groups, Users}
  alias Talk.AssetStore
  alias Talk.Schemas.User
  alias Talk.Users.Connector
  alias TalkWeb.Resolver.Helpers
  require Logger

  @type info :: %{context: %{user: User.t(), loader: Dataloader.t()}}
  @type mutation_error :: [%{attribute: String.t(), message: String.t()}]
  @type paginated_result :: {:ok, Pagination.Result.t()} | {:error, String.t()}
  @type user_mutation_result :: {:ok, %{success: boolean(), user: User.t() | nil,
        errors: mutation_error}} | {:error, String.t()}
  @type unread_result :: {:ok, %{success: boolean(), unread: integer() | nil,
        errors: mutation_error}} | {:error, String.t()}

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
  def avatar_url(%User{avatar: avatar} = _user, _args, _info) do
    if avatar do
      {:ok, AssetStore.avatar_url(avatar)}
    else
      {:ok, nil}
    end
  end

  @spec avatar_url(map(), map(), info()) :: paginated_result()
  def avatar_url(%{avatar: avatar} = _profile, _args,  _info) do
    if avatar do
      {:ok, AssetStore.avatar_url(avatar)}
    else
      {:ok, nil}
    end
  end

  @spec unread_count(map(), info()) :: unread_result()
  def unread_count(%{profile_id: profile_id}, %{context: %{user: current_user}}) do
    with {:ok, user} <- Users.get_user_by_profile_id(current_user, profile_id),
      {:ok, counts} <- Groups.total_user_unread_count(user) do
      {:ok, %{success: true, unread: counts, errors: []}}
    else
      {:ok, false} ->
        {:error, "You are not authorized to perform this action."}

      {:error, :updated_message, changeset, _} ->
        {:ok, %{success: false, unread: nil, errors: Helpers.format_errors(changeset)}}

      error ->
        error
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
