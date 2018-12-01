var mymap=L.map('map').setView([ 48.79228, 9],6);
function draw(geom){
	if(mymap!=null){
		mymap.remove()
		mymap=L.map('map').setView([ 48.79228, 9],6);
	}
var hoverColor = "white"
var defaultColor = "green"
var opacityColor = 0.6;


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
  		fillOpacity: 0.6
  		};

function highlightFeature(e) {
    var layer = e.target;
    layer.setStyle({
        				fillColor: hoverColor,
        				weight: 2,
        				opacity: 1,
        				color: "black",
        				dashArray: '',
        				fillOpacity: opacityColor
        			});

   if (!L.Browser.ie && !L.Browser.opera && !L.Browser.edge)        			layer.bringToFront();
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
   if (!L.Browser.ie && !L.Browser.opera && !L.Browser.edge)        			layer.bringToFront();
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
    Lvor.bindPopup(geom[i].date);
    Lvor.addTo(mymap)
  }
}



var xhttp = new XMLHttpRequest();
var url = "http://localhost:4000";
var respond;
xhttp.onreadystatechange = function() {
  if (this.readyState == 4 && this.status == 200) {
    //console.log(xhttp.responseText);
    respond = JSON.parse(xhttp.responseText);
     // Action to be performed when the document is read;

    draw(respond);
  }
};
xhttp.open("GET", url, true);
xhttp.setRequestHeader('Content-Type', 'text/plain');

xhttp.send();
