defmodule Web.APIView do
  use Web.Web, :view

  def render("register.json", %{tile: tile}) do
    tile
  end

  def render("status.json", %{queue: queue}) do
    %{queue: queue}
  end
  
  def render("test_snake.json", %{}) do
    %{status: "registered"}
  end

  def render("start.json", %{}) do
    %{
      color: "#FF00FF",
      name: "Test Snake",
      taunt: "Test snake please ignore",
      head_url: "/path/to/icon"
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
end
