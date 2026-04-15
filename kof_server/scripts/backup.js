import "dotenv/config";
import fs from "fs";
import path from "path";
import Database from "better-sqlite3";
import { recordRun } from "../src/maintenance.js";

// Configuration for SQLite backups and retention cleanup of old backup files.
const DB_PATH = process.env.KOF_DB_PATH || "kof.sqlite";
const BACKUP_DIR = process.env.KOF_BACKUP_DIR || "backups";
const KEEP_DAYS = Number(process.env.KOF_BACKUP_KEEP_DAYS || 30);

// Pad numeric date parts to two digits for timestamped backup file names.
function pad(value) {
  return String(value).padStart(2, "0");
}

// Build a local timestamp suitable for unique backup file names.
function timestamp() {
  const now = new Date();

  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}_${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;
}

// Record the final backup job result without allowing maintenance logging
// errors to crash the script.
function recordBackupResult(ok, message) {
  try {
    recordRun({ dbPath: DB_PATH, job: "backup", ok, message });
  } catch {}
}

// Delete backup files older than the configured retention period.
function cleanupOldBackups() {
  if (!Number.isFinite(KEEP_DAYS) || KEEP_DAYS <= 0) {
    console.log("Backup retention disabled (KOF_BACKUP_KEEP_DAYS <= 0).");
    return;
  }

  const files = fs.readdirSync(BACKUP_DIR)
    .filter((file) => file.startsWith("kof_") && file.endsWith(".sqlite"))
    .map((file) => {
      const fullPath = path.join(BACKUP_DIR, file);

      return {
        file,
        fullPath,
        mtime: fs.statSync(fullPath).mtimeMs,
      };
    })
    .sort((a, b) => b.mtime - a.mtime);

  const cutoff = Date.now() - KEEP_DAYS * 24 * 60 * 60 * 1000;

  for (const file of files) {
    if (file.mtime < cutoff) {
      console.log("Deleting old backup:", file.file);
      fs.unlinkSync(file.fullPath);
    }
  }
}

// Ensure the backup directory exists before writing backup files into it.
fs.mkdirSync(BACKUP_DIR, { recursive: true });

// Fail fast when the configured database file does not exist.
if (!fs.existsSync(DB_PATH)) {
  recordBackupResult(false, `Database file not found: ${DB_PATH}`);
  console.error("Database file not found:", DB_PATH);
  process.exit(1);
}

console.log("Opening database:", DB_PATH);

const db = new Database(DB_PATH, { readonly: true });
const backupPath = path.join(BACKUP_DIR, `kof_${timestamp()}.sqlite`);

console.log("Creating backup:", backupPath);

// Run a safe SQLite backup and then prune old backup files according to the
// configured retention period.
db.backup(backupPath)
  .then(() => {
    try {
      console.log("Backup successful.");
      db.close();
      cleanupOldBackups();
      recordBackupResult(true, `Backup created: ${backupPath}`);
      console.log("Cleanup complete.");
      process.exit(0);
    } catch (error) {
      recordBackupResult(false, `Backup cleanup failed: ${error.message}`);
      console.error("Backup cleanup failed:", error);
      process.exit(1);
    }
  })
  .catch((error) => {
    try {
      db.close();
    } catch {}

    recordBackupResult(false, `Backup failed: ${error.message}`);
    console.error("Backup failed:", error);
    process.exit(1);
  });
