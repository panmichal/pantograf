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
      |> assign(:accessible_routes, %{})
      |> assign(:radius, 300)
      |> start_async(:geocode, fn -> Geocode.forward_geocode("wroclaw") end)

    {:ok, socket, layout: false}
  end

  def handle_async(:geocode, {:ok, {:ok, %{"lat" => lat, "lon" => lon}}}, socket) do
    {:noreply,
     push_event(socket, "map:#{socket.id}:center", %{
       "center" => [lon, lat]
     })}
  end

  def handle_event("update_settings", %{"radius" => radius}, socket) do
    {:noreply, assign(socket, :radius, radius)}
  end

  def handle_event("calculate_accessibility", value, socket) do
    nearby_stops =
      Pantograf.Transit.get_nearby_stops(
        value["from"]["lat"],
        value["from"]["lng"],
        socket.assigns.radius,
        socket.assigns.network
      )

    accessible_shapes = Pantograf.Transit.get_shapes_for_stops(nearby_stops)

    accessible_routes =
      accessible_shapes
      |> Pantograf.Transit.get_routes_for_shapes()
      |> Pantograf.Transit.group_routes()

    {:reply,
     %{
       accessible_shapes: Pantograf.Transit.GTFS.shapes_to_features(accessible_shapes),
       nearby_stops: Pantograf.Transit.GTFS.stops_to_features(nearby_stops)
     }, assign(socket, :accessible_routes, accessible_routes)}
  end
end
