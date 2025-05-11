<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Check if user is logged in
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Customer Dashboard</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 800px;
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
        .button {
            padding: 8px 16px;
            background-color: #4CAF50;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            margin-top: 15px;
            display: inline-block;
            margin-right: 10px;
        }
        .button:hover {
            background-color: #45a049;
        }
        .content {
            padding: 20px 0;
        }
        .dashboard-cards {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
            margin-top: 20px;
        }
        .card {
            background-color: #f9f9f9;
            border-radius: 5px;
            padding: 15px;
            flex: 1 0 200px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .card h3 {
            margin-top: 0;
            color: #333;
        }
        .card p {
            color: #666;
            margin-bottom: 15px;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Customer Dashboard</h1>
            <div class="user-info">
                <span class="username">Welcome, <%= session.getAttribute("firstName") %> <%= session.getAttribute("lastName") %>!</span>
                <a href="logout.jsp" class="logout-button">Logout</a>
            </div>
        </header>
        <div class="content">
            <h2>Flight Management</h2>
            <p>Welcome to your flight management dashboard. From here, you can search for flights, make reservations, and manage your bookings.</p>
            
            <div class="dashboard-cards">
                <div class="card">
                    <h3>Find Flights</h3>
                    <p>Search for flights based on your travel preferences.</p>
                    <a href="flightSearch.jsp" class="button">Search Flights</a>
                </div>
                
                <div class="card">
                    <h3>Upcoming Flights</h3>
                    <p>View all your upcoming flight reservations.</p>
                    <a href="upcomingFlights.jsp" class="button">View Upcoming</a>
                </div>
                
                <div class="card">
                    <h3>Past Flights</h3>
                    <p>Access your flight history and past reservations.</p>
                    <a href="pastFlights.jsp" class="button">View History</a>
                </div>
                
                <div class="card">
                    <h3>Manage Bookings</h3>
                    <p>Cancel eligible reservations (Business/First Class).</p>
                    <a href="manageBookings.jsp" class="button">Manage</a>
                </div>
                
                <div class="card">
                    <h3>Waiting Lists</h3>
                    <p>Check your waiting list status for full flights.</p>
                    <a href="waitingList.jsp" class="button">View Status</a>
                </div>

                <div class="card">
                    <h3>My Q&A</h3>
                    <p>Browse and search your questions and answers.</p>
                    <a href="qnaList.jsp" class="button">View Q&A</a>
                </div>
            </div>
        </div>
    </div>
</body>
</html>