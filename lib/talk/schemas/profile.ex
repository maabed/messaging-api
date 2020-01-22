defmodule Talk.Schemas.Profile do
  @moduledoc """
  The Profile context.
  """
  use Ecto.Schema
  alias Talk.Schemas.{BlockedProfile, Follower, Group, GroupUser, Media, Message, User}

  @type t :: %__MODULE__{}
  @primary_key {:id, :string, autogenerate: false, source: :_id}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "profiles" do
    field :user_id, :string, source: :userId
    field :username, :string
    field :thumbnail, :map, load_in_query: false
    field :display_name, :string, source: :displayName
    field :inserted_at, :utc_datetime_usec, source: :created_at

    field :avatar, :string, virtual: true # Holds user avatar url
    field :rank, :integer, virtual: true # Holds user rank on search query

    field :time_zone, :string, virtual: true
    field :email, :string, virtual: true

    # field :updated_at, :utc_datetime_usec
    # field :deleted_at, :utc_datetime_usec
    # field :badges, {:array, :string}
    # field :description, :string
    # field :points, :integer
    # field :reputation, :integer
    # field :cover_image_url, :map
    # field :privacySettings, :map
    # field :contactInformation, :map
    # field :emailNotifications, :map
    # field :notificationSettings, :map
    # field :selected_at, :utc_datetime_usec

    belongs_to(
      :user, User,
      define_field: false,
      foreign_key: :user_id,
      type: :string,
      source: :userId,
      references: :id
    )

    has_many :media_objects, Media, foreign_key: :created_by
    has_many :groups, Group
    has_many :messages, Message
    has_many :group_users, GroupUser

    many_to_many(
      :followers,
      __MODULE__,
      join_through: Follower,
      join_keys: [follower_id: :id, following_id: :id],
      on_replace: :delete
    )

    many_to_many(
      :followings,
      __MODULE__,
      join_through: Follower,
      join_keys: [following_id: :id, follower_id: :id],
      on_replace: :delete
    )
    many_to_many(
      :blocked_by,
      __MODULE__,
      join_through: BlockedProfile,
      join_keys: [blocked_by_id: :id, blocked_profile_id: :id],
      on_replace: :delete
    )

    many_to_many(
      :blocked_profiles,
      __MODULE__,
      join_through: BlockedProfile,
      join_keys: [blocked_profile_id: :id, blocked_by_id: :id],
      on_replace: :delete
    )
  end
end
