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
