var express = require('express');
var pg = require("pg");
var app = express();

var connectionString = "postgres://fremdseinDBuser:Fr3mds1@IMM-GISDB.hs-karlsruhe.de:5432/fremdsein";

app.all('/', function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "X-Requested-With");
  next()
});

app.get('/create', function (req, res, next) {
    pg.connect(connectionString,function(err,client,done) {
       if(err){
           console.log("not able to get connection "+ err);
           res.status(400).send(err);
       }
       var sql='CREATE TABLE if not exists QuizApp(id SERIAL PRIMARY KEY, home TEXT, powerdistance INTEGER, individualism INTEGER, musculinity INTEGER, uncertainityAvoidance INTEGER, longtermOrientation INTEGER, indulgence INTEGER, w1 INTEGER, w2 INTEGER, w3 INTEGER, w4 INTEGER, w5 INTEGER, w6 INTEGER, comment TEXT, aliasName TEXT,imageName TEXT)'
       client.query(sql, function(err,result) {
           done(); // closing the connection;
           if(err){
               console.log(err);
               res.status(400).send(err);
           }
           res.status(200).send(result.rows[1]);
       });
    });
});
app.get('/list', function (req, res, next) {
    pg.connect(connectionString,function(err,client,done) {
       if(err){
           console.log("not able to get connection "+ err);
           res.status(400).send(err);
       }
       client.query('SELECT table_name FROM information_schema.tables', function(err,result) {
           done(); // closing the connection;
           if(err){
               console.log(err);
               res.status(400).send(err);
           }
           res.status(200).send(result.rows[1]);
       });
    });


});
app.get('/select/:id', function (req, res, next) {

  const id= req.params.id;

    pg.connect(connectionString,function(err,client,done) {
       if(err){
           console.log("not able to get connection "+ err);
           res.status(400).send(err);
       }
       var sql= 'SELECT * FROM QuizApp Where id=' +id
       client.query(sql, function(err,result) {
           done(); // closing the connection;
           if(err){
               console.log(err);
               res.status(400).send(err);
           }
           res.status(200).send(result.rows[0]);
       });
    });
});
app.get('/save/:sql', function (req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "X-Requested-With");
  next()

  const qr= req.params.sql;
  qr.split('%22').join('"')
  qr.split('%20').join(' ')
    pg.connect(connectionString,function(err,client,done) {
       if(err){
           console.log("not able to get connection "+ err);
           res.status(400).send(err);
       }
       var sql = 'INSERT INTO QuizApp(home, powerdistance, 	individualism, 		musculinity,	uncertainityAvoidance,	longtermOrientation, indulgence,'+
   									'w1,w2,w3,w4,w5,w6, comment,imageName,aliasName) '
       sql += qr
       client.query(sql, function(err,result) {
           done(); // closing the connection;
           if(err){
               console.log(err);
               res.status(400).send(err);
           }
           res.status(200).send(result.rows[0]);
       });
    });
});

app.get('/insert1', function (req, res, next) {
    pg.connect(connectionString,function(err,client,done) {
       if(err){
           res.status(400).send(err);
           console.log("not able to get connection "+ err);
       }
       var sql= "INSERT INTO QuizApp(home) VALUES('TURKMENISTAN');"
       client.query(sql, function(err,result) {
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
app.get('/insert2', function (req, res, next) {
    pg.connect(connectionString,function(err,client,done) {
       if(err){
           res.status(400).send(err);
           console.log("not able to get connection "+ err);
       }
       var sql= "INSERT INTO QuizApp(home) VALUES('GERMANY');"
       client.query(sql, function(err,result) {
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
