var mymap=L.map('map').setView([ 51.5, 10],6);
function draw(geom,xxx){
	if(mymap!=null){
		mymap.remove()
		mymap=L.map('map').setView([  51.5, 10],6);
	}
var hoverColor = "white"
var defaultColor = "green"
var opacityColor = 0.6;
if(xxx==1) opacityColor=0.3


	L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token={accessToken}', {
    attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://mapbox.com">Mapbox</a>',
    maxZoom: 18,
    id: 'mapbox.streets',
    accessToken: 'pk.eyJ1IjoiYWdhZ2VsZGkiLCJhIjoiY2phbm5pcTRhM2ZpNDJxcnphbnk4bXhiaSJ9.4EoCP0AuZHTMY8pA0VO8Ew'
}).addTo(mymap);


var voronoiStyle ={
  		fillColor : defaultColor,
  		weight: 1,
      color: "white",
  		opacity: 1,
  		fillOpacity: opacityColor
  		};

function highlightFeature(e) {
    var layer = e.target;
    layer.setStyle({
        				fillColor: hoverColor,
        				weight: 2,
        				opacity: 1,
        				color: "white",
        				dashArray: '',
        				fillOpacity: opacityColor
        			});

   //if (!L.Browser.ie && !L.Browser.opera && !L.Browser.edge)        			layer.bringToFront();
}

function resetHighlight(e) {
    var layer = e.target;
    layer.setStyle({
        				fillColor: defaultColor,
        				weight: 1,
        				opacity: 1,
        				color: "white",
        				dashArray: '',
        				fillOpacity: opacityColor
        			});
   //if (!L.Browser.ie && !L.Browser.opera && !L.Browser.edge)        			layer.bringToFront();
}

function onEachFeature(feature,layer){
      	layer.on({
      		mouseover: highlightFeature,
      		mouseout: resetHighlight,
      	});
      }



  for(var i=0;i<geom.length;i++){
    var geometry= JSON.parse(geom[i].geometry)
      var pol={"type": "Feature",
      "properties": {"type": "ocean"},
      geometry}
    var Lvor = L.geoJSON(pol, {style: voronoiStyle, onEachFeature:onEachFeature })
		if(xxx==0)
	    Lvor.bindPopup(""+geom[i].val);
	    Lvor.addTo(mymap)

  }
}

function draw_point(geom){
	for(var i=0;i<geom.length;i++){
		var geo= JSON.parse(geom[i].geometry)
		geo =geo.coordinates
		var circle = L.circle([geo[1],geo[0]], {
	    color: '#333',
	    fillColor: '#333',
	    fillOpacity: 1,
	    radius: 25
		}).addTo(mymap);
	}
}
