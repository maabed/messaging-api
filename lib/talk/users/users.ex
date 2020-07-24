defmodule Talk.Users do
  @moduledoc " The Users and Profiles context."

  import Ecto.Query
  require Logger
  alias Ecto.Changeset
  alias Talk.Repo
  alias Talk.Schemas.{BlockedProfile, Follower, Profile, User}

  @type query_result :: {:ok, User.t()} | {:error, String.t()}
  @type changeset_result :: {:ok, User.t()} | {:error, Changeset.t() | String.t()}

  @spec user_base_query() :: Ecto.Query.t()
  def user_base_query() do
    from(u in User,
      join: p in assoc(u, :profile),
      distinct: p.user_id,
      order_by: [desc_nulls_last: p.selected_at],
      select: %User{
        id: u.id,
        email: u.email,
        inserted_at: u.inserted_at,
        avatar: fragment("?->>?", p.thumbnail, "avatar"),
        username: p.username,
        display_name: p.display_name,
        profile_id: p.id,
        profile: p
      })
  end

  @spec user_base_query(User.t()) :: Ecto.Query.t()
  def user_base_query(%User{} = user) do
    user_base_query()
    |> where([u, _], u.id == ^user.id)
  end

  @spec users_base_query(User.t()) :: Ecto.Query.t()
  def users_base_query(%User{} = _user) do
    user_base_query()
    |> where([u, _], not is_nil(u.id))
    # join: f in Follower,
    # on: f.follower_id == p.id,
    # join: b in BlockedProfile,
    # on: b.blocked_by_id == ^profile.id,
    # where: f.following_id == p.id,
    # where: b.blocked_profile_id != p.id
  end

  @spec profiles_base_query(User.t()) :: Ecto.Query.t()
  def profiles_base_query(%User{} = _user) do
    from p in Profile,
      order_by: [desc_nulls_last: p.selected_at],
      distinct: p.user_id,
      join: u in assoc(p, :user),
      select: %{
        id: p.id,
        email: u.email,
        user_id: p.user_id,
        avatar: fragment("?->>?", p.thumbnail, "avatar"),
        username: p.username,
        display_name: p.display_name,
        inserted_at: p.inserted_at
      }
  end

  @spec get_user_by_id(User.t(), String.t()) :: query_result()
  def get_user_by_id(%User{} = user, user_id) do
    query =
      user
      |> user_base_query()

    case Repo.get(query, user_id) do
      %User{} = user ->
        {:ok, user}
      _ ->
        {:error, :not_found}
    end
  end

  @spec get_user_by_id(String.t()) :: query_result()
  def get_user_by_id(user_id) do
    query = user_base_query()

    case Repo.get(query, user_id) do
      %User{} = user ->
        {:ok, user}
      _ ->
        {:error, :not_found}
    end
  end

  @spec get_user_by_email(String.t()) :: query_result()
  def get_user_by_email(email) do
    query = user_base_query()

    case Repo.get_by(query, email: email) do
      %User{} = user ->
        {:ok, user}
      _ ->
        {:error, :not_found}
    end
  end

  @spec get_user_by_email(User.t(), String.t()) :: query_result()
  def get_user_by_email(%User{} = _user, email) do
    query = user_base_query()

    case Repo.get_by(query, email: email) do
      %User{} = user ->
        {:ok, user}
      _ ->
        {:error, :not_found}
    end
  end

  @spec get_user_by_username(String.t()) :: query_result()
  def get_user_by_username(username) do
    query =
      user_base_query()
      |> where([_, p], p.username == ^username)

    case Repo.one(query) do
      %User{} = user ->
        {:ok, user}
      _ ->
        {:error, :not_found}
    end
  end

  @spec get_user_by_profile_id(User.t(), String.t()) :: query_result()
  def get_user_by_profile_id(%User{} = user, profile_id) do
    query =
      user
      |> user_base_query()
      |> where([_, p], p.id == ^profile_id)

    case Repo.one(query) do
      %User{} = user ->
        {:ok, user}
      _ ->
        {:error, :not_found}
    end
  end

  @spec get_user_by_profile_id(String.t()) :: query_result()
  def get_user_by_profile_id(profile_id) do
    query =
      user_base_query()
      |> where([_, p], p.id == ^profile_id)

    case Repo.one(query) do
      %User{} = user ->
        {:ok, user}
      _ ->
        {:error, :not_found}
    end
  end

  @spec users_search_base_query(Ecto.Query.t(), String.t()) :: Ecto.Query.t()
  def users_search_base_query(term, %User{profile: profile} = _user) do
    from(p in Profile,
      left_join: p1 in Profile,
      on: p1.id == ^profile.id,
      left_join: b in BlockedProfile,
      on: b.blocked_by_id == ^profile.id,
      left_join: b1 in BlockedProfile,
      on: b1.blocked_profile_id != p.id,
      where: p1.id != p.id,
      where: ilike(p.username, ^term) or ilike(p.display_name, ^term),
      order_by: [desc_nulls_last: p.selected_at],
      distinct: p.userId
    )
    |> apply_rank_query(term)
    |> handle_users_search_results()
    # using similarity
    # where: fragment("similarity(?, ?) > ?", p.username, ^term, 0.2) or
    #        fragment("similarity(?, ?) > ?", p.display_name, ^term, 0.2)
  end

  @spec apply_rank_query(Ecto.Query.t(), String.t()) :: Ecto.Query.t()
  def apply_rank_query(query, term) do
    from p in query,
      select: %{
        id: p.id,
        profile_id: p.id,
        user_id: p.user_id,
        avatar: fragment("?->>?", p.thumbnail, "avatar"),
        username: p.username,
        display_name: p.display_name,
        rank: fragment(
          "GREATEST(similarity(?, ?), similarity(?, ?))",
          p.username, ^term, p.display_name, ^term
        )
      },
      limit: 20,
      order_by: fragment("rank DESC")
  end

  def handle_users_search_results(query) do
    case Repo.all(from(su in subquery(query))) do
      [] -> {:ok, nil}
      results -> {:ok, results}
    end
  end

  @spec followers_query(User.t()) :: Ecto.Query.t()
  def followers_query(%User{profile: profile} = _user) do
    from p in Profile,
      join: f in assoc(p, :followers),
      on: f.follower_id == ^profile.id,
      select: %{
        id: p.id,
        user_id: p.user_id,
        avatar: fragment("?->>?", p.thumbnail, "avatar"),
        username: p.username,
        display_name: p.display_name,
        inserted_at: p.inserted_at
      }
  end

  @spec followings_query(User.t()) :: Ecto.Query.t()
  def followings_query(%User{profile: profile} = _user) do
    from p in Profile,
      join: f in assoc(p, :followers),
      on: f.follower_id == ^profile.id
  end

  @spec blocked_query(User.t()) :: Ecto.Query.t()
  def blocked_query(%User{profile: profile} = _user) do
    from p in Profile,
      join: b in assoc(p, :blocked_profiles),
      where: b.blocked_by_id == ^profile.id
  end

  @spec get_followers(User.t()) :: Ecto.Query.t()
  def get_followers(%User{profile: profile} = _user) do
    profile = Repo.preload(profile, :followers)
    {:ok, profile.followers}
  end

  @spec get_blocked_profiles(User.t()) :: Ecto.Query.t()
  def get_blocked_profiles(%User{} = user) do
    profile = Repo.preload(user.profile, :blocked_profiles)
    {:ok, profile.blocked_profiles}
  end

  @spec is_following?(User.t(), String.t()) :: {:ok, boolean()}
  def is_following?(%User{} = user, profile_id) do
    query =
      from f in Follower,
        where: f.following_id == ^user.profile_id and f.follower_id == ^profile_id

    case Repo.one(query) do
      %Follower{} = _follower -> true
      _ -> false
    end
  end

  @spec is_blocked?(User.t(), String.t()) :: {:ok, boolean()}
  def is_blocked?(%User{} = user, profile_id) do
    query =
      from b in BlockedProfile,
        where: b.blocked_by_id == ^user.profile_id and b.blocked_profile_id == ^profile_id

    case Repo.one(query) do
      %BlockedProfile{} = _blocked -> true
      _ -> false
    end
  end
end
