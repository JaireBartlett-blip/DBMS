// mysql.js - The Database Connection Pool Module
const mysql = require('mysql2/promise'); 

// Connection configuration settings
const dbConfig = {
    host: "localhost",
    user: "root",
    password: "password", // Replace with your actual MySQL root password
    database: "hw5",      // Replace with your actual database name
    waitForConnections: true,
    connectionLimit: 10,             // Recommended pool setting from your lecture slides
    queueLimit: 0
};

// Create the connection pool
const pool = mysql.createPool(dbConfig);

// Export the pool so server.js can import it using require('./mysql')
module.exports = pool;
