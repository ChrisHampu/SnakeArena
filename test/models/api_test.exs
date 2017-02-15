defmodule Web.APITest do
  use Web.ModelCase

  alias Web.API

  @valid_attrs %{}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = API.changeset(%API{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = API.changeset(%API{}, @invalid_attrs)
    refute changeset.valid?
  end
end
