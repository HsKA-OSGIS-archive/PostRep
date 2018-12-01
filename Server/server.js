var express = require('express');
var pg = require("pg");
var app = express();

var connectionString = "postgres://rad:rad@localhost:5432/rad";

app.all('/', function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "X-Requested-With");
  next()
});

app.all('/date', function(req, res, next) {
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
       client.query('SELECT date,ST_ASgeoJSON(geom) as geometry FROM proc.voronoi', function(err,result) {
           done(); // closing the connection;
           if(err){
               console.log(err);
               res.status(400).send(err);
           }
           console.log(result);
           res.status(200).send(result.rows);
       });
    });
});

app.get('/date', function (req, res, next) {

    pg.connect(connectionString,function(err,client,done) {
       if(err){
           console.log("not able to get connection "+ err);
           res.status(400).send(err);
       }
       client.query('SELECT date FROM stg.rad_data group by date;', function(err,result) {
           done(); // closing the connection;
           if(err){
               console.log(err);
               res.status(400).send(err);
           }
           console.log(result);
           res.status(200).send(result.rows);
       });
    });

});

app.get('/voronoi/:date', function (req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "X-Requested-With");

    pg.connect(connectionString,function(err,client,done) {
       if(err){
           console.log("not able to get connection "+ err);
           res.status(400).send(err);
       }
       var rdate =""+req.params.date

       rdate = rdate.split("+").join(" ");
       console.log(rdate);
       var sql ="(SELECT NULL::double PRECISION AS val,               '"+rdate+"'::TIMESTAMP AS date,               ST_ASgeoJSON((ST_Dump(ST_CollectionExtract(ST_VoronoiPolygons(ST_Collect(DISTINCT geom)) ,3))).geom) as geometry         FROM proc.in_data        WHERE date = '"+rdate+"');"

       client.query(sql, function(err,result) {
           done(); // closing the connection;
           if(err){
               console.log(err);
               res.status(400).send(err);
           }
           console.log(result);
           res.status(200).send(result.rows);
       });
    });

});

app.listen(4000, function () {
    console.log('Server is running.. on Port 4000');
});
