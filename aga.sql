--DROP FUNCTION proc.getvoronoi (myDate timestamp);

CREATE or REPLACE FUNCTION proc.getvoronoi (myDate timestamp)
RETURNS TABLE(id Integer,place TEXT,date timestamp,val REAL,geometry TEXT) AS
$$
SELECT 	vor.id as id,
	rec.place as place,
	rec.probe_time as date,
	rec.value as val,
	ST_ASgeoJSON(vor.geom) as geometry
FROM proc.voronoi_clip as vor
LEFT JOIN proc.records_info as rec
	ON vor.id = rec.station_id
	AND rec.probe_time = myDate;
$$LANGUAGE SQL;

--select * from proc.getvoronoi('2015-10-12 00:00:00');

--DROP FUNCTION proc.gettin (myDate timestamp);

CREATE or REPLACE FUNCTION proc.gettin (myDate timestamp)
RETURNS TABLE(id Integer,place TEXT,date timestamp,val REAL,geometry TEXT) AS
$$
SELECT 	tin.id as id,
	rec.place as place,
	rec.probe_time as date,
	rec.value as val,
	ST_ASgeoJSON(tin.geom) as geometry
FROM proc.tin_clip as tin
LEFT JOIN proc.records_info as rec
	ON tin.id = rec.station_id
	AND rec.probe_time = myDate;
$$LANGUAGE SQL;

--select * from proc.gettin('2015-10-12 00:00:00');
