defmodule Talk.AssetStore.S3Adapter do
  @moduledoc false

  alias ExAws.S3
  @giphy_url Application.get_env(:talk, :giphy_url)
  @behaviour Talk.AssetStore.Adapter

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

      ext when ext in [".jpg", ".jpeg", ".png"] ->
        "https://s3.us-east-1.amazonaws.com/" <> bucket <> "/uploads/" <> filename
    end

  end

  def avatar_public_url("http://" <> _ = full_url) do
    full_url
  end

  def avatar_public_url("https://" <> _ = full_url) do
    full_url
  end

  def avatar_public_url(pathname) do
    avatar_dir = Application.get_env(:talk, :avatar_dir)
    prefix = Application.get_env(:talk, :cdn_prefix)
    "https://" <> prefix <> ".sapien.network/" <> avatar_dir <> "/" <> pathname
  end
end
