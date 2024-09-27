defmodule Pantograf.Transit.Stops do
  def stops_to_features(stops) do
    features =
      Enum.map(stops, fn stop ->
        %{
          "type" => "Feature",
          "geometry" => %{
            "type" => "Point",
            "coordinates" => Tuple.to_list(stop.coordinates.coordinates)
          },
          "properties" => %{
            "name" => stop.name,
            "id" => stop.identifier
          }
        }
      end)

    %{
      "type" => "FeatureCollection",
      "features" => features
    }
  end
end
