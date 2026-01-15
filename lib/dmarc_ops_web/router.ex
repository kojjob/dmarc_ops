defmodule DmarcOpsWeb.Router do
  use DmarcOpsWeb, :router

  import DmarcOpsWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DmarcOpsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DmarcOpsWeb do
    pipe_through :browser

    get "/", PageController, :home

    # Convenience redirects
    get "/login", Redirect, to: "/users/log-in"
    get "/register", Redirect, to: "/users/register"
    get "/signup", Redirect, to: "/users/register"
  end

  # Other scopes may use custom stacks.
  # scope "/api", DmarcOpsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:dmarc_ops, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DmarcOpsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", DmarcOpsWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{DmarcOpsWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      # Domain management
      live "/domains", DomainLive.Index, :index
      live "/domains/new", DomainLive.Index, :new
      live "/domains/:id", DomainLive.Show, :show
      live "/domains/:id/edit", DomainLive.Show, :edit
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", DmarcOpsWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{DmarcOpsWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
