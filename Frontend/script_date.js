
function date(array){
		var list = document.getElementById("date")
		list.innerHTML=""

		for(var i=0;i<array.length;i++){
			var d= array[i].date;
			list.innerHTML = list.innerHTML + '<option value="'+d+'">'+d+'</option>'
		}

}

var xhttp2 = new XMLHttpRequest();
var url = "http://localhost:4000/date";
var respond_date;
xhttp2.onreadystatechange = function() {
  if (this.readyState == 4 && this.status == 200) {
    //console.log("I am date respond"+xhttp2.responseText);
    respond_date = JSON.parse(xhttp2.responseText);
     // Action to be performed when the document is read;

    date(respond_date);
  }
};
xhttp2.open("GET", url, true);
xhttp2.setRequestHeader('Content-Type', 'text/plain');

xhttp2.send();

function getVoronoi(){
	var str = document.getElementById("date").selectedOptions[0].innerHTML
	str = str.split(" ").join("+")
	var xhttp3 = new XMLHttpRequest();
	var url = "http://localhost:4000/voronoi/"+str;
	var respond_date2;
	xhttp3.onreadystatechange = function() {
	  if (this.readyState == 4 && this.status == 200) {
	    console.log("I am date respond"+xhttp3.responseText);
	    respond_date2 = JSON.parse(xhttp3.responseText);
	     // Action to be performed when the document is read;
	    draw(respond_date2);
	  }
	};
	xhttp3.open("GET", url, true);
	xhttp3.setRequestHeader('Content-Type', 'text/plain');

	xhttp3.send();
}
