defmodule Pantograf.Repo.Migrations.CreateTransitShapesTable do
  use Ecto.Migration

  def change do
    create table(:transit_shapes) do
      add :identifier, :string

      add :network_id, references(:transit_networks, on_delete: :delete_all)
    end

    execute("SELECT AddGeometryColumn ('transit_shapes','points',4326,'LINESTRING',2);")
  end
end
