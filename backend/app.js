const express = require("express");
const { Pool } = require("pg");
const cors = require("cors");
const AWS = require("aws-sdk"); // Add this line for AWS SDK

require('dotenv').config()


const corsOptions = {
  origin: process.env.CORS_ORIGIN,
};


process.env.AWS_SDK_LOAD_CONFIG = "1";

const port = parseInt(process.env.PORT, 10) || 3000;

const app = express();
app.use(cors(corsOptions));
app.use(express.json());

AWS.config.update({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  sessionToken: process.env.AWS_SESSION_TOKEN,
  region: "us-east-1",
});

const sns = new AWS.SNS(); // Create SNS instance

const pool = new Pool({
  user: process.env.PG_USER,
  host: process.env.PG_HOST,
  database: process.env.PG_DB,
  password: process.env.PG_PASSWORD,
  port: parseInt(process.env.PG_PORT, 10) || 5432,
  // ssl: {
  //   rejectUnauthorized: false // Change to true if you have valid SSL certificates
  // }
});

// Test the database connection
pool.connect((err, client, release) => {
  if (err) {
    return console.error("Error acquiring client", err.stack);
  }
  client.query("SELECT NOW()", (err, result) => {
    release();
    if (err) {
      return console.error("Error executing query", err.stack);
    }
    console.log("Connection successful:", result.rows);
  });
});

// Import routes
const userRoutes = require("./routes/users");
const taskRoutes = require("./routes/tasks");
const authRoutes = require("./routes/auth");
const categoryRoutes = require("./routes/categories");

// Use routes
app.use("/api/users", userRoutes(pool, sns)); // Pass the sns instance here
app.use("/api/tasks", taskRoutes(pool, sns));
app.use("/api/categories", categoryRoutes(pool));
app.use("/api/auth", authRoutes(pool));

// Catch-all route for undefined endpoints
app.use((req, res) => {
  res.status(404).json({ error: "Endpoint not found" });
});

app.get("/api", (req, res) => {
  res.json({ fruits: ["apple", "banana", "cherry"] });
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
