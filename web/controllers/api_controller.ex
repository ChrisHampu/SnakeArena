defmodule Web.APIController do
  use Web.Web, :controller

  alias Web.Queue
  alias Web.Game

  def register(conn, _params) do

    render(conn, "register.json")
  end

  def status(conn, _params) do

    queue = Enum.map(Queue.get_all(), fn snake -> %{url: elem(snake, 0)} end)

    render(conn, "status.json", queue: queue, game: Game.get_turn_state())
  end

  def test_snake(conn, _params) do

    # Queue the URL root for the test snake API
    Queue.add({"localhost:4000/api/v1/snake1"})

    render(conn, "test_snake.json")
  end

  def test_snake2(conn, _params) do

    # Queue the URL root for the test snake API
    Queue.add({"localhost:4000/api/v1/snake2"})

    render(conn, "test_snake2.json")
  end

  def start(conn, _params) do

    render(conn, "start.json")
  end

  def start2(conn, _params) do

    render(conn, "start2.json")
  end

  def move(conn, _params) do

    render(conn, "move.json")
  end

  def move2(conn, _params) do

    render(conn, "move2.json")
  end
end
