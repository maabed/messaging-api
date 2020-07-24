defmodule Talk.AssetStore do
  @moduledoc """
  Responsible for taking file (media) uploads and storing them.
  """
  require Logger
  alias Talk.Schemas.Media
  alias Talk.AssetStore.S3Adapter

  @alphabet Enum.to_list(?a..?z) ++ Enum.to_list(?0..?9)

  @doc "Uploads an avatar with a randomly-generated file name."
  @spec persist_avatar(String.t()) :: {:ok, filename :: String.t()} | :error
  def persist_avatar(data) do
    case decode_base64_data_url(data) do
      {:ok, binary_data} ->
        binary_data
        |> build_avatar_path()
        |> S3Adapter.persist(bucket(), binary_data, nil)

      :error ->
        :error
    end
  end

  @doc "Generates the URL for a given avatar filename."
  @spec avatar_url(String.t()) :: String.t()
  def avatar_url(pathname) do
    S3Adapter.avatar_public_url(pathname)
  end

  def media_url(%Media{filename: filename, extension: extension} = _media) do
    filename
    |> S3Adapter.public_url(bucket(), extension)
  end

  @doc "Uploads a file."
  @spec persist_file(String.t(), binary(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def persist_file(filename, binary_data, type) do
    build_file_path(filename)
    |> S3Adapter.persist(bucket(), binary_data, type)
  end

  defp build_file_path(filename) do
    "uploads/" <> filename
  end

  defp decode_base64_data_url(raw_data) do
    raw_data
    |> extract_data()
    |> decode_base64_data()
  end

  defp extract_data(raw_data), do: Regex.run(~r/data:.*;base64,(.*)$/, raw_data)

  defp decode_base64_data([_, base64_part]), do: Base.decode64(base64_part)

  defp decode_base64_data(_), do: :error

  defp build_avatar_path(binary_data) do
    binary_data
    |> image_extension()
    |> unique_filename("avatar")
  end

  defp unique_filename(extension, prefix), do: prefix <> "/" <> random_alphabet() <> extension

  defp image_extension(<<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _::binary>>), do: ".png"
  defp image_extension(<<0xFF, 0xD8, _::binary>>), do: ".jpg"

  def random_alphabet() do
    @alphabet
    |> Enum.take_random(16)
    |> to_string
  end

  defp bucket do
    Application.get_env(:talk, :bucket)
  end
end
