CREATE TABLE fds.sym_v1_sym_entity (
    factset_entity_id character(8) NOT NULL COLLATE pg_catalog."C",
    entity_proper_name character varying(90) NOT NULL COLLATE pg_catalog."C",
    iso_country character(2) COLLATE pg_catalog."C",
    entity_type character(3) COLLATE pg_catalog."C"
);

ALTER TABLE fds.sym_v1_sym_entity OWNER TO postgres;
ALTER TABLE ONLY fds.sym_v1_sym_entity
    ADD CONSTRAINT sym_v1_sym_entity_pkey PRIMARY KEY (factset_entity_id);

INSERT INTO fds.sym_v1_sym_entity (
  factset_entity_id,
  entity_proper_name,
  iso_country,
  entity_type
) VALUES
  ('FOO001-E', 'FooBar, Inc.', 'US', 'FOO'),
  ('BAR001-E', 'BarFoo, Inc.', 'CH', 'BAR'),
  ('TX0001-X', 'City of Dallas (Texas)', 'US', 'GOV')
