defmodule Web.APIControllerTest do
  use Web.ConnCase

  alias Web.API
  @valid_attrs %{}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end
end
