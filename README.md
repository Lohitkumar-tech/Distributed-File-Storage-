# Distributed File Storage and Replication System

A Java 17+ interactive simulation of a distributed file-storage control plane. The current application models file metadata, deduplication, logical block allocation, replica placement, node health, repair/rebalance tasks, a bounded cache, undo operations, an audit log, and six rebuildable B-Tree indexes.

## Requirements

- JDK 17 or newer (`java` and `javac` on PATH).
- MySQL Server and MySQL Connector/J only if using MySQL mode or running the optional real-MySQL test.
- Windows users can use `run.bat` and `test.bat`. Other platforms can use the commands below.

## Build and run

From the repository root:

```bash
mkdir -p out
javac -encoding UTF-8 -d out src/main/java/BTree.java src/main/java/StorageSystem.java
java -cp out StorageSystem
```

On Windows, run `run.bat`. The program lets you select local durable state, MySQL durable state, or an in-memory session. Local/in-memory modes do not require external Java libraries.

## Run tests

```bash
mkdir -p out
javac -encoding UTF-8 -d out src/main/java/BTree.java src/main/java/StorageSystem.java src/test/java/StorageSystemTests.java src/test/java/StorageSystemMySqlTests.java
java -cp out StorageSystemTests
java -cp out StorageSystemMySqlTests
```

The core test suite reports 48 test groups, including 20,000 randomized B-Tree operations. The MySQL test prints `SKIPPED` unless its environment variables are configured; a real database run has not been certified by the ZIP-based integration process.

On Windows, `test.bat` performs the compilation and core suite and invokes the optional MySQL test.

## MySQL setup

1. Run `mysql-setup.sql` with your own MySQL account, or let `MySqlStore` create the tables when it connects. The script creates the `storage_system` and `storage_system_test` schemas and initializes the normal development schema.
2. Download MySQL Connector/J from the official vendor and place the JAR under `lib/` (the JAR is intentionally not included in the repository).
3. Set `STORAGE_DB_PASSWORD` or use the application's password prompt.
4. Select MySQL mode and use `jdbc:mysql://localhost:3306/storage_system` unless your setup differs.
5. For the optional integration test, set `STORAGE_TEST_DB_URL=jdbc:mysql://localhost:3306/storage_system_test`, `STORAGE_DB_USER`, and `STORAGE_DB_PASSWORD`. Use a dedicated disposable test schema; the test writes records and leaves test data for inspection. Do not point it at production or valuable data.

The MySQL adapter stores file metadata in `files`, logical block content in `blocks`, physical placements in `replicas`, node state in `nodes`, and ordered audit entries in `audit_log`. Additional `system_state`, `cache_entries`, `pending_tasks`, and `undo_operations` tables preserve revision/configuration, cache order, queued tasks, and undo history. Each file is represented as one logical block in this scaled-down simulation.

## Sample inputs

`sample-input.txt` and `edge-input.txt` contain interactive console inputs for demos. After compiling, replay on a Unix-like shell with:

```bash
java -cp out StorageSystem < sample-input.txt
java -cp out StorageSystem < edge-input.txt
```

PowerShell:

```powershell
Get-Content .\sample-input.txt | java -cp out StorageSystem
Get-Content .\edge-input.txt | java -cp out StorageSystem
```

## Architecture notes and known alignment gaps

The abstract document is the intended specification. MySQL persistence uses normalized `files`, `blocks`, `replicas`, `nodes`, and `audit_log` tables, plus support tables for revision/configuration, cache, pending tasks, and undo history. A database containing a non-empty legacy `storage_app_state` snapshot is rejected rather than silently reset; migrate it deliberately or configure a fresh schema. The application's supporting queues/stacks still use Java collection implementations rather than separately implemented custom `PriorityQueue`, `Stack`, and `Queue` classes; that remains a conformance item. A live MySQL run is still required to certify database integration. See `docs/INTEGRATION_AUDIT.md`.

## Collaboration

Use a separate feature branch and pull request per contributor. Each person must commit their own actual changes with their own Git identity. A contribution ZIP or a contribution-summary document is not proof of Git authorship. See `docs/CONTRIBUTIONS.md`.
