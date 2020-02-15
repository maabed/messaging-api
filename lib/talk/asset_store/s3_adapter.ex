defmodule Talk.AssetStore.S3Adapter do
  @moduledoc false

  alias ExAws.S3
  @cdn_url if Mix.env() == :dev, do: "https://images-local.sapien.network/", else: "https://images.sapien.network/"
  @giphy_url Application.get_env(:talk, :giphy_url)
  @avatar_path Application.get_env(:talk, :avatar_dir)
  @avatar_dir Application.get_env(:talk, :asset_store)[:avatar_dir]

  @behaviour Talk.AssetStore.Adapter
  require Logger
  @impl true
  def persist(pathname, bucket, data, content_type) do
    opts = [
      # {:acl, :public_read},
      {:cache_control, "public, max-age=604800"},
      {:content_type, content_type || "binary/octet-stream"}
    ]

    bucket
    |> S3.put_object(pathname, data, opts)
    |> ExAws.request()
    |> handle_request(pathname)
  end

  defp handle_request({:ok, _}, pathname), do: {:ok, pathname}
  defp handle_request(err, _filename), do: err

  @impl true
  def public_url({:ok, pathname}, bucket) do
    {:ok, "https://s3.us-east-1.amazonaws.com/" <> bucket <> "/" <> pathname}
  end

  def public_url({:error, error}, _bucket), do: error

  def public_url(filename, bucket, extension) do
    case extension do
      ext when ext in [".gif", ".mp4"] ->
        @giphy_url <> "/" <> filename

      ext when ext in [".jpg", ".jpeg", ".png", ".svg"] ->
        "https://s3.us-east-1.amazonaws.com/" <> bucket <> "/uploads/" <> filename
    end

  end

  def avatar_public_url(pathname) do
    avatar_path = System.get_env("ASSET_AVATAR_DIR")
    Logger.warn("avatar_dir config [@avatar_path] #{inspect @avatar_path}")
    Logger.warn("avatar_dir System envs [avatar_path] #{inspect avatar_path}")
    Logger.warn("avatar_dir old [@avatar_dir]  #{inspect @avatar_dir}")
    Logger.warn("avatar_dir [pathname] #{inspect pathname}")

    @cdn_url <> "thumbnails/" <> pathname
  end
end
