defmodule Pantograf.Repo.Migrations.CreateTransitTripsTable do
  use Ecto.Migration

  def change do
    create table(:transit_trips) do
      add :identifier, :string
      add :headsign, :string

      add :route_id, references(:transit_routes, on_delete: :delete_all)
      add :shape_id, references(:transit_shapes, on_delete: :delete_all)

      timestamps(inserted_at: :created_at, updated_at: :updated_at)
    end
  end
end
