var express = require('express');
var pg = require("pg");
var app = express();

var connectionString = "postgres://user:user@localhost:5432/saag_geo";

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
       client.query('SELECT * FROM roads', function(err,result) {
           done(); // closing the connection;
           if(err){
               console.log(err);
               res.status(400).send(err);
           }
           res.status(200).send(result.rows[1]);
       });
    });
});
app.get('/b', function (req, res, next) {
    pg.connect(connectionString,function(err,client,done) {
       if(err){
           console.log("not able to get connection "+ err);
           res.status(400).send(err);
       }
       client.query('SELECT ST_ASTEXT(geom) as Coordinates FROM roads', function(err,result) {
           done(); // closing the connection;
           if(err){
               console.log(err);
               res.status(400).send(err);
           }
           res.status(200).send(result.rows[1]);
       });
    });
});

app.get('/a', function (req, res, next) {
    pg.connect(connectionString,function(err,client,done) {
       if(err){
           console.log("not able to get connection "+ err);
           res.status(400).send(err);
       }
       client.query('SELECT *,ST_ASTEXT(geom) as Coordinates FROM places', function(err,result) {
           done(); // closing the connection;
           if(err){
               console.log(err);
               res.status(400).send(err);
           }
           console.log(result);
           res.status(200).send(result.rows[0]);
       });
    });
});


app.listen(4000, function () {
    console.log('Server is running.. on Port 4000');
});
