defmodule Talk.Loaders do
  @moduledoc " Sources for Dataloader."

  alias Talk.Loaders.Database

  def database_source(params) do
    Database.source(params)
  end
end
