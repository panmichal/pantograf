defmodule Pantograf.Repo.Migrations.ChangeTransitNetworkNameToLocation do
  use Ecto.Migration

  def change do
    rename table("transit_networks"), :name, to: :location
  end
end
