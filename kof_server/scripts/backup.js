import "dotenv/config";
import fs from "fs";
import path from "path";
import Database from "better-sqlite3";
import { recordRun } from "../src/maintenance.js";

const DB_PATH = process.env.KOF_DB_PATH || "kof.sqlite";
const BACKUP_DIR = process.env.KOF_BACKUP_DIR || "backups";
const KEEP_DAYS = Number(process.env.KOF_BACKUP_KEEP_DAYS || 30);

const pad = (value) => String(value).padStart(2, "0");

function timestamp() {
  const now = new Date();
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}_${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;
}

function recordBackupResult(ok, message) {
  try {
    recordRun({ dbPath: DB_PATH, job: "backup", ok, message });
  } catch {}
}

// Prune backup files older than KEEP_DAYS.
function cleanupOldBackups() {
  if (!Number.isFinite(KEEP_DAYS) || KEEP_DAYS <= 0) {
    console.log("Backup retention disabled (KOF_BACKUP_KEEP_DAYS <= 0).");
    return;
  }

  const cutoff = Date.now() - KEEP_DAYS * 24 * 60 * 60 * 1000;
  const files = fs.readdirSync(BACKUP_DIR)
    .filter((file) => file.startsWith("kof_") && file.endsWith(".sqlite"))
    .map((file) => ({
      file,
      fullPath: path.join(BACKUP_DIR, file),
      mtime: fs.statSync(path.join(BACKUP_DIR, file)).mtimeMs,
    }));

  for (const file of files) {
    if (file.mtime < cutoff) {
      console.log("Deleting old backup:", file.file);
      fs.unlinkSync(file.fullPath);
    }
  }
}

fs.mkdirSync(BACKUP_DIR, { recursive: true });

if (!fs.existsSync(DB_PATH)) {
  recordBackupResult(false, `Database file not found: ${DB_PATH}`);
  console.error("Database file not found:", DB_PATH);
  process.exit(1);
}

console.log("Opening database:", DB_PATH);

const db = new Database(DB_PATH, { readonly: true });
const backupPath = path.join(BACKUP_DIR, `kof_${timestamp()}.sqlite`);

console.log("Creating backup:", backupPath);

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
