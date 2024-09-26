defmodule Pantograf.Repo.Migrations.CreateTransitRouteTypesTable do
  use Ecto.Migration

  def change do
    create table(:transit_route_types) do
      add :name, :string
      add :identifier, :string

      add :network_id, references(:transit_networks, on_delete: :delete_all)

      timestamps(inserted_at: :created_at, updated_at: :updated_at)
    end
  end
end
