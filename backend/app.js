const express = require("express");
const { Pool } = require("pg");
const cors = require("cors");
const AWS = require("aws-sdk"); // Add this line for AWS SDK

const corsOptions = {
  origin: "http://localhost:5173",
};
process.env.AWS_SDK_LOAD_CONFIG = "1";

const port = 3000;
const app = express();
app.use(cors(corsOptions));
app.use(express.json());

AWS.config.update({
  accessKeyId: "ASIATQZ4JQQTEDYSOIY3",
  secretAccessKey: "5b50gMeFMUAVjIB7WpNH8rkkLoKHX8bBLslDcPR3",
  sessionToken:
    "IQoJb3JpZ2luX2VjEGkaCXVzLXdlc3QtMiJGMEQCIGS0a2iAfjaxXWH7ml1WdbQ69ADLLSdZhjm36Sp8SN6TAiAgUhSOyPWqyaQPq8kuGxppNtr1S44782y8zPhQdaCR9yqsAgiy//////////8BEAAaDDI0MjI1NTIzNDA4NiIMzfsrh/pO3gBSaMX8KoACUGCpCHJ82L/qnWw08LEtlyLhlHWdLaoGWgnUslCD/aiVGYXLdhlUm0M8SM3GeH7kpcSEnkp5BeUzdBvQIOOdVovkxp/MVTV4UkSjh5rCfdxIlhEsJxKjQ5YNXsMhAglVBNTI4CteJDfDEHOluGW+EnhI2bvTxNNBj1CG4y/bxy3PuNDHQ2Z/1PNcrKRhFVZ7TkVsxj9lCbHK1CnohNi6SUFDfbuiWKDbZKwNUXN29FXWx5hVgzOsl430FqRdXmdHdpr4jxnuOUXVwvXW0FknGmPs0Xm90uEZtL2ldiM5AZaBeN+tXV75s5G7H71iYsjNLYjdi7tpcN+/PJoiXp0g8TCQ1ve3BjqeAUnBhopgxtQIHcyM+k/5fIllyDZzY0azcBMNi76VTJpu0uf5KmRzHz8ZlCaSzekUkukYtVLU5b5uXBbs4gO2+AsXxQbnvJ+IlJdpEx+/HbVjOPlHjcomFKHOmRDujQU6MI1hvkew9aFqDxpJLrX0BU6iG8pgeb3NiekU4nCCYNbibhSRYoolIihobChJ+Ws5rmgQFLfPubWTqxrqSJiL",
  region: "us-east-1", // Change to your AWS region
});

const sns = new AWS.SNS(); // Create SNS instance

// Database connection pool
const pool = new Pool({
  user: "root",
  host: "db", // the service name of the database in docker-compose.yml
  database: "test_db",
  password: "root",
  port: 5432, // Default PostgreSQL port
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
app.use("/api/tasks", taskRoutes(pool));
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
