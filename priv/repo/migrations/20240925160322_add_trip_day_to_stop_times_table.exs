defmodule Pantograf.Repo.Migrations.AddTripDayToStopTimesTable do
  use Ecto.Migration

  def change do
    alter table(:transit_stop_times) do
      add :trip_day, :integer, null: false, default: 0
    end
  end
end
