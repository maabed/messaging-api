defmodule Talk.Medias do
  @moduledoc "Functions for interacting with user media uploads."

  import Ecto.Query

  alias Ecto.Multi
  alias Talk.AssetStore
  alias Talk.Repo
  alias Talk.Schemas.{Media, Message, User}
  require Logger

  @adapter Application.get_env(:talk, :asset_store)[:adapter]
  @bucket Application.get_env(:talk, :asset_store)[:bucket]
  @giphy_html5_url Application.get_env(:talk, :giphy_html5_url)
  @allowed_format ~w(.jpg .jpeg .png .svg .gif .mp4)

  def get_medias(%User{profile: profile} = _user, media_ids) do
    profile
    |> Ecto.assoc(Media)
    |> where([f], f.id in ^media_ids)
    |> Repo.all()
  end

  def get_media_by_message_id(message_id) do
    case Repo.get_by(Media, message_id: message_id) do
      %Media{} = media ->
        {:ok, media}
      _ ->
        {:error, nil}
    end
  end

  def upload_media(%User{profile_id: profile_id} = _user, %Plug.Upload{} = upload, %Message{id: message_id} = _message) do
    case validate_format(upload) do
      {true, ext} ->
        binary = get_media_contents(upload)
        ext
        |> rename_media()
        |> store_media(ext, binary, profile_id, to_string(message_id))
      {false, _} ->
        {:error, :file_type_not_allowed}
    end
  end

  def upload_media(%User{profile_id: profile_id} = _user, media_id, %Message{id: message_id} = _message) do
    case validate_format(media_id) do
      {true, ext} ->
        store_media(media_id, ext, profile_id, to_string(message_id))
      {false, _} ->
        {:error, :file_type_not_allowed}
    end
  end

  def validate_format(%Plug.Upload{filename: filename} = _upload) do
    ext =
      filename
      |> Path.extname()
      |> String.downcase()
    valid = Enum.member?(@allowed_format, ext)
    {valid, ext}
  end

  def validate_format(filename) do
    ext =
    case String.ends_with?(filename, "html5") do
      true -> ".mp4"
      false ->
        case String.ends_with?(filename, ".gif") do
          true -> ".gif"
          false -> nil
        end
    end
    valid = Enum.member?(@allowed_format, ext)
    {valid, ext}
  end

  defp get_media_contents(%Plug.Upload{path: path_on_disk}) do
    Elixir.File.read(path_on_disk)
  end

  defp rename_media(ext) do
    AssetStore.random_alphabet() <> ext
  end

  defp store_media(filename, extension, {:ok, binary}, profile_id, message_id) do
    params = %{
      type: "IMAGE", # || upload.content_type,
      size: byte_size(binary),
      filename: filename,
      created_by: profile_id,
      extension: extension,
      message_id: message_id
    }

    Multi.new()
    |> Multi.insert(:media, Media.create_changeset(%Media{}, params))
    |> Multi.run(:url, fn _, %{media: %Media{filename: filename, type: type}} ->
      AssetStore.persist_file(filename, binary, type)
      |> @adapter.public_url(@bucket)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{media: media, url: url}} ->
       serialize_response(media, url)
      {:error, :url, _} ->
        {:error, :upload_to_store_error}
    end
  end

  defp store_media(_, _, err, _, _), do: err

  defp store_media(filename, ext, profile_id, message_id) do
    filename = if ext == ".gif", do: filename |> String.slice(0..-5), else: filename
    params = %{
      type: "IMAGE",
      filename: filename,
      created_by: profile_id,
      extension: ext,
      message_id: message_id
    }

    Multi.new()
    |> Multi.insert(:media, Media.create_changeset(%Media{}, params))
    |> Multi.run(:url, fn _, %{media: %Media{filename: filename}} ->
        {:ok, @giphy_html5_url <> "/" <> filename}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{media: media, url: url}} ->
       serialize_response(media, url)
      {:error, :url, _} ->
        {:error, :upload_to_store_error}
    end

  end

  def serialize_response(media, url) do
    media =
      media
      |> Map.delete(:__struct__)
      |> Map.delete(:__meta__)
      |> Map.put(:url, url)
      |> Enum.into(%{})

    {:ok, media }
  end
end
