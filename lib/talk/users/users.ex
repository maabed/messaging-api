defmodule Talk.Users do
  @moduledoc " The Users context."

  import Ecto.Query
  require Logger
  alias Talk.AssetStore
  alias Ecto.Changeset
  alias Talk.Repo
  alias Talk.Schemas.User

  @type query_result :: {:ok, User.t()} | {:error, String.t()}
  @type changeset_result :: {:ok, User.t()} | {:error, Changeset.t() | String.t()}

  @spec users_base_query(User.t()) :: Ecto.Query.t()
  def users_base_query(%User{} = _user) do
    from u in User,
      where: not is_nil(u.id)
      # where: u.id == ^user.id
  end

  @spec get_user_by_id(String.t()) :: query_result()
  def get_user_by_id(id) do
    case Repo.get(User, id) do
      %User{} = user ->
        {:ok, user}

      _ ->
        {:error, :not_found}
    end
  end

  @spec get_user_by_email(String.t()) :: query_result()
  def get_user_by_email(email) do
    case Repo.get_by!(User, email: email) do
      %User{} = user ->
        {:ok, user}

      _ ->
        {:error, :not_found}
    end
  end

  @spec get_user_by_email(User.t(), String.t()) :: query_result()
  def get_user_by_email(%User{} = user, email) do
    query =
      user
      |> users_base_query()
      |> where([u], u.email == ^email)

    case Repo.one(query) do
      %User{} = user ->
        {:ok, user}

      _ ->
        {:error, :not_found}
    end
  end

  @spec get_user_by_profile_id(String.t()) :: query_result()
  def get_user_by_profile_id(profile_id) do
    case Repo.get_by!(User, profile_id: profile_id) do
      %User{} = user ->
        {:ok, user}

      _ ->
        {:error, :not_found}
    end
  end

  def get_user_by_profile_id(%User{} = user, profile_id) do
    query =
      user
      |> users_base_query()
      |> where([u], u.profile_id == ^profile_id)

    case Repo.one(query) do
      %User{} = user ->
        {:ok, user}

      _ ->
        {:error, :not_found}
    end
  end

  @spec get_user_by_username( String.t()) :: query_result()
  def get_user_by_username(username) do
    case Repo.get_by!(User, username: username) do
      %User{} = user ->
        {:ok, user}

      _ ->
        {:error, :not_found}
    end
  end

  def get_user_by_username(%User{} = user, username) do
    query =
      user
      |> users_base_query()
      |> where([u], u.username == ^username)

    case Repo.one(query) do
      %User{} = user ->
        {:ok, user}

      _ ->
        {:error, :not_found}
    end
  end

  def get_user(%User{} = user, user_id) do
    query =
      user
      |> users_base_query()
      |> where([u], u.id == ^user_id)

    case Repo.one(query) do
      %User{} = user ->
        {:ok, user}

      _ ->
        {:error, :not_found}
    end
  end

  @spec create_user(map()) :: changeset_result()
  def create_user(params) do
    %User{}
    |> User.create_changeset(params)
    |> Repo.insert(on_conflict: :nothing)
    |> after_create_user()
  end

  defp after_create_user({:ok, user}), do: {:ok, user}
  defp after_create_user(err), do: err

  @spec update_user(User.t(), map()) :: changeset_result()
  def update_user(user, params) do
    user
    |> User.update_changeset(params)
    |> Repo.update()
    |> after_update_user()
  end

  defp after_update_user({:ok, %User{} = user}), do: {:ok, user}
  defp after_update_user({:error, :user, %Changeset{} = changeset, _}), do: {:error, changeset}
  defp after_update_user(_), do: {:error, "An unexpected error occurred"}

  @spec update_avatar(User.t(), String.t()) :: changeset_result()
  def update_avatar(user, raw_data) do
    raw_data
    |> AssetStore.persist_avatar()
    |> set_user_avatar(user)
  end

  defp set_user_avatar({:ok, filename}, user), do: update_user(user, %{avatar: filename})
  defp set_user_avatar(:error, _user), do: {:error, "An error occurred updating avatar"}


  def delete_user(%User{} = user) do
    user
    |> Repo.delete()
    |> after_delete_user()

    {:ok, true}
  end

  defp after_delete_user({:ok, _user}) do
    # remove users channel?
    :ok
  end

  defp after_delete_user(err), do: err

end
