# PostRep

# PostMaster

Repository for the fictional company PostMaster created within OSGIS classes during the winter semester at HsKA. This project focuses on developing and optimizing server-side spatial analysis of radiological data using PostGIS. In particular, the optimized functionality for deriving voronoi and TIN polygons using sample radiological data has been created, using PostGIS.

## Getting Started
### Setting up the environment

To ensure similar workflow on all machines, please install OSGeoLive in your VirtualMachine in Linux Ubuntu environment (unless Ubuntu is your default OS). You can download VM here https://www.virtualbox.org/wiki/Downloads and OSGeoLive here https://live.osgeo.org/en/download.html. Once up and running, update and upgrade the packages using following commands in the command line.

### Setting up the database

It is advised to set up the database in GUI of PostGIS, however, you might use the enclosed SQL code in the shell, provided you enabled the postgis extension by 

--$ psql CREATE extension postgis;

## Pre-processing

### Importing the data and creating first tables

In this project after setting up the database two schemas are created (staging and processing).The stg schema (standing for staging) is created to have separate schema for original data. In this schema an empty table which is called as stg.rad_data is created to store the values of the original data. The following SQL commands show the created stg schema and stg.rad_data : 

                 CREATE SCHEMA stg;
                 CREATE TABLE stg.rad_data (
	                            id integer,
	                            place text,
	                            x text,
	                            y text,
	                            z text,
	                            date text,
	                            time text,
	                            val text
                );

After creating the stg schema and stg.rad_data table,the original data should be imported to this table. The data is stored in the ‘/home/user/PostRep/input/data.csv’ path as a csv file. For importing the data to the table a terminal shell in OSGEO LIVE is used to connect to the database. The following commands change the path (if your data is stored somewhere else) and connect to the database and import the data to the stg.rad_data : 

- Change directory to the repository directory : cd PostRep/ 
- Connecting to the rad database via terminal : psql -d rad
- Importing the data to the stg.rad_data table : \copy stg.rad_data from '/home/user/PostRep/input/data.csv' delimiter ',' csv header

Since the data is stored in the ‘/home/user/PostRep/input/data.csv’ path,it might be necessary to alter the path in importing the data to the table as above. 

For the formatting the data in a proper way, an additional new column probe_time is created in the stg.rad_data to integrate the two columns of date and time in the one column by separating them with a space delimiter. The following SQL commands show the procedure of formatting the data : 


	ALTER TABLE stg.rad_data ADD probe_time timestamp without time zone;

	UPDATE stg.rad_data SET probe_time = (date|| ' ' || time)::timestamp without time zone;

	ALTER TABLE stg.rad_data
	DROP COLUMN time;
	ALTER TABLE stg.rad_data
	DROP COLUMN date;

it is also needed to also add geometry column for each records. With having geometry column for each station, the stations can be represented as points in POSTGIS. The geometry is also needed to assign to a SRID ( Spatial Reference ID ) which in this project is 4326. The following SQL statements show creating the geometry and assigning SRID = 4326 to each station : 

	 ALTER TABLE stg.rad_data

         ADD COLUMN geom geometry(point, 4326), 
	 
         ADD COLUMN geom_3d geometry(pointz, 4326);

	UPDATE stg.rad_data
	SET geom = ST_SetSRID(ST_MakePoint(x::numeric, y::numeric), 4326),
		geom_3d = ST_SetSRID(ST_MakePoint(x::numeric, y::numeric, z::numeric), 4326);

As it is mentioned before there is also a processing schema which will handle the process of creating and clipping voronoi and tins. All the tables related to the voronoi and TIN will be created in this schema which is called proc.The SQL statement for creating the proc schema is : 

	CREATE SCHEMA proc;

Since the data is for whole Germany and the final clipped voronoi and tins will be shown only for German boundary, it is also essential to import the germany shapefile. This is done again via OSGEO LIVE terminal as the following command : 

	shp2pgsql -I -d -s 4326 /home/user/PostRep/input/germany.shp proc.germany | psql -d rad
                                      
