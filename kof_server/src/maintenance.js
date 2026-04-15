import Database from "better-sqlite3";

// Record the latest result of a maintenance job — each job upserts a single row
export function recordRun({ dbPath, job, ok, message = "" }) {
  const db = new Database(dbPath);

  db.prepare(`
    INSERT INTO maintenance_runs (job, last_run_at, ok, message)
    VALUES (?, datetime('now','localtime'), ?, ?)
    ON CONFLICT(job) DO UPDATE SET
      last_run_at = excluded.last_run_at,
      ok = excluded.ok,
      message = excluded.message
  `).run(job, ok ? 1 : 0, message);

  db.close();
}