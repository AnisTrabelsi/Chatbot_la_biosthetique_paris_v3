-- ────────────────────────────────────────────────────────────────
--  Portatou  •  Schéma initial  •  compatible PostgreSQL 14 + pgvector
-- ────────────────────────────────────────────────────────────────

-- 1. Extension pgcrypto (facultatif pour chiffrer certains champs)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. Table utilisateurs (commerciaux)
CREATE TABLE IF NOT EXISTS users (
    id            UUID PRIMARY KEY,                      -- user_id généré côté n8n
    full_name     TEXT        NOT NULL,
    sector        TEXT,
    gps_lat       DOUBLE PRECISION,
    gps_lon       DOUBLE PRECISION,
    portatour_token TEXT,                                -- peut être chiffré avec pgcrypto
    created_at    TIMESTAMPTZ DEFAULT now()
);

-- 3. Table clients / prospects
CREATE TABLE IF NOT EXISTS clients (
    id            SERIAL PRIMARY KEY,
    kdnr          TEXT UNIQUE,
    phone         TEXT UNIQUE,
    salon_name    TEXT,
    addr_street   TEXT,
    addr_city     TEXT,
    addr_zip      TEXT,
    gps_lat       DOUBLE PRECISION,
    gps_lon       DOUBLE PRECISION,
    owner_id      UUID REFERENCES users(id),
    status        TEXT    DEFAULT 'prospect',            -- prospect | actif | perdu
    created_at    TIMESTAMPTZ DEFAULT now(),
    updated_at    TIMESTAMPTZ DEFAULT now()
);

-- 4. Historique de conversation IA (WhatsApp / ChatGPT)
CREATE TABLE IF NOT EXISTS chat_history (
    id           BIGSERIAL PRIMARY KEY,
    client_id    INT REFERENCES clients(id) ON DELETE CASCADE,
    role         TEXT CHECK (role IN ('user','assistant')),
    content      TEXT,
    created_at   TIMESTAMPTZ DEFAULT now()
);

-- 5. Comptes-rendus (photo, audio, formulaire, PDF)
CREATE TABLE IF NOT EXISTS reports (
    id           BIGSERIAL PRIMARY KEY,
    client_id    INT REFERENCES clients(id) ON DELETE CASCADE,
    report_type  TEXT CHECK (report_type IN ('photo','audio','form','pdf')),
    file_url     TEXT,                         -- URL signée MinIO
    transcript   TEXT,                         -- transcription/ocr éventuelle
    created_at   TIMESTAMPTZ DEFAULT now()
);

-- 6. Catalogue offres / formations vectorisé
CREATE TABLE IF NOT EXISTS catalog_chunks (
    id           BIGSERIAL PRIMARY KEY,
    doc_title    TEXT,
    doc_type     TEXT CHECK (doc_type IN ('offer','training')),
    eligibility  JSONB,                        -- règles métiers
    embedding    VECTOR(1536),
    file_url     TEXT,
    created_at   TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_catalog_embed
    ON catalog_chunks USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- 7. Base de connaissances (success stories, objections)
CREATE TABLE IF NOT EXISTS knowledge_chunks (
    id           BIGSERIAL PRIMARY KEY,
    tag          TEXT,
    content      TEXT,
    embedding    VECTOR(1536),
    created_at   TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_know_embed
    ON knowledge_chunks USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- 8. Historique de scoring prospects
CREATE TABLE IF NOT EXISTS lead_score_history (
    id          BIGSERIAL PRIMARY KEY,
    client_id   INT REFERENCES clients(id) ON DELETE CASCADE,
    score       NUMERIC(5,2),
    factors     JSONB,
    decision    TEXT CHECK (decision IN ('add','ignore')),
    created_at  TIMESTAMPTZ DEFAULT now()
);

-- 9. Index classiques
CREATE INDEX IF NOT EXISTS idx_clients_phone  ON clients(phone);
CREATE INDEX IF NOT EXISTS idx_clients_kdnr   ON clients(kdnr);
CREATE INDEX IF NOT EXISTS idx_reports_cli    ON reports(client_id);
CREATE INDEX IF NOT EXISTS idx_chat_cli       ON chat_history(client_id);

-- ─── Fin du script ───
