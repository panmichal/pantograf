defmodule Pantograf.Repo.Migrations.CreateTransitNetworksTable do
  use Ecto.Migration

  def change do
    create table(:transit_networks) do
      add :name, :string

      timestamps(inserted_at: :created_at, updated_at: :updated_at)
    end
  end
end
