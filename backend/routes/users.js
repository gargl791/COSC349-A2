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

      console.log(`User ${email} created successfully.`)

      const subscribeParams = {
        Protocol: "email",
        TopicArn: process.env.TOPIC_ARN,
        Endpoint: email,
        Attributes: {
          FilterPolicy: JSON.stringify({
            EmailAddress: [email] // Filter policy for this user's email
          })
        }
      };

      console.log(`Subscribing ${email} to SNS topic...`);
      await sns.subscribe(subscribeParams).promise(); // Subscribe the user's email
      console.log(`Subscription request sent to ${email}.`);
    
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

  router.get('/:userId', async (req, res) => {
    const { userId } = req.params;
  
    try {
      const result = await pool.query('SELECT * FROM users WHERE user_id = $1', [userId]);
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      res.json(result.rows[0]);
    } catch (err) {
      console.error(err.message);
      res.status(500).json({ error: 'Server error' });
    }
  });

  return router;
};
