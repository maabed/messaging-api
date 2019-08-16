defmodule TalkWeb.Type.File do
  @moduledoc "GraphQL types for files"

  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers

  alias Talk.Files
  alias TalkWeb.Resolver.Files, as: Resolver

  import_types Absinthe.Plug.Types

  object :file do
    field :id, non_null(:id)
    field :content_type, :string
    field :filename, non_null(:string)
    field :size, non_null(:integer)
    field :message, :message, resolve: dataloader(:db)
    field :inserted_at, non_null(:time)

    field :url, non_null(:string) do
      resolve fn file, _, _ ->
        {:ok, Files.file_url(file)}
      end
    end
  end

  object :file_mutations do
    field :upload_file, type: :upload_file_response do
      arg :file, non_null(:upload)
      resolve &Resolver.upload_file/2
    end
  end

  object :upload_file_response do
    interface :response
    field :success, non_null(:boolean)
    field :errors, list_of(:error)
    field :file, :file
  end
end
