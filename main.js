const express = require('express');

// Create an instance of the Express app
const app = express();

// Define a route
app.get('/', (req, res) => {
  res.send('Hello, world! Testing from Github #2');
});

// Start the server
app.listen(3000, () => {
  console.log('Server is running on http://localhost:3000');
});
