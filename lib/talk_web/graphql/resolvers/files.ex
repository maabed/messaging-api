defmodule TalkWeb.Resolver.Files do
  @moduledoc "Resolver module for files queries and mutations."

  alias Ecto.Changeset
  alias Talk.{Files, Users}
  alias Talk.Schemas.{File, User}
  alias TalkWeb.Resolver.Helpers

  @type info :: %{context: %{user: User.t(), loader: Dataloader.t()}}
  @type file_mutation_result :: {:ok, %{success: boolean(), file: File.t() | nil,
        errors: [%{attribute: String.t(), file: String.t()}]}} | {:error, String.t()}


  @spec upload_file(map(), info()) :: file_mutation_result()
  def upload_file(%{file: upload}, %{context: %{user: user}}) do
    with {:ok, user} <- Users.get_user(user, user.id),
         {:ok, %{file: file}} <- Files.upload_file(user, upload) do
      {:ok, %{success: true, errors: [], file: file}}
    else
      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, errors: Helpers.format_errors(changeset)}}

      err ->
        err
    end
  end
end
