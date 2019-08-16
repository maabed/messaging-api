defmodule Talk.AssetStore do
  @moduledoc """
  Responsible for taking file uploads and storing them.
  """

  @adapter Application.get_env(:talk, :asset_store)[:adapter]
  @bucket Application.get_env(:talk, :asset_store)[:bucket]

  @doc "Uploads an thumbnail with a randomly-generated file name."
  @spec persist_thumbnail(String.t()) :: {:ok, filename :: String.t()} | :error
  def persist_thumbnail(data) do
    case decode_base64_data_url(data) do
      {:ok, binary_data} ->
        binary_data
        |> build_thumbnail_path()
        |> @adapter.persist(@bucket, binary_data, nil)

      :error ->
        :error
    end
  end

  @doc "Generates the URL for a given thumbnail filename."
  @spec thumbnail_url(String.t()) :: String.t()
  def thumbnail_url(pathname), do: @adapter.public_url(pathname, @bucket)

  @doc "Uploads a file."
  @spec persist_file(String.t(), String.t(), binary(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def persist_file(unique_id, filename, binary_data, content_type) do
    unique_id
    |> build_file_path(filename)
    |> @adapter.persist(@bucket, binary_data, content_type)
  end

  @doc "Generates the URL for a file upload."
  @spec file_url(String.t(), String.t()) :: String.t()
  def file_url(unique_id, filename) do
    unique_id
    |> build_file_path(filename)
    |> @adapter.public_url(@bucket)
  end

  defp build_file_path(unique_id, filename), do: "uploads/" <> unique_id <> "/" <> filename

  defp decode_base64_data_url(raw_data) do
    raw_data
    |> extract_data()
    |> decode_base64_data()
  end

  defp extract_data(raw_data), do: Regex.run(~r/data:.*;base64,(.*)$/, raw_data)

  defp decode_base64_data([_, base64_part]), do: Base.decode64(base64_part)

  defp decode_base64_data(_), do: :error

  defp build_thumbnail_path(binary_data) do
    binary_data
    |> image_extension()
    |> unique_filename("thumbnail")
  end

  defp unique_filename(extension, prefix), do: prefix <> "/" <> Ecto.UUID.generate() <> extension

  defp image_extension(<<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _::binary>>), do: ".png"
  defp image_extension(<<0xFF, 0xD8, _::binary>>), do: ".jpg"
end
