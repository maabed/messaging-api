defmodule TalkWeb.Schema do
  @moduledoc "Absinthe schema."

  use Absinthe.Schema

  alias TalkWeb.Schema.Middleware

  import_types TalkWeb.Type.File
  import_types TalkWeb.Type.User
  import_types TalkWeb.Type.Enum
  import_types TalkWeb.Type.Group
  import_types TalkWeb.Type.Message
  import_types TalkWeb.Type.Paginator
  import_types TalkWeb.Type.Subscriptions

  def plugins, do: [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]

  def middleware(middleware, _field, _object), do: middleware ++ [Middleware.ErrorHandler]

  query do
    import_fields(:user_queries)
    import_fields(:group_queries)
    import_fields(:message_queries)
  end

  mutation do
    import_fields(:file_mutations)
    import_fields(:user_mutations)
    import_fields(:group_mutations)
    import_fields(:message_mutations)
  end

  subscription do
    import_fields(:subscriptions)
  end
end
