const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const queryHandler = require('./queryHandler');

const app = express();
const port = 3000;

app.use(bodyParser.json());
app.use(cors());

app.post('/query', queryHandler);

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});