defmodule PantografWeb.TransitLive.MapComponent do
  use PantografWeb, :live_component

  alias MapLibre
  alias Pantograf.MapTiler

  def update(_assigns, socket) do
    socket =
      socket
      |> assign(id: socket.id)

    # stops = Pantograf.Transit.GTFS.stops_to_features(assigns.network.stops)
    # we want to begin with empty stops
    stops = Pantograf.Transit.GTFS.stops_to_features([])
    # shapes = Pantograf.Transit.GTFS.shapes_to_features(assigns.network.shapes)
    shapes = Pantograf.Transit.GTFS.shapes_to_features([])

    ml =
      MapLibre.new(style: MapTiler.default_style(MapTiler.api_key()))
      |> add_stops(stops)
      |> add_shapes(shapes)

    {:ok,
     push_event(socket, "map:#{socket.id}:init", %{
       "ml" => ml |> MapLibre.to_spec(),
       "mode" => "accessibility"
     })}
  end

  def add_shapes(ml, source) do
    ml
    |> MapLibre.add_source(
      "shapes",
      type: :geojson,
      data: source
    )
    |> MapLibre.add_layer(
      id: "shapes",
      source: "shapes",
      type: :line,
      paint: %{
        "line-color" => "#0000ff",
        "line-width" => 1
      }
    )
  end

  def add_stops(ml, source) do
    ml
    |> MapLibre.add_source(
      "stops",
      type: :geojson,
      data: source
    )
    |> MapLibre.add_layer(
      id: "stops",
      source: "stops",
      type: :circle,
      paint: %{
        "circle-radius" => 5,
        "circle-color" => [
          "case",
          ["boolean", ["feature-state", "hover"], false],
          "#0000ff",
          "#000000"
        ]
      }
    )
    |> MapLibre.add_layer(
      id: "stop_labels",
      source: "stops",
      type: :symbol,
      paint: %{
        "text-color": "#000000"
      },
      layout: %{
        "text-field": ["get", "name"],
        "text-size": 12,
        "text-offset": [0, 0.6],
        "text-anchor": "top"
      }
    )
  end
end
