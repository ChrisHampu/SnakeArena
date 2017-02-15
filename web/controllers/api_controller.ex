defmodule Web.APIController do
  use Web.Web, :controller

  alias Web.Board

  def register(conn, _params) do

    Board.init_board()

    Board.set_board_tile(2, 2, :snake)
    tile = Board.get_board_tile(2,2)

    render(conn, "register.json", tile: tile)
  end

  def status(conn, _params) do
    #api = Repo.all(API)
    render(conn, "status.json")
  end
end
