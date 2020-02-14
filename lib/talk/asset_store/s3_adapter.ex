defmodule Talk.AssetStore.S3Adapter do
  @moduledoc false

  alias ExAws.S3
  @cdn_url if Mix.env() == :dev, do: "https://images-local.sapien.network/", else: "https://images.sapien.network/"
  @giphy_url Application.get_env(:talk, :giphy_url)

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

  def avatar_public_url(pathname, bucket) do
    Logger.warn("S3Adapter [@cdn_url] #{inspect @cdn_url}")
    Logger.warn("avatar_public_url pathname #{inspect pathname}")
    Logger.warn("avatar_public_url bucket #{inspect bucket}")
    @cdn_url <> bucket <> "/" <> pathname
  end
end
