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



CREATE TABLE proc.table1(id integer,place text,x text,y text,z text);


CREATE TABLE proc.table2(id integer,place text,date text,value text);



INSERT INTO proc.table1 SELECT id,place,x,y,z FROM stg.rad_data;


INSERT INTO proc.table2 SELECT id,place,date,val FROM stg.rad_data;




ALTER TABLE proc.table1 ADD PRIMARY KEY (id);
ALTER TABLE proc.table2 ADD PRIMARY KEY (id);


SELECT b.id,a.place,a.x,a.y,a.z,b.date,b.value FROM proc1.table2 AS b JOIN proc1.table1 AS a ON a.id = b.id;



CREATE TABLE proc.table3  (
    id integer,
    place text,
    x text,
    y text,
    z text,
    date text, 
    val text
);

INSERT INTO proc.table3 SELECT b.id,a.place,a.x,a.y,a.z,b.date,b.value FROM proc1.table2 AS b JOIN proc1.table1 AS a ON a.id = b.id;




CREATE INDEX ON proc.table1 USING gist(geom);
CREATE INDEX ON proc.table2 USING gist(geom);

/*
CREATE INDEX ON proc.table1 USING gist(geom_height);
CREATE INDEX ON proc.table2 USING gist(geom_height);
*/

-- #############################################################################
-- Function creating voronois + TIN per timestamp (clipped)
-- #############################################################################