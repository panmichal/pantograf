defmodule Pantograf.Repo.Migrations.CreateTransitRoutesTable do
  use Ecto.Migration

  def change do
    create table(:transit_routes) do
      add :identifier, :string, null: false
      add :short_name, :string
      add :long_name, :string
      add :description, :text
      add :type, :integer
      add :custom_type, :string

      add :network_id, references(:transit_networks, on_delete: :delete_all)

      timestamps(inserted_at: :created_at, updated_at: :updated_at)
    end
  end
end
