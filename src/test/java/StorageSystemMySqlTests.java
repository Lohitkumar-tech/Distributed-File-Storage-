import java.sql.*;

/** Optional real MySQL test. Use a NEW, EMPTY, dedicated test database. */
public class StorageSystemMySqlTests {
    static void check(boolean value,String message) { if(!value)throw new AssertionError(message); }
    static long rowCount(Connection connection,String table) throws SQLException {
        if(!java.util.Set.of("files","blocks","replicas","nodes","audit_log","cache_entries","pending_tasks","undo_operations").contains(table))
            throw new IllegalArgumentException("Unexpected table name");
        try(Statement s=connection.createStatement();ResultSet r=s.executeQuery("SELECT COUNT(*) FROM "+table)) {
            if(!r.next()) throw new SQLException("COUNT query returned no row for "+table);
            return r.getLong(1);
        }
    }
    public static void main(String[] args) throws Exception {
        String url=System.getenv("STORAGE_TEST_DB_URL");
        String user=System.getenv("STORAGE_DB_USER");
        String password=System.getenv("STORAGE_DB_PASSWORD");
        if(url==null||user==null||password==null) {
            System.out.println("SKIPPED: set STORAGE_TEST_DB_URL, STORAGE_DB_USER and STORAGE_DB_PASSWORD; add Connector/J to the classpath.");
            return;
        }
        // Refuse to overwrite any existing application state. The test leaves its data for inspection.
        try(var firstStore=new StorageSystem.MySqlStore(url,user,password)) {
            check(firstStore.load()==null,"Test needs an empty dedicated database; existing state was not changed.");
            var first=new StorageSystem(firstStore);
            first.addNode("test-N1","A",1000);first.addNode("test-N2","B",1000);first.addNode("test-N3","C",1000);
            var file=first.uploadText("mysql-test.txt","database persistence test");first.delete(file.id);
            try(var secondStore=new StorageSystem.MySqlStore(url,user,password)) {
                var second=new StorageSystem(secondStore);
                check(second.getFile(file.id)==null,"Delete not durable");
                check(second.undo(),"Undo history not durable");
                check(second.download(file.id).file().content.length==25,"Content not durable");
                check(rowCount(secondStore.connection,"files")==1,"Normalized files table was not persisted");
                check(rowCount(secondStore.connection,"blocks")==1,"Normalized blocks table was not persisted");
                check(rowCount(secondStore.connection,"replicas")==3,"Expected three normalized replica rows");
                check(rowCount(secondStore.connection,"nodes")==3,"Normalized node table was not persisted");
                check(rowCount(secondStore.connection,"audit_log")>0,"Audit entries were not persisted");
                boolean conflict=false;
                try { first.addNode("stale-client-node","D",100); } catch(IllegalStateException expected) { conflict=true; }
                check(conflict,"Stale writer was not rejected");
                check(first.state.nodes.get("stale-client-node")==null,"Stale writer did not roll back locally");
            }
        }
        try(var verifyStore=new StorageSystem.MySqlStore(url,user,password)) {
            var verify=new StorageSystem(verifyStore);verify.validateState();
            check(verify.files(1,Long.MAX_VALUE).size()==1&&verify.nodes().size()==3,"Unexpected committed state");
            check(verify.state.nodes.get("stale-client-node")==null,"Stale write reached database");
            check(rowCount(verifyStore.connection,"files")==1&&rowCount(verifyStore.connection,"replicas")==3,
                    "Normalized metadata did not survive closing and reopening the database adapter");
        }
        System.out.println("PASS MySQL commit/reload/delete/undo/content/revision-conflict/rollback checks. Test data retained in the dedicated schema.");
    }
}
