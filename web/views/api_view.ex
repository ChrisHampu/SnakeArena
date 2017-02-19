defmodule Web.APIView do
  use Web.Web, :view

  def render("register.json", %{}) do
    "register"
  end

  def render("status.json", %{queue: queue, game: state}) do
    %{queue: queue, game: state}
  end
  
  def render("test_snake.json", %{}) do
    %{status: "registered"}
  end

  def render("test_snake2.json", %{}) do
    %{status: "registered"}
  end

  def render("start.json", %{}) do
    %{
      color: "#FF00FF",
      name: "Test Snake 1",
      taunt: "Test snake please ignore",
      head_url: "/path/to/icon",
      move_url: "localhost:4000/api/v1//snake1/move"
    }
  end

  def render("start2.json", %{}) do
    %{
      color: "#FF00FF",
      name: "Test Snake 2",
      taunt: "Test snake please ignore",
      head_url: "/path/to/icon",
      move_url: "localhost:4000/api/v1//snake2/move"
    }
  end

  def render("move.json", %{}) do
    case :rand.uniform(4) do
      1 -> %{move: "up"}
      2 -> %{move: "down"}
      3 -> %{move: "left"}
      _ -> %{move: "right"}
    end
  end

  def render("move2.json", %{}) do
    case :rand.uniform(4) do
      1 -> %{move: "up"}
      2 -> %{move: "down"}
      3 -> %{move: "left"}
      _ -> %{move: "right"}
    end
  end
end
