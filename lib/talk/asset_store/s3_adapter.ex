defmodule Talk.AssetStore.S3Adapter do
  @moduledoc false

  alias ExAws.S3
  @cdn_url if Mix.env() == :dev, do: "https://images-local.sapien.network/", else: "https://images.sapien.network/"

  @behaviour Talk.AssetStore.Adapter
  require Logger
  @impl true
  def persist(pathname, bucket, data, content_type) do
    opts = [
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
  def public_url("https://" <> _ = full_url, _), do: full_url
  def public_url({:ok, pathname}, bucket), do: {:ok, "https://s3.us-east-1.amazonaws.com/" <> bucket <> "/" <> pathname}

  def public_url({:error, error}, _bucket), do: error

  def avatar_public_url(pathname, bucket) do
    @cdn_url <> bucket <> "/" <> pathname
  end
end
