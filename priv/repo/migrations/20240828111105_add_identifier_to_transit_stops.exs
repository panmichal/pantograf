defmodule Pantograf.Repo.Migrations.AddIdentifierToTransitStops do
  use Ecto.Migration

  def change do
    alter table(:transit_stops) do
      add :identifier, :string
    end
  end
end
