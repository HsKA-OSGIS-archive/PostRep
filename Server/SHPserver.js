var express = require('express');
var pg = require("pg");
var app = express();

var connectionString = "postgres://rad:rad@localhost:5432/rad";

const exec = require('child_process').exec;
var command="pgsql2shp -f /home/user/PostRep/Server/export/1 -h localhost -p5432 -u user -g geom rad 'select date, geom from proc.in_data'";
const child = exec(command,
    (error, stdout, stderr) => {
        console.log(`stdout: ${stdout}`);
        console.log(`stderr: ${stderr}`);
        var zip = 'zip ~/PostRep/Server/export/1.zip ~/PostRep/Server/export/1.*'
        const child = exec(zip,
            (error, stdout, stderr) => {
                console.log(`stdout: ${stdout}`);
                console.log(`stderr: ${stderr}`);

                if (error !== null) {
                    console.log(`exec error: ${error}`);
                }
        });

        if (error !== null) {
            console.log(`exec error: ${error}`);
        }
});

var path = require('path');
var mime = require('mime');
var fs = require('fs');

app.get('/download', function(req, res){

  var file = __dirname+'/export/1.zip';

  var filename = path.basename(file);
  var mimetype = mime.lookup(file);

  res.setHeader('Content-disposition', 'attachment; filename=' + filename);
  res.setHeader('Content-type', mimetype);

  var filestream = fs.createReadStream(file);
  filestream.pipe(res);
});



app.all('/', function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "X-Requested-With");
  next()
});


app.listen(4000, function () {
    console.log('Server is running.. on Port 4000');
});
