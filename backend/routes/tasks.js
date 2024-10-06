const express = require("express");
const router = express.Router();

module.exports = (pool, sns) => {
    // Create a new task
    router.post("/", async (req, res) => {
        const { userId, title, startDate, endDate, priority, tags } = req.body;
        console.log("backend req: ", req.body);
        try {
            const newTask = await pool.query(
                "INSERT INTO tasks (user_id, title, start_date, end_date, priority, tags) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *",
                [userId, title, startDate, endDate, priority, tags]
            );
            console.log("Task successfully created to db");
            res.json(newTask.rows[0]);

            // This obtains the user needed to make the email.
            const userResult = await pool.query('SELECT * FROM users WHERE user_id = $1', [userId]);
            if (userResult.rows.length === 0) {
                return res.status(404).json({ error: 'User not found' });
            }
            const user = userResult.rows[0]; // user details

            const publishParams = {
                Message: `Hello ${user.username},\n\nYour task of "${title}" has been successfully created at ${startDate}.\nThe task's due date is ${endDate}.\n\nTags: ${tags}\nPriority: ${priority}\n\nGood luck!\n\nRegards,\nThe Todoey Team`,
                Subject: `Your Todoey Task: ${title}`,
                TopicArn: process.env.TOPIC_ARN, // Update with your SNS Topic ARN
                MessageAttributes: {
                    EmailAddress: {
                        DataType: "String",
                        StringValue: user.email, // Add the email address as a message attribute
                    },
                },
            };

            console.log("Sending SNS notification...");
            await sns.publish(publishParams).promise(); // Send the SNS message
            console.log("SNS notification sent");
        } catch (err) {
            console.error(err.message);
            res.status(500).json("Server Error");
        }
    });

    // Get all tasks
    router.get("/", async (req, res) => {
        try {
            const allTasks = await pool.query("SELECT * FROM tasks");
            res.json(allTasks.rows);
        } catch (err) {
            console.error(err.message);
            res.status(500).json("Server Error");
        }
    });

    // Get all tasks for a specific user
    router.get("/:userId", async (req, res) => {
        const { userId } = req.params;
        try {
            const userTasks = await pool.query(
                "SELECT * FROM tasks WHERE user_id = $1",
                [userId]
            );
            res.json(userTasks.rows);
        } catch (err) {
            console.error(err.message);
            res.status(500).json("Server Error");
        }
    });

    // Update a task
    router.put("/:taskId", async (req, res) => {
        console.log("tasks.js: ", req);
        const { taskId } = req.params;
        const { title, startDate, endDate, priority, tags } = req.body;
        try {
            const updateTask = await pool.query(
                "UPDATE tasks SET title = $1, start_date = $2, end_date = $3, priority = $4, tags = $5 WHERE task_id = $6 RETURNING *",
                [title, startDate, endDate, priority, tags, taskId]
            );
            if (updateTask.rows.length === 0) {
                return res.status(404).json("Task not found");
            }
            res.json(updateTask.rows[0]);
        } catch (err) {
            console.error(err.message);
            res.status(500).json("Server Error");
        }
    });

    // Delete a task
    router.delete("/:taskId", async (req, res) => {
        const { taskId } = req.params;
        try {
            const deleteTask = await pool.query(
                "DELETE FROM tasks WHERE task_id = $1 RETURNING *",
                [taskId]
            );
            if (deleteTask.rows.length === 0) {
                return res.status(404).json("Task not found");
            }
            res.json("Task deleted successfully");
        } catch (err) {
            console.error(err.message);
            res.status(500).json("Server Error");
        }
    });


    return router;
};
