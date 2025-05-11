<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Check if user is logged in and is an admin
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    String userRole = (String) session.getAttribute("userRole");
    if (!"admin".equals(userRole)) {
        response.sendRedirect("dashboard.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Admin Dashboard</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1000px;
            margin: 50px auto;
            padding: 20px;
            background-color: white;
            border-radius: 5px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }
        header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        h1 {
            color: #333;
            margin: 0;
        }
        .user-info {
            display: flex;
            align-items: center;
        }
        .username {
            margin-right: 15px;
            font-weight: bold;
        }
        .logout-button {
            padding: 8px 16px;
            background-color: #f44336;
            color: white;
            text-decoration: none;
            border-radius: 4px;
        }
        .logout-button:hover {
            background-color: #d32f2f;
        }
        .admin-functions {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        .admin-card {
            background-color: #f9f9f9;
            border-radius: 5px;
            padding: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        .admin-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        .admin-card h3 {
            margin-top: 0;
            color: #2c3e50;
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        .admin-card p {
            color: #666;
            margin-bottom: 20px;
        }
        .button {
            display: inline-block;
            padding: 8px 16px;
            background-color: #4CAF50;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            transition: background-color 0.3s ease;
        }
        .button:hover {
            background-color: #45a049;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Admin Dashboard</h1>
            <div class="user-info">
                <span class="username">Welcome, <%= session.getAttribute("firstName") %> <%= session.getAttribute("lastName") %>!</span>
                <a href="logout.jsp" class="logout-button">Logout</a>
            </div>
        </header>
        
        <div class="content">
            <h2>Administrative Functions</h2>
            <p>As an administrator, you have access to the following management functions:</p>
            
            <div class="admin-functions">
                <div class="admin-card">
                    <h3>User Management</h3>
                    <p>Add, edit, or delete customer representatives and customers.</p>
                    <a href="adminUserManagement.jsp" class="button">Manage Users</a>
                </div>
                
                <div class="admin-card">
                    <h3>Monthly Sales Reports</h3>
                    <p>View detailed sales reports for any month.</p>
                    <a href="adminSalesReport.jsp" class="button">View Reports</a>
                </div>
                
                <div class="admin-card">
                    <h3>Reservation Lists</h3>
                    <p>Find reservations by flight number or customer name.</p>
                    <a href="adminReservations.jsp" class="button">View Reservations</a>
                </div>
                
                <div class="admin-card">
                    <h3>Revenue Summary</h3>
                    <p>Generate revenue reports by flight, airline, or customer.</p>
                    <a href="adminRevenue.jsp" class="button">Revenue Analytics</a>
                </div>
                
                <div class="admin-card">
                    <h3>Top Customers</h3>
                    <p>Identify customers who generate the most revenue.</p>
                    <a href="adminTopCustomers.jsp" class="button">View Top Customers</a>
                </div>
                
                <div class="admin-card">
                    <h3>Active Flights</h3>
                    <p>See which flights have the most tickets sold.</p>
                    <a href="adminActiveFlights.jsp" class="button">View Active Flights</a>
                </div>
            </div>
        </div>
    </div>
</body>
</html> 