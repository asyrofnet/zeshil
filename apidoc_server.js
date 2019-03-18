const express = require('express');
const app = express();

const PORT = process.env.PORT || 3001;

app.use('/api-docs', express.static(__dirname + '/docs/apidoc'));
app.use('/', express.static(__dirname + '/docs/site'));

app.listen(PORT, () => {
  console.log(`Example app listening on port ${PORT}!`)
});