defmodule Web.APIView do
  use Web.Web, :view

  def render("register.json", %{tile: tile}) do
    tile
  end

  def render("status.json", %{queue: queue}) do
    %{queue: queue}
  end
  
  def render("test_snake.json", %{}) do
    %{data: %{}}
  end

  def render("start.json", %{}) do
    %{data: %{}}
  end

  def render("move.json", %{}) do
    %{data: %{}}
  end
end
