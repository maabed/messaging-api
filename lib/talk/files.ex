defmodule Talk.Files do
  @moduledoc "Functions for interacting with user file uploads."

  import Ecto.Query

  alias Ecto.Multi
  alias Talk.AssetStore
  alias Talk.Repo
  alias Talk.Schemas.{File, User}

  @spec file_url(File.t()) :: String.t()
  def file_url(%File{} = file) do
    AssetStore.file_url(file.id, file.filename)
  end

  @spec get_files(User.t(), [String.t()]) :: [File.t()] | no_return()
  def get_files(%User{} = user, file_ids) do
    user
    |> Ecto.assoc(:files)
    |> where([f], f.id in ^file_ids)
    |> Repo.all()
  end

  @spec upload_file(User.t(), Plug.Upload.t()) :: {:ok, %{file: File.t(), store: any()}}
          | {:error, :upload | :store, any(), any()} | {:error, atom()}
  def upload_file(%User{} = user, %Plug.Upload{} = upload) do
    upload
    |> get_file_contents()
    |> store_file(user, upload)
  end

  defp get_file_contents(%Plug.Upload{path: path_on_disk}) do
    Elixir.File.read(path_on_disk)
  end

  defp store_file({:ok, binary_data}, user, upload) do
    params = %{
      user_id: user.id,
      filename: upload.filename,
      content_type: upload.content_type,
      size: byte_size(binary_data)
    }

    Multi.new()
    |> Multi.insert(:file, File.create_changeset(%File{}, params))
    |> Multi.run(:store, fn %{file: %File{id: id, filename: filename}} ->
      AssetStore.persist_file(id, filename, binary_data, params.content_type)
    end)
    |> Repo.transaction()
  end

  defp store_file(err, _, _), do: err
end
