defmodule Pantograf.Repo.Migrations.AddCoordinatesToTransitStops do
  use Ecto.Migration

  def change do
    execute("SELECT AddGeometryColumn ('transit_stops','coordinates',4326,'POINT',2);")
  end
end
