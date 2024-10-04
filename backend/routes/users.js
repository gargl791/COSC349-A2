const express = require("express");
const router = express.Router();
const bcrypt = require("bcryptjs");
const saltRounds = 10;

module.exports = (pool, sns) => {
  // Create a new user
  router.post("/", async (req, res) => {
    const { username, email, password } = req.body;
    try {
      const salt = await bcrypt.genSalt(saltRounds);
      const password_hash = await bcrypt.hash(password, salt);

      // Insert the new user into the database
      const newUser = await pool.query(
        "INSERT INTO users (username, email, password_hash) VALUES ($1, $2, $3) RETURNING *",
        [username, email, password_hash]
      );

      // Subscribe the user's email to the SNS topic
      const subscribeParams = {
        Protocol: "email", // Specify the protocol
        TopicArn: "arn:aws:sns:us-east-1:242255234086:todoey-email", // Update with your SNS Topic ARN
        Endpoint: email, // The user's email address
      };

      console.log(`Subscribing ${email} to SNS topic...`);
      await sns.subscribe(subscribeParams).promise(); // Subscribe the user's email
      console.log(`Subscription request sent to ${email}.`);

      // After user creation, send a welcome email via SNS
      const publishParams = {
        Message: `Hello ${username}, welcome to our platform! Your account has been successfully created.`,
        Subject: "Welcome to Our Platform",
        TopicArn: "arn:aws:sns:us-east-1:242255234086:todoey-email", // Update with your SNS Topic ARN
      };

      console.log("Sending SNS notification...");
      await sns.publish(publishParams).promise(); // Send the SNS message
      console.log("SNS notification sent");

      res.json(newUser.rows[0]); // Return the newly created user
    } catch (err) {
      console.error(err.message);
      res.status(500).json("Server Error");
    }
  });

  // Get all users
  router.get("/", async (req, res) => {
    try {
      const allUsers = await pool.query("SELECT * FROM users");
      res.json(allUsers.rows);
    } catch (err) {
      console.error(err.message);
      res.status(500).json("Server Error");
    }
  });

  // Get a user by username
  router.get("/:username", async (req, res) => {
    const { username } = req.params;
    try {
      const user = await pool.query("SELECT * FROM users WHERE username = $1", [
        username,
      ]);

      if (user.rows.length === 0) {
        return res.status(404).json({ msg: "User not found" });
      }

      res.json(user.rows[0]);
    } catch (err) {
      console.error(err.message);
      res.status(500).json("Server Error");
    }
  });

  return router;
};
