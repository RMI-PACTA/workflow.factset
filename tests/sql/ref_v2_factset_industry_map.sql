CREATE TABLE fds.ref_v2_factset_industry_map (
    factset_industry_code character(4) NOT NULL COLLATE pg_catalog."C",
    factset_industry_desc character varying(34) NOT NULL COLLATE pg_catalog."C",
    factset_sector_code character(4) NOT NULL COLLATE pg_catalog."C"
);


ALTER TABLE fds.ref_v2_factset_industry_map OWNER TO postgres;
ALTER TABLE ONLY fds.ref_v2_factset_industry_map
    ADD CONSTRAINT ref_v2_factset_industry_map_pkey PRIMARY KEY (factset_industry_code);

INSERT INTO fds.ref_v2_factset_industry_map (
  factset_industry_code,
  factset_industry_desc,
  factset_sector_code
) VALUES
  ('XX01', 'Motor Vehicles', 'XX01'),
  ('XX02', 'Air Freight/Couriers', 'XX02'),
  ('XX03', 'Airlines', 'XX02'),
  ('XX04', 'Construction Materials', 'XX03'),
  ('XX05', 'Coal', 'XX04'),
  ('XX06', 'Trucking', 'XX05'),
  ('XX07', 'Trucks/Construction/Farm Machinery', 'XX05'),
  ('XX08', 'Gas Distributors', 'XX06'),
  ('XX09', 'Integrated Oil', 'XX06'),
  ('XX10', 'Oil & Gas Pipelines', 'XX06'),
  ('XX11', 'Oil & Gas Production', 'XX07'),
  ('XX12', 'Alternative Power Generation', 'XX08'),
  ('XX13', 'Electric Utilities', 'XX09'),
  ('XX14', 'Marine Shipping', 'XX10'),
  ('XX15', 'Steel', 'XX11'),
  ('YY01', 'Backpack Manufacturing', 'YY01'),
  ('YY02', 'Goat Herding', 'YY01'),
  ('YY03', 'Rainbow Chasing', 'YY02'),
  ('YY04', 'Oil & Gas Burning', 'XX06')
  ;
