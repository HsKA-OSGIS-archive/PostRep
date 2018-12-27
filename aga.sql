--Select * from stg.rad_data;

--Select * from proc.in_data;

--CREATE INDEX ON proc.in_data USING gist(geom);

--DROP FUNCTION proc.func;

CREATE or REPLACE FUNCTION PROC.FUNC (myDate timestamp)
RETURNS TABLE(val double precision,Datum timestamp,geom geometry) AS
$$
SELECT inData.val AS val,myDate::timestamp AS date, myVoronoi.geom
FROM 	(SELECT  (ST_Dump(ST_CollectionExtract(ST_VoronoiPolygons(ST_Collect(DISTINCT geom)) ,3))).geom
	FROM proc.in_data
	WHERE date = myDate) AS myVoronoi,proc.in_data AS inData
WHERE inData.date = myDate
  AND ST_intersects(inData.geom,myVoronoi.geom)
$$LANGUAGE SQL;

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
