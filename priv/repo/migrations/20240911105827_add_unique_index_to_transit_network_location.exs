defmodule Pantograf.Repo.Migrations.AddUniqueIndexToTransitNetworkLocation do
  use Ecto.Migration

  def change do
    create unique_index(:transit_networks, [:location])
  end
end
