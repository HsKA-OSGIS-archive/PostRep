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


copy stg.rad_data from '/home/user/PostRep/data.csv' delimiter ',' csv header

ALTER TABLE stg.rad_data ADD fulldate text;

UPDATE stg.rad_data SET fulldate = date|| ' ' || time;

ALTER TABLE stg.rad_data
DROP COLUMN time;


ALTER TABLE stg.rad_data
DROP COLUMN date;


CREATE SCHEMA proc;


-- #############################################################################
-- CREATE relational tables in processing schema
-- #############################################################################

/*
CREATE TABLE proc.in_data AS
  ( SELECT id,
           place,
           z::double PRECISION AS height,
           date::TIMESTAMP,
           val::double PRECISION,
           ST_SetSRID(ST_MakePoint(x::double PRECISION, y::double PRECISION), 4326)::geometry(point, 4326) AS geom,
           ST_SetSRID(ST_MakePoint(x::double PRECISION, y::double PRECISION, z::double PRECISION), 4326)::geometry(pointz, 4326) AS geom_height
   FROM stg.rad_data );
*/

-- #############################################################################
-- CREATE relational tables in processing schema
-- CHANGE TABLE NAMES ACCORDINGLY
-- #############################################################################


ALTER TABLE proc.table1 ADD PRIMARY KEY (id);
ALTER TABLE proc.table2 ADD PRIMARY KEY (id);


CREATE INDEX ON proc.table1 USING gist(geom);
CREATE INDEX ON proc.table2 USING gist(geom);

/*
CREATE INDEX ON proc.table1 USING gist(geom_height);
CREATE INDEX ON proc.table2 USING gist(geom_height);
*/

-- #############################################################################
-- Function creating voronois + TIN per timestamp (clipped)
-- #############################################################################