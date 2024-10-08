import maplibregl from "maplibre-gl";


const TransitMap = {
    mounted() {
        let map = null;
        let stops = null;
        let routes = []
        this.props = { id: this.el.getAttribute("data-id") };
        this.handleEvent(`map:${this.props.id}:center`, ({ center, routes }) => {
            map.jumpTo({ center: center, zoom: 11 });
            routes = routes;
        })
        this.handleEvent(`map:${this.props.id}:init`, ({ ml, center }) => {
            const map_params = { container: "map", style: ml, zoom: 14, center: center }
            map = new maplibregl.Map(map_params);

            map.on("load", () => {
                stops = map.getSource('stops')._data;

                console.log(stops)
            });

            map.on("click", (e) => {
                this.pushEvent("calculate_accessibility", { from: e.lngLat }, ({ nearby_stops, accessible_shapes }) => {
                    map.getSource('stops').setData(nearby_stops);
                    map.getSource('shapes').setData(accessible_shapes);
                });
            })
        });

        this.handleEvent(`map:highlight_route`, ({ route_id }) => {
            console.log(route_id)
            map.setFilter('shapes', ['in', ["literal", route_id], ["get", "routes"]]);
        });


        this.handleEvent(`map:${this.props.id}:update_accessible_shapes`, ({ accessible_shapes, nearby_stops }) => {
            map.getSource('stops').setData(nearby_stops);
            map.getSource('shapes').setData(accessible_shapes);
        });
    },
};

const RoutesCard = {
    mounted() {
        const badges = this.el.getElementsByClassName("route-badge");
        Array.from(badges).forEach(route => {
            route.addEventListener("mouseover", () => {
                this.pushEvent("highlight_route", { route_id: route.getAttribute("data-route-id") })
            });
        });
    },
    updated() {
        const badges = this.el.getElementsByClassName("route-badge");
        Array.from(badges).forEach(route => {
            route.addEventListener("mouseover", () => {
                this.pushEvent("highlight_route", { route_id: route.getAttribute("data-route-id") })
            });
        });
    }
}

export { TransitMap, RoutesCard };