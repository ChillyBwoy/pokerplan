defmodule PokerplanWeb.Router do
  use PokerplanWeb, :router

  import PokerplanWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PokerplanWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PokerplanWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/rooms", PokerplanWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{PokerplanWeb.UserAuth, :ensure_authenticated}] do
      live "/:room_id", RoomLive
    end
  end

  scope "/auth", PokerplanWeb do
    pipe_through :browser

    get "/signout", AuthController, :signout
    get "/signin/:provider", AuthController, :request
    get "/signin/:provider/callback", AuthController, :callback
  end

  # Other scopes may use custom stacks.
  # scope "/api", PokerplanWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:pokerplan, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PokerplanWeb.Telemetry
    end
  end
end
