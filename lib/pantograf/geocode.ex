defmodule Pantograf.Geocode do
  @reverse_geocode_url "https://nominatim.openstreetmap.org/reverse"
  @forward_geocode_url "https://nominatim.openstreetmap.org/search"
  def forward_geocode(address) do
    query = %{
      q: address,
      format: "jsonv2",
      "accept-language": "en-US"
    }

    uri =
      @forward_geocode_url
      |> URI.parse()
      |> URI.append_query(URI.encode_query(query))
      |> URI.to_string()

    case Req.get(uri) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        if length(body) > 0 do
          [%{"lat" => lat, "lon" => lon} | _] = body
          {:ok, %{"lat" => lat, "lon" => lon}}
        else
          {:error, "Could not geocode"}
        end
    end
  end

  def reverse_geocode(lat, long) do
    query = %{
      lat: lat,
      lon: long,
      format: "json",
      "accept-language": "en-US"
    }

    uri =
      @reverse_geocode_url
      |> URI.parse()
      |> URI.append_query(URI.encode_query(query))
      |> URI.to_string()

    case Req.get(uri) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, %{"address" => body["address"]}}

      {:error, _} ->
        {:error, "Could not reverse geocode"}
    end
  end
end
