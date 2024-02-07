CREATE TABLE my_object(
  id serial,
  time_create TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  time_dead TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id, time_create)
);

CREATE TABLE mini_object1 (
  name varchar(17)
) INHERITS (my_object);

CREATE TABLE mini_object2 (
  name varchar(17)
) INHERITS (my_object);

CREATE TABLE mini_object3 (
  name varchar(17)
) INHERITS (my_object);


SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'mini_object3';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'my_object';

SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'mini_object3';

SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'my_object';


CREATE OR REPLACE FUNCTION update_time_create()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM my_object WHERE id = NEW.id) THEN
    UPDATE my_object SET time_dead = CURRENT_TIMESTAMP WHERE id = NEW.id;
    RETURN NEW;
  ELSE
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER update_time_create_trigger
BEFORE INSERT ON mini_object1
FOR EACH ROW
EXECUTE FUNCTION update_time_create();

CREATE TRIGGER update_time_create_trigger
BEFORE INSERT ON mini_object2
FOR EACH ROW
EXECUTE FUNCTION update_time_create();

CREATE TRIGGER update_time_create_trigger
BEFORE INSERT ON mini_object3
FOR EACH ROW
EXECUTE FUNCTION update_time_create();

CREATE TRIGGER update_time_create_trigger
BEFORE INSERT ON my_object
FOR EACH ROW
EXECUTE FUNCTION update_time_create();

INSERT INTO mini_object1 (id, name) VALUES
(1, 'name 1'),
(2, 'name 2');

INSERT INTO mini_object1 (id, name) VALUES
(1, 'name 1');

INSERT INTO mini_object1 (id, name) VALUES
(3, 'name 3');

INSERT INTO mini_object2 (id, name) VALUES
(1, 'name 1'),
(2, 'name 2');

INSERT INTO mini_object3 (id, name) VALUES
(2, 'name 2');

INSERT INTO mini_object3 (id, name) VALUES
(7, 'name 7');

SELECT * FROM my_object ORDER BY 1;

CREATE FUNCTION array_avg(numeric[])
RETURNS numeric AS
$$
SELECT AVG(x) FROM UNNEST($1) AS t(x);
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE AGGREGATE self_avg(numeric) (
    SFUNC = array_append,
    STYPE = numeric[],
    FINALFUNC = array_avg,
    INITCOND = '{}'
);





SELECT self_avg(id) AS Среднее_значение_по_id FROM my_object;
CREATE OR REPLACE FUNCTION merged_func(text, text, text)
RETURNS text AS
$$
SELECT CASE WHEN $1 IS NULL THEN $2 ELSE $1 || $3 || $2 END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE AGGREGATE name_merge(text, text) (
    SFUNC = merged_func,
    STYPE = text
);

SELECT name_merge(name, ', ') AS Слияние_name FROM mini_object1;

DO $$
DECLARE
    child_table record;
BEGIN
    FOR child_table IN 
        SELECT c.relname
        FROM pg_inherits i
        JOIN pg_class c ON c.oid = i.inhrelid
        WHERE i.inhparent = 'my_object'::regclass
    LOOP
        EXECUTE format('CREATE INDEX ON %I (name)', child_table.relname);
    END LOOP;
END $$;

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'mini_object1';

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'my_object';
