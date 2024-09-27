defmodule Pantograf.Transit.Trip do
  use Pantograf.Schema
  import Ecto.Changeset

  schema "transit_trips" do
    field :headsign, :string
    field :identifier, :string

    belongs_to :route, Pantograf.Transit.Route
    belongs_to :shape, Pantograf.Transit.Shape

    has_many :stop_times, Pantograf.Transit.StopTime
    has_many :stops, through: [:stop_times, :stop]

    timestamps(inserted_at: :created_at, updated_at: :updated_at)
  end

  def changeset(trip, attrs) do
    trip
    |> cast(attrs, [:headsign, :identifier, :route_id, :shape_id])
    |> validate_required([:headsign, :identifier, :route_id, :shape_id])
  end
end
