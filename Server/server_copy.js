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
/*app.get('/:sql', function (req, res, next) {
  const qr= req.params.sql;
  qr.split('%22').join('"')
  qr.split('%20').join(' ')
*/
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
           //console.log(result);
           res.status(200).send(result.rows);
       });
    });

});



//Download shapefile
const exec = require('child_process').exec;
var path = require('path');
var mime = require('mime');
var fs = require('fs');


app.get('/voronoi/download/:date', function (req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "X-Requested-With");
  //command to delete exsisting shapefile & zip
  var del = 'yes|rm ~/PostRep/Server/export/*'
  const child = exec(del,
      (error, stdout, stderr) => {
          console.log(`stdout: ${stdout}`);
          console.log(`stderr: ${stderr}`);

          if (error !== null) {
              console.log(`exec error: ${error}`);
          }
       var rdate =""+req.params.date

       rdate = rdate.split("+").join(" ");
       //SQL query to create voronoi polygons
       var sql ="SELECT NULL::double PRECISION AS val,               '"+rdate+"'::TIMESTAMP AS date,               (ST_Dump(ST_CollectionExtract(ST_VoronoiPolygons(ST_Collect(DISTINCT geom)) ,3))).geom         FROM proc.in_data        WHERE date = '"+rdate+"';"
       // Command to create shapefile
       var command="pgsql2shp -f "+__dirname+"/export/1 -h localhost -p5432 -u user -g geom rad \""+sql+"\"";
       const child = exec(command,
           (error, stdout, stderr) => {
               console.log(`stdout: ${stdout}`);
               console.log(`stderr: ${stderr}`);

               //command to zip shapefile
               var zip = 'zip '+__dirname+'/export/1.zip '+__dirname+'/export/1.*'
               const child = exec(zip,
                   (error, stdout, stderr) => {
                       console.log(`stdout: ${stdout}`);
                       console.log(`stderr: ${stderr}`);

                       var file = __dirname+'/export/1.zip';

                       var filename = path.basename(file);
                       var mimetype = mime.lookup(file);

                       res.setHeader('Content-disposition', 'attachment; filename=' + filename);
                       res.setHeader('Content-type', mimetype);

                       //download the zip
                       var filestream = fs.createReadStream(file);
                       filestream.pipe(res);



                       if (error !== null) {
                           console.log(`exec error: ${error}`);
                       }
               });

               if (error !== null) {
                   console.log(`exec error: ${error}`);
               }
       });
});
});

app.get('/point/:date', function (req, res, next) {
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
       var sql ="select ST_asgeoJSON(geom) as geometry from proc.in_data where date='"+rdate+"';"

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
