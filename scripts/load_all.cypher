// Optional reset
MATCH (n) DETACH DELETE n;
CALL apoc.schema.assert({}, {});

// Constraints
CREATE CONSTRAINT researcher_id IF NOT EXISTS FOR (r:Researcher) REQUIRE r.researcherId IS UNIQUE;
CREATE CONSTRAINT orcid_val IF NOT EXISTS FOR (o:ORCID) REQUIRE o.value IS UNIQUE;
CREATE CONSTRAINT email_addr IF NOT EXISTS FOR (e:Email) REQUIRE e.address IS UNIQUE;
CREATE CONSTRAINT paper_doi IF NOT EXISTS FOR (p:Paper) REQUIRE p.doi IS UNIQUE;
CREATE CONSTRAINT patent_num IF NOT EXISTS FOR (p:Patent) REQUIRE p.patentNumber IS UNIQUE;
CREATE CONSTRAINT drug_code IF NOT EXISTS FOR (d:Drug) REQUIRE d.codeName IS UNIQUE;

// Helpful indexes
CREATE INDEX res_lastname IF NOT EXISTS FOR (r:Researcher) ON (r.lastName);
CREATE INDEX res_firstname IF NOT EXISTS FOR (r:Researcher) ON (r.firstName);
CREATE INDEX inst_name IF NOT EXISTS FOR (i:Institution) ON (i.name);


// Nodes
LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/researchers.csv' AS row
MERGE (r:Researcher {researcherId: row.researcherId})
SET
  r.firstName = row.firstName,
  r.lastName = row.lastName,
  r.suffix = row.suffix;

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/institutions.csv' AS row
MERGE (i:Institution {instId: row.instId})
SET i.name = row.name, i.country = row.country, i.city = row.city;

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/papers.csv' AS row
MERGE (p:Paper {doi: row.doi})
SET p.title = row.title, p.year = toInteger(row.year), p.journal = row.journal;

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/targets.csv' AS row
MERGE (t:Target {symbol: row.symbol})
SET t.name = row.name;

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/phenotypes.csv' AS row
MERGE (ph:Phenotype {phenotypeId: row.phenotypeId})
SET ph.name = row.name, ph.meshId = row.meshId;

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/companies.csv' AS row
MERGE (co:Company {companyId: row.companyId})
SET co.name = row.name, co.country = row.country;

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/drugs.csv' AS row
MERGE (d:Drug {codeName: row.codeName})
SET d.name = row.name, d.phase = row.phase;

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/patents.csv' AS row
MERGE (pat:Patent {patentNumber: row.patentNumber})
SET pat.title = row.title, pat.filingDate = date(row.filingDate);

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/orcids.csv' AS row
MERGE (o:ORCID {value: row.orcid});

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/emails.csv' AS row
MERGE (e:Email {address: row.email});

// Relationships
LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/orcids.csv' AS row
MATCH (r:Researcher {researcherId: row.researcherId})
MATCH (o:ORCID {value: row.orcid})
MERGE (r)-[:HAS_ORCID]->(o);

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/emails.csv' AS row
MATCH (r:Researcher {researcherId: row.researcherId})
MATCH (e:Email {address: row.email})
MERGE (r)-[:HAS_EMAIL]->(e);

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/affiliations.csv' AS row
MATCH (r:Researcher {researcherId: row.researcherId})
MATCH (i:Institution {instId: row.instId})
MERGE (r)-[:AFFILIATED_WITH {year: toInteger(row.year)}]->(i);

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/authorship.csv' AS row
MATCH (r:Researcher {researcherId: row.researcherId})
MATCH (p:Paper {doi: row.doi})
MERGE (r)-[:AUTHORED {position: row.position}]->(p);

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/citations.csv' AS row
MATCH (p1:Paper {doi: row.sourceDoi})
MATCH (p2:Paper {doi: row.targetDoi})
MERGE (p1)-[:CITES]->(p2);

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/paper_targets.csv' AS row
MATCH (p:Paper {doi: row.doi})
MATCH (t:Target {symbol: row.targetSymbol})
MERGE (p)-[:STUDIES_TARGET]->(t);

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/drug_targets.csv' AS row
MATCH (d:Drug {codeName: row.codeName})
MATCH (t:Target {symbol: row.targetSymbol})
MERGE (d)-[:HAS_TARGET]->(t);

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/drug_treats.csv' AS row
MATCH (d:Drug {codeName: row.codeName})
MATCH (ph:Phenotype {phenotypeId: row.phenotypeId})
MERGE (d)-[:TREATS]->(ph);

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/drug_companies.csv' AS row
MATCH (d:Drug {codeName: row.codeName})
MATCH (co:Company {companyId: row.companyId})
MERGE (d)-[:DEVELOPED_BY]->(co);

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/patent_targets.csv' AS row
MATCH (pat:Patent {patentNumber: row.patentNumber})
MATCH (t:Target {symbol: row.targetSymbol})
MERGE (pat)-[:TARGETS]->(t);

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/patent_companies.csv' AS row
MATCH (pat:Patent {patentNumber: row.patentNumber})
MATCH (co:Company {companyId: row.companyId})
MERGE (pat)-[:ASSIGNED_TO]->(co);

LOAD CSV WITH HEADERS FROM 'file:///d:/temp/er/inventorship.csv' AS row
MATCH (r:Researcher {researcherId: row.researcherId})
MATCH (pat:Patent {patentNumber: row.patentNumber})
MERGE (r)-[:INVENTED]->(pat);