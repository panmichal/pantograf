defmodule PantografWeb.TransitLive.Index do
  use PantografWeb, :live_view

  alias Pantograf.Geocode

  def mount(%{"location" => location}, _session, socket) do
    center = %{lat: 37.7749, lng: -122.4194}

    network =
      Pantograf.Transit.get_network_by_location(location, [:stops, [shapes: :routes], :routes])

    socket =
      socket
      |> assign(:center, center)
      |> assign(:network, network)
      |> assign(:accessible_routes, [])
      |> start_async(:geocode, fn -> Geocode.forward_geocode("wroclaw") end)

    {:ok, socket, layout: false}
  end

  def handle_async(:geocode, {:ok, {:ok, %{"lat" => lat, "lon" => lon}}}, socket) do
    {:noreply,
     push_event(socket, "map:#{socket.id}:center", %{
       "center" => [lon, lat]
     })}
  end

  def handle_event("calculate_accessibility", value, socket) do
    nearby_stops =
      Pantograf.Transit.get_nearby_stops(
        value["from"]["lat"],
        value["from"]["lng"],
        300,
        socket.assigns.network
      )

    accessible_shapes = Pantograf.Transit.get_shapes_for_stops(nearby_stops)
    accessible_routes = Pantograf.Transit.get_routes_for_shapes(accessible_shapes)

    {:reply,
     %{
       accessible_shapes: Pantograf.Transit.GTFS.shapes_to_features(accessible_shapes),
       nearby_stops: Pantograf.Transit.GTFS.stops_to_features(nearby_stops)
     }, assign(socket, :accessible_routes, accessible_routes)}
  end
end
