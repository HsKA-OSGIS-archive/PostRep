# PostRep
repository for fictional company Postmaster of HSKA OSGIS course WS 2018/2019

- use aliases when referencing tables

	SELECT a.id, 
	       a.date, 
	       a.value, 
	       b.place
	FROM opensource.time AS a
	JOIN opensource.Stations AS b ON a.id = b.id;


- implement FOREIGN KEY constraints to actually connect the tables

	https://www.postgresql.org/docs/9.6/tutorial-fk.html

- DON'T use capital letters in table names (or ANY other names) opensource.Stations -> opensource.stations

- use schemas / table names from before (e.g. schema "stg" as staging, "proc" etc.)
