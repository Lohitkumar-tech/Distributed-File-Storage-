# Normalized MySQL Persistence

The `StorageSystem.MySqlStore` adapter persists application state using relational tables and reconstructs the Java `State` on load. The six B-Tree indexes are rebuilt by `StorageSystem` after loading.

## Tables

- `files`: durable file ID, filename, SHA-256, size and last-access timestamp.
- `blocks`: this scaled-down simulation stores one logical block per file, including optional content bytes.
- `replicas`: physical node placement and byte offset for each file's replica.
- `nodes`: region, capacity, usage, heartbeat timestamp and health status.
- `audit_log`: ordered audit messages.
- `system_state`: revision, ID counters, cache settings and health/rebalance configuration.
- `cache_entries`: LRU ordering.
- `pending_tasks`: queued repair/verification/rebalance tasks.
- `undo_operations`: persisted undo stack entries.

Each modifying operation rewrites these tables inside one InnoDB transaction. This keeps the sample system simple and atomic, but it is not intended as a high-throughput production persistence strategy. Large-scale write performance should be profiled before claiming production scalability.

## Setup

1. Back up any existing database before upgrading.
2. Use `mysql-setup.sql` to create the `storage_system` and `storage_system_test` schemas. The application also creates the normalized tables on connect.
3. Download MySQL Connector/J separately and place the JAR under `lib/`.
4. First test against a dedicated empty schema, preferably `storage_system_test`.
5. Set `STORAGE_TEST_DB_URL`, `STORAGE_DB_USER`, and `STORAGE_DB_PASSWORD` before running `StorageSystemMySqlTests`.

The adapter explicitly refuses to initialize normalized state if it detects a non-empty legacy `storage_app_state` snapshot. It does not silently discard or automatically migrate that old state. Back it up and plan a migration, or use a new empty schema.

## Validation status

The Java source and both test classes compile, and all 48 existing core test groups pass (including 20,000 randomized B-Tree operations). The optional MySQL test only reports `SKIPPED` when its environment variables are absent. A live MySQL server was not available for this patch's validation; run the integration test against a dedicated test database before merging.
