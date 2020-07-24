defmodule TalkWeb.Resolver.Helpers do
  @moduledoc "Helpers for GraphQL query and mutations"

  import Absinthe.Resolution.Helpers

  def format_errors(%Ecto.Changeset{errors: errors}) do
    Enum.map(errors, fn {attr, {msg, props}} ->
      message =
        Enum.reduce(props, msg, fn {k, v}, acc ->
          String.replace(acc, "%{#{k}}", to_string(v))
        end)

      attribute =
        attr
        |> Atom.to_string()
        |> Absinthe.Utils.camelize(lower: true)

      %{attribute: attribute, message: message}
    end)
  end

  def loader_with_handler(args) do
    args.loader
    |> Dataloader.load(args.source_name, args.batch_key, args.item_key)
    |> on_load(fn loader ->
      loader
      |> Dataloader.get(args.source_name, args.batch_key, args.item_key)
      |> args.handler_fn.()
    end)
  end

end
