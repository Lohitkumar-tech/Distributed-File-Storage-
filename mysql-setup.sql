-- Distributed File Storage: normalized MySQL persistence schema
-- Run with a MySQL account that has CREATE/SELECT/INSERT/UPDATE/DELETE permissions.
-- The application also runs CREATE TABLE IF NOT EXISTS when MySqlStore connects.
-- Use storage_system for normal development and storage_system_test for isolated tests.
CREATE DATABASE IF NOT EXISTS storage_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS storage_system_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE storage_system;

CREATE TABLE IF NOT EXISTS system_state (
    id INT PRIMARY KEY,
    revision BIGINT NOT NULL,
    initialized BOOLEAN NOT NULL DEFAULT FALSE,
    next_file BIGINT NOT NULL,
    next_task BIGINT NOT NULL,
    cache_tick BIGINT NOT NULL,
    timeout_millis BIGINT NOT NULL,
    imbalance_threshold DOUBLE NOT NULL,
    cache_limit INT NOT NULL
) ENGINE=InnoDB;

INSERT IGNORE INTO system_state
    (id, revision, initialized, next_file, next_task, cache_tick, timeout_millis, imbalance_threshold, cache_limit)
VALUES (1, 0, FALSE, 1, 1, 0, 300000, 0.25, 5);

CREATE TABLE IF NOT EXISTS nodes (
    node_id VARCHAR(191) PRIMARY KEY,
    region VARCHAR(191) NOT NULL,
    capacity BIGINT NOT NULL,
    used_bytes BIGINT NOT NULL,
    heartbeat_ms BIGINT NOT NULL,
    healthy BOOLEAN NOT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS files (
    file_id BIGINT PRIMARY KEY,
    filename VARCHAR(1024) NOT NULL,
    content_hash CHAR(64) NOT NULL UNIQUE,
    size_bytes BIGINT NOT NULL,
    last_access BIGINT NOT NULL
) ENGINE=InnoDB;

-- This simulation represents a file as one logical block; physical placement is in replicas.
CREATE TABLE IF NOT EXISTS blocks (
    block_id BIGINT PRIMARY KEY,
    file_id BIGINT NOT NULL UNIQUE,
    block_index INT NOT NULL DEFAULT 0,
    size_bytes BIGINT NOT NULL,
    data LONGBLOB NULL,
    CONSTRAINT fk_blocks_file FOREIGN KEY (file_id) REFERENCES files(file_id) ON DELETE CASCADE,
    UNIQUE KEY uq_file_block (file_id, block_index)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS replicas (
    file_id BIGINT NOT NULL,
    block_id BIGINT NOT NULL,
    node_id VARCHAR(191) NOT NULL,
    start_offset BIGINT NOT NULL,
    PRIMARY KEY (file_id, node_id),
    CONSTRAINT fk_replicas_file FOREIGN KEY (file_id) REFERENCES files(file_id) ON DELETE CASCADE,
    CONSTRAINT fk_replicas_block FOREIGN KEY (block_id) REFERENCES blocks(block_id) ON DELETE CASCADE,
    CONSTRAINT fk_replicas_node FOREIGN KEY (node_id) REFERENCES nodes(node_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS cache_entries (
    file_id BIGINT PRIMARY KEY,
    access_tick BIGINT NOT NULL,
    CONSTRAINT fk_cache_file FOREIGN KEY (file_id) REFERENCES files(file_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pending_tasks (
    sequence_no BIGINT PRIMARY KEY,
    priority INT NOT NULL,
    task_type VARCHAR(32) NOT NULL,
    file_id BIGINT NOT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS undo_operations (
    position INT PRIMARY KEY,
    payload LONGBLOB NOT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS audit_log (
    sequence_no BIGINT PRIMARY KEY,
    message TEXT NOT NULL
) ENGINE=InnoDB;
