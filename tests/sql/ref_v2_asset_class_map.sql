--
-- TOC entry 278 (class 1259 OID 30953)
-- Name: ref_v2_asset_class_map; Type: TABLE; Schema: fds; Owner: postgres
--

CREATE TABLE fds.ref_v2_asset_class_map (
    asset_class_code character(1) NOT NULL COLLATE pg_catalog."C",
    asset_class_desc character varying(25) NOT NULL COLLATE pg_catalog."C"
);


ALTER TABLE fds.ref_v2_asset_class_map OWNER TO postgres;

ALTER TABLE ONLY fds.ref_v2_asset_class_map
    ADD CONSTRAINT ref_v2_asset_class_map_pkey PRIMARY KEY (asset_class_code);

INSERT INTO fds.ref_v2_asset_class_map (
  asset_class_code,
  asset_class_desc
) VALUES
  ('X', 'Bond'),
  ('Y', 'Equity'),
  ('Z', 'Other')
  ;
