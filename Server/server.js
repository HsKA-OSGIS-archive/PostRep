var express = require('express');
var pg = require("pg");
var app = express();

var connectionString = "postgres://rad:rad@localhost:5432/rad";

app.all('/', function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "X-Requested-With");
  next()
});

app.get('/', function (req, res, next) {
    pg.connect(connectionString,function(err,client,done) {
       if(err){
           console.log("not able to get connection "+ err);
           res.status(400).send(err);
       }
       client.query('SELECT * FROM proc.VORONOI', function(err,result) {
           done(); // closing the connection;
           if(err){
               console.log(err);
               res.status(400).send(err);
           }
           res.status(200).send(result.rows[1]);
       });
    });
});
app.get('/:sql', function (req, res, next) {
  const qr= req.params.sql;
  qr.split('%22').join('"')
  qr.split('%20').join(' ')

    pg.connect(connectionString,function(err,client,done) {
       if(err){
           console.log("not able to get connection "+ err);
           res.status(400).send(err);
       }
       client.query("SELECT ST_geoJSON(geom) FROM proc.VORONOI WHERE date = '"+qr+"';", function(err,result) {
           done(); // closing the connection;
           if(err){
               console.log(err);
               res.status(400).send(err);
           }
           res.status(200).send(result.rows[1]);
       });
    });
});



app.listen(4000, function () {
    console.log('Server is running.. on Port 4000');
});
