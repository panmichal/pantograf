defmodule Pantograf.Transit.RouteType do
  use Pantograf.Schema
  import Ecto.Changeset

  schema "transit_route_types" do
    field :identifier, :string
    field :name, :string

    belongs_to :network, Pantograf.Transit.Network

    timestamps(inserted_at: :created_at, updated_at: :updated_at)
  end

  def changeset(route_type, attrs) do
    route_type
    |> cast(attrs, [:name, :identifier, :network_id])
    |> validate_required([:name, :identifier])
  end
end
