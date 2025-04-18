# Airline Reservation System

A web application for airline reservation management using JSP, JDBC, and MySQL.

## Features

- User authentication with User ID and password
- Different user roles (Customer, Admin, Customer Representative)
- Flight management
- Ticket booking and tracking
- Session management
- User logout
- Dashboard for authenticated users

## Project Structure

```
src/
├── main/
│   ├── java/
│   │   └── com/
│   │       └── auth/
│   │           ├── DatabaseConnection.java
│   │           ├── User.java
│   │           └── UserDAO.java
│   └── webapp/
│       ├── WEB-INF/
│       │   └── web.xml
│       ├── dashboard.jsp
│       ├── index.jsp
│       ├── login.jsp
│       ├── loginProcess.jsp
│       └── logout.jsp
└── database_setup.sql
```

## Prerequisites

- Java JDK 8 or higher
- Apache Tomcat 9.x
- MySQL 5.7 or higher
- Maven (optional, for building)

## Database Schema

The database includes tables for:
- User: Basic user information
- Customer, Admin, Customer_Rep: Different user roles
- Airline, Airport, Aircraft: Basic travel entities
- Flight, Seat: Flight and seating information
- Ticket, Travel: Booking and travel records

## Database Setup

1. Install MySQL if you haven't already.
2. Create the database and tables using the SQL script:
   ```
   mysql -u root -p < database_setup.sql
   ```
   This will create a database called `userdb` with the airline reservation system schema.

## Running the Application

### Using an IDE (Eclipse, IntelliJ IDEA)

1. Import the project as a web application
2. Configure Tomcat server
3. Add the MySQL JDBC driver to the classpath
4. Run the application on the Tomcat server

### Using Tomcat Directly

1. Build the project to create a WAR file
2. Deploy the WAR file to Tomcat's `webapps` directory
3. Start Tomcat
4. Access the application at `http://localhost:8080/airline`

## User Authentication

To login, use:
- User ID field: Enter your user_id
- Password field: Enter your password

## Security Notes

- This is a simple demonstration application
- In a production environment, passwords should be hashed (using bcrypt or similar)
- Additional security measures like HTTPS, CSRF protection, etc. should be implemented
- Input validation should be added to prevent SQL injection