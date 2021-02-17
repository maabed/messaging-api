defmodule TalkWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: TalkWeb

      import Plug.Conn
      import TalkWeb.Gettext
      alias TalkWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/talk_web/templates",
        namespace: TalkWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1]

      import TalkWeb.ErrorHelpers
      import TalkWeb.Gettext
      alias TalkWeb.Router.Helpers, as: Routes
    end
  end

  def router do
    quote do
      use Phoenix.Router #, log: false
      import TalkWeb.Plugs
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel #, log_join: false, log_handle_in: false
      import TalkWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
