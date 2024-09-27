import maplibregl from "maplibre-gl";


const TransitMap = {
    mounted() {
        let map = null;
        let stops = null;
        this.props = { id: this.el.getAttribute("data-id") };
        this.handleEvent(`map:${this.props.id}:center`, ({ center }) => {
            map.jumpTo({ center: center, zoom: 11 });
        })
        this.handleEvent(`map:${this.props.id}:init`, ({ ml, center }) => {
            const map_params = { container: "map", style: ml, zoom: 14, center: center }
            console.log(ml)

            map = new maplibregl.Map(map_params);

            map.on("load", () => {
                stops = map.getSource('stops')._data;

                console.log(stops)
            });

            map.on("click", (e) => {
                this.pushEvent("calculate_accessibility", { from: e.lngLat }, ({ nearby_stops }) => {
                    console.log(nearby_stops)
                    map.getSource('stops').setData(nearby_stops);
                });
            })
        });
    },
};

export default TransitMap;