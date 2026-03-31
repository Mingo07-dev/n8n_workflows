-- =============================================================
-- News Digest Bot - Schema PostgreSQL
-- Eseguito automaticamente all'avvio del container postgres
-- =============================================================

-- Tabella utenti registrati al bot
CREATE TABLE IF NOT EXISTS users (
    user_id     TEXT PRIMARY KEY,
    chat_id     TEXT NOT NULL,
    first_name  TEXT,
    email       TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Tabella topic/argomenti per utente
CREATE TABLE IF NOT EXISTS topics (
    id              SERIAL PRIMARY KEY,
    user_id         TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    keywords        TEXT NOT NULL,
    schedule        TEXT NOT NULL DEFAULT 'none'      CHECK (schedule IN ('none','daily','weekly')),
    schedule_time   TEXT NOT NULL DEFAULT '08:00',    -- formato HH:MM
    schedule_day    TEXT NOT NULL DEFAULT 'lunedi',   -- usato solo se schedule='weekly'
    delivery        TEXT NOT NULL DEFAULT 'telegram'  CHECK (delivery IN ('telegram','email','both')),
    active          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Tabella feed RSS personalizzati aggiuntivi per topic
CREATE TABLE IF NOT EXISTS custom_feeds (
    id          SERIAL PRIMARY KEY,
    user_id     TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    topic_id    INTEGER REFERENCES topics(id) ON DELETE CASCADE,
    feed_url    TEXT NOT NULL,
    feed_name   TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Tabella log degli invii (evita duplicati nel digest schedulato)
CREATE TABLE IF NOT EXISTS digest_log (
    id              SERIAL PRIMARY KEY,
    user_id         TEXT NOT NULL,
    topic_id        INTEGER NOT NULL,
    delivery_method TEXT,
    sent_at         TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- Indici per le query più frequenti
-- =============================================================

CREATE INDEX IF NOT EXISTS idx_topics_user_id      ON topics(user_id);
CREATE INDEX IF NOT EXISTS idx_topics_active        ON topics(active);
CREATE INDEX IF NOT EXISTS idx_topics_schedule      ON topics(schedule) WHERE schedule != 'none';
CREATE INDEX IF NOT EXISTS idx_custom_feeds_topic   ON custom_feeds(topic_id);
CREATE INDEX IF NOT EXISTS idx_digest_log_topic     ON digest_log(topic_id, sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_digest_log_sent      ON digest_log(sent_at DESC);

-- =============================================================
-- Funzione per aggiornare updated_at automaticamente
-- =============================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER trg_topics_updated_at
    BEFORE UPDATE ON topics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