## Creating relational tables 
The relational tables are a set of data elements (values) using a model of vertical columns (identifiable by name) and horizontal rows. the values which are used must be assigned to these tables. It is very important to increase the processing speed of the queries. 
Two relational tables should be created using SQL query statements in the following steps:

Create the first table “proc.station_info” which holds the stations' information. The table has four columns (attributes):
ID which is integer data type and primary key (unique value) 
Place is the name of the station which is a Text data type. 
Station location coordinates (X, Y). It is a point geometry column defined by EPSG:4326. 
Station (Z) coordinate. it is a point geometry column defined by EPSG:4326. 

	 CREATE TABLE proc.station_info (
	    id int primary key,
	    place text,
	    geom geometry(Point, 4326),
	    geom_3d geometry(PointZ, 4326)
	    );
    
Create the second table “proc.records_info” which holds the station records the table has five columns (attributes):
ID which is integer data type and primary key (unique value) 
Station_id which is a foreign primary key that refers to the station id in the first table.   
Place is the name of the station which is a text data type. 
Probe_time holds the time of the records with a timestamp data type. 
Value  which holds the records.

	 CREATE TABLE proc.records_info (
	  id int primary key,
	  station_id int references proc.station_info(id,
	  place text,
	  probe_time timestamp,
	  value real,
	  ); 

The third step is to insert the values of each table from the first create table “rad_data”. The values are inserted to  “proc.station_info”  table and “proc.records_info” table using the select and insert. The SQL statement row_number() over() is used to add the row number column in front of each column. To avoid duplicate values The SQL SELECT DISTINCT Statement. also Alias can be used to give short names of tables and columns. 

	INSERT INTO proc.station_info (id, place, geom, geom_3d) (
	SELECT row_number() over() AS id

	INSERT INTO proc.records_info (id, place, probe_time, value, station_id)

The LEFT JOIN keyword returns all records from the left table proc.records_info”, and the matched records from the right table “proc.station_info”.

	LEFT JOIN proc.station_info AS b ON a.place = b.place

The CREATE INDEX statement is used to create indexes in  “proc.station_info”. this gives the ability to retrieve data from the database very fast. Index for (X, Y) geometry and (Z) geometry.   

	CREATE INDEX ON proc.station_info  USING gist(geom);
	CREATE INDEX ON proc.station_info  USING gist(geom_3d);

Every time overall workflow process run the two tables must be dropped and recreated again. 

	DROP TABLE IF EXISTS proc.station_info;
	DROP TABLE IF EXISTS proc.records_info;

## Creating voronoi and TIN tables

As it has been explained before, the schema ‘proc’ and relational tables has been created. Now, it is possible to operate with this information. The process starts creating temporary table called ‘voronoi’ using a geometry from the table ‘station_info’. The temporary tables are created in temporary database. It works like in regular tables, where it is possible to query their data via SELECT queries and modify their data via UPDATE, INSERT, and DELETE statements so on.
In order to obtain correctly Voronoi polygons, different functions have been used in following steps:
The SELECT DISTINCT statement is used to return only distinct (different) values, in this case is the geometry.
ST_Collect function returns a GEOMETRYCOLLECTION to operate on rows of data. It simply combines all the points into a MultiPoint, without performing any spatial operations.
ST_VoronoiPolygons computes a two-dimensional Voronoi diagram from the vertices of the supplied geometry. The result is a GeometryCollection of Polygons that covers an envelope larger than the extent of the input vertices.
Given a multigeometry, ST_CollectionExtract function returns a multigeometry consisting only the elements of the specified type, in this case is POLYGON.
ST_Dump return a record for each of the collection components (polygons) with its position.
Once the Voronoi polygons has been obtain, the index is added.
Some Voronoi cells of their Voronoi diagram are infinite or outside of the boundary of Germany, only the parts inside of it are needed. Therefore, they have to be clipped. To save a new Voronoi polygons already clipped, the new table is created ‘voronoi_clip’.
To properly clip polygons, following cases must be taken into account to select the data:
- The obtained Voronoi polygons that intersect with the German boundary have to be clipped. (CASE WHEN ST_Overlaps(a.geom, b.geom) THEN ST_Intersection(a.geom, b.geom)
- There are three points outside of the of the German boundary. The obtained Voronoi polygons do not have to be taken in account. And for the points inside of the German boundary, the obtained Voronoi polygons has to be added to the final table (WHEN ST_Within(a.geom, b.geom) THEN a.geom)



Note: the alias ‘a’ is for the table ‘record_info’ (timestamp, place, measurements) and the alias ‘b’ is for ‘station_info’ table (id, place, geometry)
After all process, in order to fill a resulting table, the spatial join is done. This is can be realized only if a geometry shares any portion of space then they intersect with the boundary (ST_Intersects). The spatial join is a common use case in spatial databases, putting together two tables based on the spatial relationships of their geometry fields. Finally,it is ordered by id.

## Frontend extension

### Setting up the Frontend
Installation of the required library
To run backend server nodejs library was used. Therefore to start backend nodejs library should be installed on the machine. Here is how to do it:
Go into PostRep/Server/ 
- Install nodejs library via terminal shell

	sudo apt-get update	
	
	sudo apt-get install nodejs
	
- Install nodejs package manager

	sudo apt install npm
	
- Initiate nodejs package manager

	npm init 
	

- Install nodejs express and pg (version 6.4.2) libraries

	npm install express pg@6.4.2 --save

### Starting backend server
After installing nodejs library and it’s extensions, following command in the command line and in PostRep/Server/ directory should start server:
	nodejs server.js
	
Now you can start frontend application on the same machine, because by default setting was set for localhost. Incase you want to make it online then you will need to change connection string tin the frontend application.

### Application
#### Concept
In the Project, to create easy and multi-access to the backend an appropriate frontend application was also considered. By keeping in mind the broad libraries and features of contemporary web development techniques, the frontend application was also built base of the web application. The main essence of the frontend is spatial representation of the input Radiological data. To achieve this result with minimum complication Leaflet javascript library was used. OpenStreetMap was used as a basemap. To be able to select and download the data, on the left side of the page small panel was placed. On which one can select date and by clicking “get” buttons retrieve corresponding values and geometry for this specific timestamp. By sticking our main concept of the project two possibilities of data request was created (Voronoi and TIN). As it already was mentioned almost all preparation of the data was done on the backend and only depiction of the data will be the task of the frontend application. Each time, when client makes data request, http requests, to get Points and Polygons with values, will automatically take place on the background. In case of requesting TIN polygons won’t have assigned values because unlikely from Voronoi polygons in TIN it is not possible to make concrete concept for calculation of value for each polygon. HTTP requests will communicate with server which was built on backend with nodejs library, and received response from server will be drawn on the map by mean of the two functions (drawPoint() to draw points and draw() to draw polygons). In case if client requests download the shapefiles then correspond request will be prepared on the frontend and will be sent to the server. Where server will respond back filestream with attached zipped shapefile. In case of the Voronoi polygons values of the drawn polygons can be seen by clicking the on it, value will be popped up.

#### Outlook

Frontend web application was built in PostRep Project, which’s main focus fell of the backend data preparation,  in frame of the OSGIS class. Therefore relative less time investment for the development of the frontend was done and not the all features, which could be done, were implemented. Following features could be implemented to improve current state of the frontend web application:
1. When user requests to get new timestamp value, functions which are drawing the geometry on the leaflet window, are deleting the existing map view and recreating all map view again. Which causes need of reloading basemap once again. Instead of doing that one may improve functions so that they will only update geometry. In ideal case it would be smart to update only popup values of the geometries. Reason why this of this issue is initial concept of the project. Which was also changed and improved during the development of the project.
2. In nodejs server, requests to the database is done by mean of the function which is predefined in the database already. This was done to make nodejs and database communication more robust and capsulated. Unfortunately, using this functions is returning more attributes than required to draw only geometries because functions intentions was for both downloading shapefile and drawing geometries. Even though this issue is causing some redundancies, this redundancy could be used to for other features of the frontend web application.







