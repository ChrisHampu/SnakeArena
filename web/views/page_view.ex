defmodule Web.PageView do
  use Web.Web, :view

  def index(_template, assigns) do
    render "index.html", assigns
  end
end
