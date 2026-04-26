// sqflite_sw.js - Service worker for sqflite web support
// Place this file in your web/ directory

importScripts('https://cdn.jsdelivr.net/npm/sql.js@1.8.0/dist/sql-wasm.js');

let db;
let SQL;

self.onmessage = async (event) => {
  const { id, method, args } = event.data;
  
  try {
    let result;
    
    switch(method) {
      case 'init':
        SQL = await initSqlJs({
          locateFile: file => `https://cdn.jsdelivr.net/npm/sql.js@1.8.0/dist/${file}`
        });
        result = { success: true };
        break;
        
      case 'open':
        const data = args[0];
        db = new SQL.Database(data);
        result = { success: true };
        break;
        
      case 'execute':
        const sql = args[0];
        const params = args[1] || [];
        const stmt = db.prepare(sql);
        stmt.bind(params);
        let rows = [];
        while (stmt.step()) {
          rows.push(stmt.getAsObject());
        }
        stmt.free();
        result = { rows };
        break;
        
      case 'exec':
        const statements = args[0] || [];
        for (const sql of statements) {
          db.run(sql);
        }
        result = { success: true };
        break;
        
      case 'export':
        const data_out = db.export();
        result = { data: Array.from(data_out) };
        break;
        
      default:
        result = { error: `Unknown method: ${method}` };
    }
    
    self.postMessage({ id, result });
  } catch (error) {
    self.postMessage({ 
      id, 
      error: error.message || 'Unknown error'
    });
  }
};