-- change column type (contact_id -> TEXT)

BEGIN TRANSACTION;

CREATE TABLE BLOCK_T (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type INTEGER,
    bot_id INTEGER REFERENCES bot(id) ON DELETE CASCADE,    
    contact_id TEXT,
    name TEXT,
    number TEXT);

INSERT INTO BLOCK_T
    SELECT id, type, bot_id, NULL, name, number
    FROM BLOCK
    WHERE contact_id IS NULL;


DROP TABLE BLOCK;
ALTER TABLE BLOCK_T RENAME TO BLOCK;

ALTER TABLE BLOCK_HISTORY ADD COLUMN viewed INTEGER DEFAULT 0;

CREATE UNIQUE INDEX IF NOT EXISTS idx_block_contact ON block (contact_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_block_bot ON block (bot_id);

COMMIT;
