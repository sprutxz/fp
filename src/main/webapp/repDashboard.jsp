<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Check if user is logged in and is a customer rep
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String userRole = (String) session.getAttribute("userRole");
    if (!"customer_rep".equals(userRole)) {
        response.sendRedirect("dashboard.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Customer Rep Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5; }
        .container { max-width: 1000px; margin: 50px auto; padding: 20px; background-color: white; border-radius: 5px; box-shadow: 0 0 10px rgba(0, 0, 0, 0.1); }
        header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; border-bottom: 1px solid #eee; padding-bottom: 10px; }
        h1 { color: #333; margin: 0; }
        .user-info { display: flex; align-items: center; }
        .username { margin-right: 15px; font-weight: bold; }
        .logout-button { padding: 8px 16px; background-color: #f44336; color: white; text-decoration: none; border-radius: 4px; }
        .logout-button:hover { background-color: #d32f2f; }
        .dashboard-cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 20px; margin-top: 20px; }
        .card { background-color: #f9f9f9; border-radius: 5px; padding: 20px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); transition: transform 0.3s ease, box-shadow 0.3s ease; }
        .card:hover { transform: translateY(-5px); box-shadow: 0 5px 15px rgba(0,0,0,0.1); }
        .card h3 { margin-top: 0; color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        .card p { color: #666; margin-bottom: 20px; }
        .button { display: inline-block; padding: 8px 16px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 4px; transition: background-color 0.3s ease; }
        .button:hover { background-color: #45a049; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Customer Rep Dashboard</h1>
            <div class="user-info">
                <span class="username">Welcome, <%= session.getAttribute("firstName") %> <%= session.getAttribute("lastName") %>!</span>
                <a href="logout.jsp" class="logout-button">Logout</a>
            </div>
        </header>
        <div class="content">
            <h2>Representative Functions</h2>
            <div class="dashboard-cards">
                <div class="card">
                    <h3>Flight Reservations</h3>
                    <p>Make or edit reservations on behalf of users.</p>
                    <a href="repFlightReservations.jsp" class="button">Manage Reservations</a>
                </div>
                <div class="card">
                    <h3>Aircraft Management</h3>
                    <p>Add, edit, or delete aircraft information.</p>
                    <a href="manageAircraft.jsp" class="button">Manage Aircraft</a>
                </div>
                <div class="card">
                    <h3>Airport Management</h3>
                    <p>Add, edit, or delete airport information.</p>
                    <a href="manageAirports.jsp" class="button">Manage Airports</a>
                </div>
                <div class="card">
                    <h3>Flight Management</h3>
                    <p>Add, edit, or delete flight schedules.</p>
                    <a href="manageFlights.jsp" class="button">Manage Flights</a>
                </div>
                <div class="card">
                    <h3>Waiting List</h3>
                    <p>View all passengers on a specific flight's waiting list.</p>
                    <a href="waitingListByFlight.jsp" class="button">View Waiting List</a>
                </div>
                <div class="card">
                    <h3>Airport Flights</h3>
                    <p>List all flights departing from or arriving at an airport.</p>
                    <a href="airportFlights.jsp" class="button">View Flights by Airport</a>
                </div>
                <div class="card">
                    <h3>Q&A Management</h3>
                    <p>Reply to customer questions.</p>
                    <a href="repQnA.jsp" class="button">Manage Q&A</a>
                </div>
            </div>
        </div>
    </div>
</body>
</html> 