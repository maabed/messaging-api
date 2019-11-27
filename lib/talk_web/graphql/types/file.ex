defmodule TalkWeb.Type.File do
  @moduledoc "GraphQL types for files"

  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers

  alias TalkWeb.Resolver.Files, as: Resolver

  object :file do
    field :id, non_null(:id)
    field :content_type, :string
    field :filename, non_null(:string)
    field :url, :string
    field :size, non_null(:integer)
    field :message, :message, resolve: dataloader(:db)
    field :inserted_at, non_null(:time)
  end

  object :upload_file_response do
    interface :response
    field :success, non_null(:boolean)
    field :errors, list_of(:error)
    field :file, :file
  end

  object :file_mutations do
    field :upload_file, type: :upload_file_response do
      arg :file, :upload
      resolve &Resolver.upload_file/2
    end
  end
end
