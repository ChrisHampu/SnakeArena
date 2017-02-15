defmodule Web.APIController do
  use Web.Web, :controller

  alias Web.Board
  alias Web.Queue

  def register(conn, _params) do

    Board.init_board()

    Board.set_board_tile(2, 2, :snake)
    tile = Board.get_board_tile(2,2)

    render(conn, "register.json", tile: tile)
  end

  def status(conn, _params) do

    queue = Enum.map(Queue.get_all(), fn snake -> %{url: elem(snake, 0)} end)

    render(conn, "status.json", queue: queue)
  end

  def test_snake(conn, _params) do

    # Queue the URL root for the test snake API
    Queue.add({"localhost:4000/api/v1"})

    render(conn, "test_snake.json")
  end

  def start(conn, _params) do

    render(conn, "start.json")
  end

  def move(conn, _params) do

    render(conn, "move.json")
  end
end
