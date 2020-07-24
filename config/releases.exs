import Config

config :talk,
  SECRET_KEY_BASE: System.fetch_env!("SECRET_KEY_BASE"),
  priv_key: System.fetch_env!("JWT_PRIVATE_KEY"),
  giphy_url: "https://media.giphy.com/media",
  bucket: System.fetch_env!("ASSET_STORE_BUCKET"),
  avatar_dir: System.fetch_env!("ASSET_AVATAR_DIR"),
  cdn_prefix: System.fetch_env!("CDN_PREFIX")

config :ex_aws,
  access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY"),
  region: "us-east-1"
