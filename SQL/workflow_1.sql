CREATE SCHEMA stg;


-- #############################################################################
-- Importing and formatting data
-- #############################################################################


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


\copy stg.rad_data from '/home/user/PostRep/data.csv' delimiter ',' csv header


ALTER TABLE stg.rad_data ADD probe_time timestamp without time zone;


UPDATE stg.rad_data SET probe_time = (date|| ' ' || time)::timestamp without time zone;


ALTER TABLE stg.rad_data
DROP COLUMN time;


ALTER TABLE stg.rad_data
DROP COLUMN date;


ALTER TABLE stg.rad_data
    ADD COLUMN geom geometry(point, 4326),
    ADD COLUMN geom_3d geometry(pointz, 4326);


UPDATE stg.rad_data
SET geom = ST_SetSRID(ST_MakePoint(x::numeric, y::numeric), 4326),
    geom_3d = ST_SetSRID(ST_MakePoint(x::numeric, y::numeric, z::numeric), 4326);


CREATE SCHEMA proc;


-- #############################################################################
-- CREATE relational tables in processing schema
-- #############################################################################


DROP TABLE IF EXISTS proc.station_info;


CREATE TABLE proc.station_info (
    id int primary key,
    place text,
    geom geometry(Point, 4326),
    geom_3d geometry(PointZ, 4326)
    );


DROP TABLE IF EXISTS proc.records_info;


CREATE TABLE proc.records_info (
    id int primary key ,
    station_id int references proc.station_info(id),
    place text,
    probe_time timestamp,
    value real
    );


INSERT INTO proc.station_info (id, place, geom, geom_3d) (
    SELECT row_number() over() AS id,
           foo.*
    FROM
      (SELECT DISTINCT ON (place, geom)
            place,
            geom,
            geom_3d
       FROM stg.rad_data) AS foo);


INSERT INTO proc.records_info (id, place, probe_time, value, station_id)
  ( SELECT a.id,
           a.place,
           a.probe_time,
           a.val::real,
           b.id
   FROM stg.rad_data AS a
   LEFT JOIN proc.station_info AS b ON a.place = b.place
   AND a.geom = b.geom);


CREATE INDEX ON proc.station_info  USING gist(geom);

CREATE INDEX ON proc.station_info  USING gist(geom_3d);

-- #############################################################################
-- IMPORT GERMANY DATA
-- #############################################################################

shp2pgsql -I -d -s 4326 /home/user/PostRep/germany.shp proc.germany | psql -d rad



-- #############################################################################
-- CREATING AND CLIPPING VORONOI
-- #############################################################################



CREATE TEMPORARY TABLE voronoi AS (
SELECT  (
			ST_Dump(ST_CollectionExtract(ST_VoronoiPolygons(ST_Collect(DISTINCT geom)) ,3))).geom
		FROM proc.station_info);



CREATE INDEX ON voronoi  USING gist(geom);



CREATE TABLE proc.voronoi_clip as (
SELECT inData.id AS id,
		myVoronoi.geom as geom
	FROM (

                        SELECT (ST_Dump(geom)).geom::geometry(POLYGON, 4326)
                        FROM (
                            SELECT
                                CASE
                                    WHEN ST_Overlaps(a.geom, b.geom) THEN ST_Intersection(a.geom, b.geom)
                                    WHEN ST_Within(a.geom, b.geom) THEN a.geom
                                    ELSE NULL
                                END as geom
                            FROM voronoi as a
                            LEFT JOIN proc.germany AS b on ST_Intersects(a.geom, b.geom)
                            ) AS foo
                        )AS myVoronoi,
			proc.station_info AS inData
	WHERE ST_intersects(inData.geom,myVoronoi.geom)
	ORDER BY id);


-- #############################################################################
-- CREATING AND CLIPPING TIN
-- #############################################################################

CREATE TEMPORARY TABLE tin AS (
SELECT  (
			ST_Dump(ST_CollectionExtract( ST_DelaunayTriangles(ST_Collect(DISTINCT geom)) ,3))).geom
		FROM proc.station_info);



CREATE INDEX ON tin  USING gist(geom);



CREATE TABLE proc.tin_clip as (
SELECT inData.id AS id,
		myTin.geom as geom
	FROM (

                        SELECT (ST_Dump(geom)).geom::geometry(POLYGON, 4326)
                        FROM (
                            SELECT
                                CASE
                                    WHEN ST_Overlaps(a.geom, b.geom) THEN ST_Intersection(a.geom, b.geom)
                                    WHEN ST_Within(a.geom, b.geom) THEN a.geom
                                    ELSE NULL
                                END as geom
                            FROM tin as a
                            LEFT JOIN proc.germany AS b on ST_Intersects(a.geom, b.geom)
                            ) AS foo
                        )AS myTin,
			proc.station_info AS inData
	WHERE ST_intersects(inData.geom,myTin.geom)
	ORDER BY id);

  -- #############################################################################
  -- CREATING a FUNCTION FOR FRONTEND REQUESTS
  -- #############################################################################


  --DROP FUNCTION proc.getvoronoi (myDate timestamp);

  CREATE or REPLACE FUNCTION proc.getvoronoi (myDate timestamp)
  RETURNS TABLE(id Integer,place TEXT,date timestamp,val REAL,geometry TEXT,geom geometry) AS
  $$
  SELECT 	vor.id as id,
  	rec.place as place,
  	rec.probe_time as date,
  	rec.value as val,
  	ST_ASgeoJSON(vor.geom) as geometry,
    vor.geom as geom
  FROM proc.voronoi_clip as vor
  LEFT JOIN proc.records_info as rec
  	ON vor.id = rec.station_id
  	AND rec.probe_time = myDate;
  $$LANGUAGE SQL;

  --SELECT * FROM proc.getvoronoi('2015-10-12 00:00:00');
