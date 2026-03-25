defmodule WCoreWeb.Router do
  use WCoreWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WCoreWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WCoreWeb do
    pipe_through :browser

    live "/", DashboardLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", WCoreWeb do
  #   pipe_through :api
  # end
end
