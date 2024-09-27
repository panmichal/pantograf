defmodule Pantograf.Transit.Stop do
  use Pantograf.Schema
  import Ecto.Changeset

  schema "transit_stops" do
    field :name, :string
    field :code, :string
    field :identifier, :string
    field :coordinates, Geo.PostGIS.Geometry

    belongs_to :network, Pantograf.Transit.Network
    has_many :stop_times, Pantograf.Transit.StopTime
    has_many :trips, through: [:stop_times, :trip]

    timestamps(inserted_at: :created_at, updated_at: :updated_at)
  end

  def changeset(stop, attrs) do
    stop
    |> cast(attrs, [:name, :code, :identifier, :coordinates, :network_id])
    |> validate_required([:name, :code, :identifier, :coordinates])
  end
end
