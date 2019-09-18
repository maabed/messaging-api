defmodule TalkWeb.Resolver.Users do
  @moduledoc "Resolver module for users queries and mutations"

  import Ecto.Query, warn: false

  alias Ecto.Changeset
  alias Talk.Users
  alias Talk.Schemas.User
  alias Talk.Users.Connector
  alias TalkWeb.Resolver.Helpers

  @type info :: %{context: %{user: User.t(), loader: Dataloader.t()}}
  @type paginated_result :: {:ok, Pagination.Result.t()} | {:error, String.t()}
  @type user_mutation_result ::
      {:ok, %{success: boolean(), user: User.t() | nil,
      errors: [%{attribute: String.t(), message: String.t()}]}} | {:error, String.t()}

  @spec user(map(), info()) :: {:ok, User.t()} | {:error, String.t()}
  def user(%{id: user_id} = _args, %{context: %{user: user}} = _info) do
    case Users.get_user(user, user_id) do
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

  @spec update_user(map(), info()) :: user_mutation_result()
  def update_user(args, %{context: %{user: user}}) do
    case Users.update_user(user, args) do
      {:ok, user} ->
        {:ok, %{success: true, user: user, errors: []}}

      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, user: nil, errors: Helpers.format_errors(changeset)}}

      err ->
        err
    end
  end

  @spec update_user_avatar(map(), info()) :: user_mutation_result()
  def update_user_avatar(%{data: data}, %{context: %{user: user}}) do
    case Users.update_avatar(user, data) do
      {:ok, user} ->
        {:ok, %{success: true, user: user, errors: []}}

      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, user: nil, errors: Helpers.format_errors(changeset)}}

      _ ->
        {:ok, %{success: false, user: nil, errors: []}}
    end
  end
end
