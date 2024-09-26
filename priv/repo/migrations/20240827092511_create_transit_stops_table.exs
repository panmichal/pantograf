defmodule Pantograf.Repo.Migrations.CreateTransitStopsTable do
  use Ecto.Migration

  def change do
    create table(:transit_stops) do
      add :name, :string
      add :code, :string

      add :network_id, references(:transit_networks, on_delete: :delete_all)

      timestamps(inserted_at: :created_at, updated_at: :updated_at)
    end
  end
end
