defmodule Pantograf.Repo.Migrations.AddTimestampsTransitShapes do
  use Ecto.Migration

  def change do
    alter table(:transit_shapes) do
      timestamps(inserted_at: :created_at, updated_at: :updated_at)
    end
  end
end
