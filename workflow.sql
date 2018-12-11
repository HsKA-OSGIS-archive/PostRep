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


\copy stg.rad_data from '/home/user/PostRep/data.csv' delimiter ' ' csv header


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
shp2pgsql -I -d -s 4326 /media/sf_f/tmp/germany.shp proc.germany | psql -d rad

-- #############################################################################
-- Function creating voronois + TIN per timestamp (clipped)
-- #############################################################################

DO $function$
DECLARE 
    _rec record;
    _sql_vor text;
    _sql_clip text;
BEGIN
    FOR _rec IN SELECT DISTINCT ON (probe_time) probe_time
                FROM proc.records_info
    LOOP
        _sql_vor := format('
                    CREATE TABLE proc.voronoi_%s as (
                        SELECT (ST_Dump(
                                    ST_CollectionExtract(
                                        ST_VoronoiPolygons(
                                            ST_Collect(b.geom)
                                            )
                                        ,3)
                                    )).geom::geometry(Polygon, 4326) as geom
                        FROM proc.records_info AS a
                        LEFT JOIN proc.station_info AS b on a.station_id = b.id
                        WHERE a.probe_time = %L
                    );

                    CREATE INDEX on proc.voronoi_%s USING gist(geom);
                    ', 
                    to_char(_rec.probe_time, 'YYYYMMDDHH24MM'),
                    _rec.probe_time,
                    to_char(_rec.probe_time, 'YYYYMMDDHH24MM')
                    );

                    /*
                    %s -> test
                    %L -> 'test' string
                    %I -> "test"
                    */
        
        RAISE notice '%', _sql_vor;

        _sql_clip := format('
                    CREATE TABLE proc.voronoi_%s_clip as (
                        SELECT (ST_Dump(geom)).geom::geometry(POLYGON, 4326)
                        FROM (
                            SELECT 
                                CASE
                                    WHEN ST_Overlaps(a.geom, b.geom) THEN ST_Intersection(a.geom, b.geom)
                                    WHEN ST_Within(a.geom, b.geom) THEN a.geom
                                    ELSE NULL
                                END as geom
                            FROM proc.voronoi_%s as a
                            LEFT JOIN proc.germany AS b on ST_Intersects(a.geom, b.geom)
                            ) AS foo
                        );

                        CREATE INDEX ON proc.voronoi_%s_clip USING gist(geom);
                    )
        ', to_char(_rec.probe_time, 'YYYYMMDDHH24MM'),
           to_char(_rec.probe_time, 'YYYYMMDDHH24MM'),
           to_char(_rec.probe_time, 'YYYYMMDDHH24MM') 
        );

        raise notice '%', _sql_clip;
    END LOOP;
END;
$function$
LANGUAGE plpgsql;
