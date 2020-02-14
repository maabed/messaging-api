import Config

config :talk,
  priv_key: System.fetch_env!("JWT_PRIVATE_KEY"),
  SECRET_KEY_BASE: System.fetch_env!("SECRET_KEY_BASE")

config :talk, :asset_store,
  bucket: System.fetch_env!("ASSET_STORE_BUCKET"),
  avatar_dir: System.fetch_env!("ASSET_AVATAR_DIR"),
  adapter: Talk.AssetStore.S3Adapter

config :ex_aws,
  access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY"),
  region: "us-east-1"
