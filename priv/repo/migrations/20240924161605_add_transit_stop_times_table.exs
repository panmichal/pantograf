defmodule Pantograf.Repo.Migrations.AddTransitStopTimesTable do
  use Ecto.Migration

  def change do
    create table(:transit_stop_times) do
      add :arrival_time, :time
      add :departure_time, :time

      add :trip_id, references(:transit_trips, on_delete: :delete_all)
      add :stop_id, references(:transit_stops, on_delete: :delete_all)
    end
  end
end
