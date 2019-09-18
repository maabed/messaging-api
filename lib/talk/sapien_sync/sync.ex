defmodule Talk.SapienDB.Sync do
  alias Talk.Utils
  alias Talk.SapienDB.Seed

  def sync_users do
    path = Utils.get_path("users")
    columns = [:id, :profile_id, :display_name, :email, :username, :avatar, :inserted_at, :updated_at]
    export_query =  """
      COPY (SELECT
        p."userId" AS id,
        p."_id" AS profile_id,
        display_name,
        email,
        username,
        thumbnail->>'avatar' AS avatar,
        p.created_at AS inserted_at,
        p.updated_at
      FROM profiles AS p
      LEFT JOIN users u ON p."userId" = u._id)
      TO '#{path}' WITH (FORMAT CSV, HEADER TRUE, DELIMITER '|', NULL '', quote E'\x01')
    """
    Seed.build_and_export_csv(path, "users", columns, export_query)
  end

  def sync_followers do
    path = Utils.get_path("followers")
    columns = [:following_id, :follower_id, :inserted_at, :updated_at]
    export_query =  """
      COPY (SELECT
        following_id,
        follower_id,
        "createdAt" AS inserted_at,
        "updatedAt" AS updated_at
      FROM followers)
      TO '#{path}' WITH (FORMAT CSV, HEADER TRUE, DELIMITER '|', NULL '', quote E'\x01')
    """
    Seed.build_and_export_csv(path, "followers", columns, export_query)
  end

  def sync_blocked_profiles do
    path = Utils.get_path("blocked_profiles")
    columns = [:blocked_profile_id, :blocked_by_id]
    export_query =  """
      COPY (SELECT
        blocked_profile_id,
        blocked_by_id
      FROM blocked_profiles)
      TO '#{path}' WITH (FORMAT CSV, HEADER TRUE, DELIMITER '|', NULL '', quote E'\x01')
    """
    Seed.build_and_export_csv(path, "blocked_profiles", columns, export_query)
  end
end
