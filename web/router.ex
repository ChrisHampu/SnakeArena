defmodule Web.Router do
  use Web.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Web do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  scope "/api", as: :api do
    pipe_through :api

    scope "/v1", as: :v1 do
      post "/register", Web.APIController, :register
      post "/status", Web.APIController, :status

      # Testing functionality as a dummy snake

      scope "/snake1", as: :snake1 do
        post "/test_snake", Web.APIController, :test_snake
        post "/move", Web.APIController, :move
        post "/start", Web.APIController, :start
      end

      scope "/snake2", as: :snake2 do
        post "/test_snake", Web.APIController, :test_snake2
        post "/move", Web.APIController, :move2
        post "/start", Web.APIController, :start2
      end
    end
  end
end
