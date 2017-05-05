const express = require('express');
const app = express();

const port = process.env.APP_PORT || 3000;
const root = '/roasts';

const roasts = [
  {
    id: "light",
    type: "Light",
    origin: "Honduras"
  },
  {
    id: "medium",
    type: "Medium",
    origin: "Guatemala"
  },
  {
    id: "dark",
    type: "Dark",
    origin: "Columbia"
  }
];

app.get('/', (req, res) => {
  res.send("Roasts");
});

app.get(root, (req, res) => {
  res.send(roasts);
});

app.get(`${root}/:id`, (req, res) => {
  let id = req.params.id;
  let roast = roasts.find((roast) => {
    return roast.id === id;
  });

  if (!roast)
    return res.status(404).send();

  return res.send(roast);
});

app.listen(port);
console.log(`Listening on port: ${port}`);
