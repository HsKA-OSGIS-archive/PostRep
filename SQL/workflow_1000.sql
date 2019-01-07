CREATE SCHEMA stg;


-- #############################################################################
-- Importing and formatting data
-- #############################################################################


CREATE TABLE stg.rad_data_1000 (
    id integer,
    place text,
    x text,
    y text,
    z text,
    date text,
    time text,
    val text
);




\copy stg.rad_data_1000 from '/home/user/PostRep/Upscaled_data/new_test_1000.csv' delimiter ',' csv header


ALTER TABLE stg.rad_data_1000 ADD probe_time timestamp without time zone;


UPDATE stg.rad_data_1000 SET probe_time = (date|| ' ' || time)::timestamp without time zone;


ALTER TABLE stg.rad_data_1000
DROP COLUMN time;


ALTER TABLE stg.rad_data_1000
DROP COLUMN date;


ALTER TABLE stg.rad_data_1000
    ADD COLUMN geom geometry(point, 4326),
    ADD COLUMN geom_3d geometry(pointz, 4326);


UPDATE stg.rad_data_1000
SET geom = ST_SetSRID(ST_MakePoint(x::numeric, y::numeric), 4326),
    geom_3d = ST_SetSRID(ST_MakePoint(x::numeric, y::numeric, z::numeric), 4326);


CREATE SCHEMA proc;


-- #############################################################################
-- CREATE relational tables in processing schema
-- #############################################################################


DROP TABLE IF EXISTS proc.station_info_1000;


CREATE TABLE proc.station_info_1000 (
    id int primary key,
    place text,
    geom geometry(Point, 4326),
    geom_3d geometry(PointZ, 4326)
    );


DROP TABLE IF EXISTS proc.records_info_1000;


CREATE TABLE proc.records_info_1000 (
    id int primary key ,
    station_id int references proc.station_info_1000(id),
    place text,
    probe_time timestamp,
    value real
    );


INSERT INTO proc.station_info_1000 (id, place, geom, geom_3d) (
    SELECT row_number() over() AS id,
           foo.*
    FROM
      (SELECT DISTINCT ON (place, geom)
            place,
            geom,
            geom_3d
       FROM stg.rad_data_1000) AS foo);


INSERT INTO proc.records_info_1000 (id, place, probe_time, value, station_id)
  ( SELECT a.id,
           a.place,
           a.probe_time,
           a.val::real,
           b.id
   FROM stg.rad_data_1000 AS a
   LEFT JOIN proc.station_info_1000 AS b ON a.place = b.place
   AND a.geom = b.geom);


CREATE INDEX ON proc.station_info_1000  USING gist(geom);

CREATE INDEX ON proc.station_info_1000  USING gist(geom_3d);

-- #############################################################################
-- IMPORT GERMANY DATA
-- #############################################################################

shp2pgsql -I -d -s 4326 /home/user/PostRep/germany.shp proc.germany | psql -d rad



-- #############################################################################
-- CREATING AND CLIPPING VORONOI
-- #############################################################################



CREATE TEMPORARY TABLE voronoi_1000 AS (
SELECT  (
			ST_Dump(ST_CollectionExtract(ST_VoronoiPolygons(ST_Collect(DISTINCT geom)) ,3))).geom
		FROM proc.station_info_1000);



CREATE INDEX ON voronoi_1000  USING gist(geom);


CREATE TABLE proc.voronoi_clip_1000 as (
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
                            FROM voronoi_1000 as a
                            LEFT JOIN proc.germany AS b on ST_Intersects(a.geom, b.geom)
                            ) AS foo
                        )AS myVoronoi,
			proc.station_info_1000 AS inData
	WHERE ST_intersects(inData.geom,myVoronoi.geom)
	ORDER BY id);


-- #############################################################################
-- CREATING AND CLIPPING TIN
-- #############################################################################

CREATE TEMPORARY TABLE tin_1000 AS (
SELECT  (
			ST_Dump(ST_CollectionExtract( ST_DelaunayTriangles(ST_Collect(DISTINCT geom)) ,3))).geom
		FROM proc.station_info_1000);

CREATE INDEX ON tin_1000  USING gist(geom);

CREATE TABLE proc.tin_clip_1000 as (
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
                            FROM tin_1000 as a
                            LEFT JOIN proc.germany AS b on ST_Intersects(a.geom, b.geom)
                            ) AS foo
                        )AS myTin,
			proc.station_info_1000 AS inData
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
  FROM proc.voronoi_clip_1000 as vor
  LEFT JOIN proc.records_info_1000 as rec
  	ON vor.id = rec.station_id
  	AND rec.probe_time = myDate;
  $$LANGUAGE SQL;

  --SELECT * FROM proc.getvoronoi('2015-10-12 00:00:00');
