CREATE ROLE rad LOGIN ENCRYPTED PASSWORD 'md5612abdce80cf2090a4bd8425c1bff79e'
	SUPERUSER CREATEDB CREATEROLE REPLICATION
	VALID UNTIL 'infinity';

CREATE DATABASE rad
  WITH ENCODING='UTF8'
       OWNER=rad
       CONNECTION LIMIT=-1;


CREATE extension postgis;


CREATE SCHEMA stg;


CREATE TABLE stg.rad_data (
    id integer,
    place text,
    x text,
    y text,
    z text,
    date text,
    val text
);

-- \copy stg.rad_data from '/media/sf_e/vm_exchange/data.csv' delimiter ',' csv header


/*
SELECT *
FROM stg.rad_data LIMIT 10;
*/

CREATE SCHEMA proc;


CREATE TABLE proc.in_data AS
  ( SELECT id,
           place,
           z::double PRECISION AS height,
           date::TIMESTAMP,
           val::double PRECISION,
           ST_SetSRID(ST_MakePoint(x::double PRECISION, y::double PRECISION), 4326)::geometry(point, 4326) AS geom,
           ST_SetSRID(ST_MakePoint(x::double PRECISION, y::double PRECISION, z::double PRECISION), 4326)::geometry(pointz, 4326) AS geom_height
   FROM stg.rad_data );


ALTER TABLE proc.in_data ADD PRIMARY KEY (id);


CREATE INDEX ON proc.in_data USING gist(geom);


CREATE INDEX ON proc.in_data USING gist(geom_height);



CREATE TABLE proc.voronoi as (
SELECT (ST_Dump(
            ST_CollectionExtract(
                ST_VoronoiPolygons(
                    ST_Collect(DISTINCT geom)
                    )
                ,3)
            )).geom
FROM proc.in_data);


SELECT (ST_Dump(
            ST_CollectionExtract(
                ST_DelaunayTriangles(
                    ST_Collect(DISTINCT geom)
                    )
                ,3)
            )).geom
FROM proc.in_data;


DROP TABLE IF EXISTS proc.voronoi;


CREATE TABLE proc.voronoi AS
  (SELECT NULL::double PRECISION AS val,
          '2015-10-12 21:50:00'::TIMESTAMP AS date,
          (ST_Dump(ST_CollectionExtract(ST_VoronoiPolygons(ST_Collect(DISTINCT geom)) ,3))).geom
   FROM proc.in_data
   WHERE date = '2015-10-12 21:50:00');


CREATE INDEX ON proc.voronoi USING gist(geom);


UPDATE proc.voronoi AS a
SET val = b.val
FROM proc.in_data AS b
WHERE st_intersects(a.geom, b.geom)
  AND b.date = '2015-10-12 21:50:00';




CREATE TABLE proc.delaunay AS
  (SELECT NULL::double PRECISION AS val,
          '2015-10-12 21:50:00'::TIMESTAMP AS date,
          (ST_Dump(ST_CollectionExtract(ST_DelaunayTriangles(ST_Collect(DISTINCT geom)) ,3))).geom::geometry(polygon,4326)
   FROM proc.in_data
   WHERE date = '2015-10-12 21:50:00');


CREATE INDEX ON proc.delaunay USING gist(geom);

UPDATE proc.delaunay AS a
SET val = b.val
FROM proc.in_data AS b
WHERE st_intersects(a.geom, b.geom)
  AND b.date = '2015-10-12 21:50:00';
