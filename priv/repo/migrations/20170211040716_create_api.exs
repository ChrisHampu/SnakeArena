defmodule Web.Repo.Migrations.CreateAPI do
  use Ecto.Migration

  def change do
    create table(:api) do

      timestamps()
    end

  end
end
