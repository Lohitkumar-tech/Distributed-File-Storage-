# Apply this patch to the existing Git working tree

Copy the contents of this ZIP into the root of your working repository, preserving the directory structure and allowing replacement of the matching files. It changes only:

- `src/main/java/StorageSystem.java`
- `src/test/java/StorageSystemMySqlTests.java`
- `mysql-setup.sql`
- `README.md`
- `docs/INTEGRATION_AUDIT.md`

It adds `docs/MYSQL_PERSISTENCE.md`.

Then, from the repository root:

```powershell
git status --short
.\test.bat
git --no-pager diff --check
```

Expected for the core suite: `ALL 48 TEST GROUPS PASSED`. The MySQL integration test will be skipped until Connector/J and the dedicated test database settings are configured.

Do not commit or push until a live MySQL integration run succeeds. Do not use a database containing valuable data for the integration test. The patch refuses to load an existing non-empty `storage_app_state` snapshot; use a new empty schema or perform an explicit migration.
