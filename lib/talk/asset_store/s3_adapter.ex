defmodule Talk.AssetStore.S3Adapter do
  @moduledoc false

  alias ExAws.S3

  @behaviour Talk.AssetStore.Adapter
  require Logger
  @impl true
  def persist(pathname, bucket, data, content_type) do
    opts = [
      {:acl, :public_read},
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
  def public_url({:ok, pathname}, bucket), do: {:ok, "https://s3.amazonaws.com/" <> bucket <> "/" <> pathname}
  def public_url(err, _bucket), do: err
end
