const db = require('./db');

module.exports = (req, res) => {
  const query = req.body.query;
  console.log(`Received query request: ${query}`);

  db.serialize(() => {
    db.all(query, (err, rows) => {
      if (err) {
        console.error(`Query error: ${err}`);
        res.status(500).send(err.message);
      } else {
        console.log(`Query results: ${JSON.stringify(rows)}`);
        res.json(rows);
      }
    });
  });
};