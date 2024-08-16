const sqlite3 = require('sqlite3').verbose();

// Create a new database file or open it if it already exists
const db = new sqlite3.Database('./cranecorp.db', sqlite3.OPEN_READWRITE | sqlite3.OPEN_CREATE, (err) => {
  if (err) {
    console.error(err.message);
  } else {
    console.log('Connected to the cranecorp.db database.');
  }
});

module.exports = db;