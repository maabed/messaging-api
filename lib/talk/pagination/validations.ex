defmodule Talk.Pagination.Validations do
  @moduledoc "Validates the limit arguments for pagination."

  alias Talk.Pagination.Args

  def validate_limit(%Args{first: nil, last: nil}) do
    {:error, "You must provide either a `first` or `last` value"}
  end

  def validate_limit(%Args{first: first, last: last})
      when is_integer(first) and is_integer(last) do
        {:error, "You must provide either a `first` or `last` value"}
  end

  def validate_limit(args), do: {:ok, args}
end
