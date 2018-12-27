--Select * from stg.rad_data;

--Select * from proc.in_data;

--DROP FUNCTION proc.getvoronoi (myDate timestamp);

CREATE or REPLACE FUNCTION proc.getvoronoi (myDate timestamp)
RETURNS TABLE(id Integer,place TEXT,probe_time timestamp,val REAL,geom geometry) AS
$$
SELECT 	vor.id as id,
	rec.place as place,
	rec.probe_time as probe_time,
	rec.value as val,
	vor.geom as geom
FROM proc.voronoi_clip as vor
LEFT JOIN proc.records_info as rec
	ON vor.id = rec.station_id
	AND rec.probe_time = myDate;
$$LANGUAGE SQL;

select * from proc.getvoronoi('2015-10-12 00:00:00');

--select date from proc.voronoi;
--Select date from proc.voronoi where date = '2015-10-12 21:50:00';

SELECT * from proc.func('2015-10-12 21:50:00');

--DROP FUNCTION proc.functin;

CREATE or REPLACE FUNCTION PROC.FUNCTIN (myDate timestamp)
RETURNS TABLE(val double precision,Datum timestamp,geom geometry) AS
$$
SELECT inData.val AS val,myDate::timestamp AS date, myVoronoi.geom
FROM 	(SELECT  (ST_Dump(ST_CollectionExtract(ST_DelaunayTriangles(ST_Collect(DISTINCT geom)) ,3))).geom
	FROM proc.in_data
	WHERE date = myDate) AS myVoronoi,proc.in_data AS inData
WHERE inData.date = myDate
  AND ST_intersects(inData.geom,myVoronoi.geom)
$$LANGUAGE SQL;

SELECT * from proc.functin('2015-10-12 21:50:00');
