-- We always drop the old table and recreate it
DROP TABLE IF EXISTS pkgCandidates;

CREATE TABLE pkgCandidates (
    ID          TEXT  PRIMARY KEY,
    Name        TEXT  NOT NULL,
    Version     TEXT NOT NULL,
    Release     INT,
    Homepage    TEXT,
    Summary     TEXT,
    Description TEXT
);