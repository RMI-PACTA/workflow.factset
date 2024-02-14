--
-- TOC entry 355 (class 1259 OID 31350)
-- Name: ref_v2_issue_type_map; Type: TABLE; Schema: fds; Owner: postgres
--

CREATE TABLE fds.ref_v2_issue_type_map (
    issue_type_code character(2) NOT NULL COLLATE pg_catalog."C",
    issue_type_desc character varying(25) NOT NULL COLLATE pg_catalog."C",
    asset_class_code character(1) COLLATE pg_catalog."C"
);


ALTER TABLE fds.ref_v2_issue_type_map OWNER TO postgres;
ALTER TABLE ONLY fds.ref_v2_issue_type_map
    ADD CONSTRAINT ref_v2_issue_type_map_pkey PRIMARY KEY (issue_type_code);

INSERT INTO fds.ref_v2_issue_type_map (
  issue_type_code,
  issue_type_desc,
  asset_class_code
) VALUES
  ('00', 'N/A', NULL),
  ('BB', 'Bond', 'W'),
  ('DD', 'Debenture', 'W'),
  ('EE', 'Equity', 'X'),
  ('02', 'Dual Listing', 'X'),
  ('F2', 'Closed-End Mutual Fund', 'X'),
  ('F1', 'Exchange Traded Fund', 'X'),
  ('LL', 'Loan', 'Z'),
  ('NN', 'Note', 'Z')
  ;
