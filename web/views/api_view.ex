defmodule Web.APIView do
  use Web.Web, :view

  def render("register.json", %{tile: tile}) do
    tile
  end

  def render("status.json", %{api: api}) do
    %{data: %{}}
  end
end
