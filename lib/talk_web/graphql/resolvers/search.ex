defmodule TalkWeb.Resolver.Search do
  @moduledoc "Resolver module for search queries."

  alias Ecto.Changeset
  alias Talk.Search
  alias Talk.Users
  alias Talk.Schemas.User
  alias TalkWeb.Resolver.Helpers

  @type info :: %{context: %{user: User.t(), loader: Dataloader.t()}}
  @type search_mutation_result :: {:ok, %{success: boolean(), user: User.t() | nil, errors: [%{attribute: String.t(), file: String.t()}]}}
                                  | {:error, String.t()}

  @spec search_users(map(), info()) :: search_mutation_result()
  def search_users(%{query: query}, %{context: %{user: user}}) do
    with {:ok, user} <- Users.get_user_by_id(user.id),
         results <- Search.users(query, user) do
      {:ok, results}
    else
      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, errors: Helpers.format_errors(changeset)}}

      err ->
        err
    end
  end

  @spec search_groups(map(), info()) :: search_mutation_result()
  def search_groups(%{query: query}, %{context: %{user: user}}) do
    with {:ok, user} <- Users.get_user_by_id(user.id),
         results <- Search.groups(query, user) do
      {:ok, results}
    else
      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, errors: Helpers.format_errors(changeset)}}

      err ->
        err
    end
  end
end
