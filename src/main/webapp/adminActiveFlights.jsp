<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.auth.DatabaseConnection" %>
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
    
    // Initialize variables
    List<Map<String, Object>> activeFlights = new ArrayList<>();
    String message = "";
    String messageType = "";
    
    // Get filter parameters
    String timeFrame = request.getParameter("timeFrame");
    if (timeFrame == null) {
        timeFrame = "all"; // Default to all time
    }
    
    String airlineId = request.getParameter("airlineId");
    
    int limit = 25; // Default limit
    try {
        String limitParam = request.getParameter("limit");
        if (limitParam != null && !limitParam.isEmpty()) {
            limit = Integer.parseInt(limitParam);
        }
    } catch (NumberFormatException e) {
        // Use default limit if invalid
    }
    
    // Get list of airlines for filter dropdown
    List<Map<String, String>> airlines = new ArrayList<>();
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = DatabaseConnection.getConnection();
        
        // Get airlines first
        String sqlAirlines = "SELECT airline_id, airline_name FROM Airline ORDER BY airline_name";
        pstmt = conn.prepareStatement(sqlAirlines);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, String> airline = new HashMap<>();
            airline.put("airlineId", rs.getString("airline_id"));
            airline.put("airlineName", rs.getString("airline_name"));
            airlines.add(airline);
        }
        
        rs.close();
        pstmt.close();
        
        // SQL query with date and airline filtering
        String dateFilter = "";
        if ("month".equals(timeFrame)) {
            dateFilter = "AND YEAR(t.date) = YEAR(CURRENT_DATE) AND MONTH(t.date) = MONTH(CURRENT_DATE)";
        } else if ("year".equals(timeFrame)) {
            dateFilter = "AND YEAR(t.date) = YEAR(CURRENT_DATE)";
        }
        
        String airlineFilter = "";
        if (airlineId != null && !airlineId.isEmpty()) {
            airlineFilter = "AND f.airline_id = ?";
        }
        
        String sql = "SELECT f.flight_number, f.airline_id, a.airline_name, " +
                    "f.dep_airport_id, f.arr_airport_id, f.flight_type, " +
                    "COUNT(t.ticket_id) as ticket_count, SUM(t.fare) as total_revenue " +
                    "FROM Flight f " +
                    "JOIN Travel tr ON f.flight_number = tr.flight_number " +
                    "JOIN Ticket t ON tr.user_id = t.user_id AND tr.seat_no = t.seat_no AND tr.aircraft_id = t.aircraft_id " +
                    "JOIN Airline a ON f.airline_id = a.airline_id " +
                    "WHERE 1=1 " + dateFilter + " " + airlineFilter + " " +
                    "GROUP BY f.flight_number, f.airline_id, a.airline_name, f.dep_airport_id, f.arr_airport_id, f.flight_type " +
                    "ORDER BY ticket_count DESC " +
                    "LIMIT ?";
        
        pstmt = conn.prepareStatement(sql);
        
        int paramIndex = 1;
        if (airlineId != null && !airlineId.isEmpty()) {
            pstmt.setString(paramIndex++, airlineId);
        }
        pstmt.setInt(paramIndex, limit);
        
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> flight = new HashMap<>();
            flight.put("flightNumber", rs.getString("flight_number"));
            flight.put("airlineId", rs.getString("airline_id"));
            flight.put("airlineName", rs.getString("airline_name"));
            flight.put("depAirport", rs.getString("dep_airport_id"));
            flight.put("arrAirport", rs.getString("arr_airport_id"));
            flight.put("flightType", rs.getString("flight_type"));
            flight.put("ticketCount", rs.getInt("ticket_count"));
            flight.put("totalRevenue", rs.getDouble("total_revenue"));
            activeFlights.add(flight);
        }
        
        if (activeFlights.isEmpty()) {
            message = "No flight data found for the selected filters.";
            messageType = "info";
        }
        
    } catch (Exception e) {
        message = "Error retrieving active flights: " + e.getMessage();
        messageType = "error";
    } finally {
        try {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            if (conn != null) conn.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    
    // Calculate totals
    int totalTickets = 0;
    double totalRevenue = 0;
    for (Map<String, Object> flight : activeFlights) {
        totalTickets += (Integer) flight.get("ticketCount");
        totalRevenue += (Double) flight.get("totalRevenue");
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Most Active Flights</title>
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
        h1, h2 {
            color: #333;
        }
        .back-button {
            padding: 8px 16px;
            background-color: #3498db;
            color: white;
            text-decoration: none;
            border-radius: 4px;
        }
        .back-button:hover {
            background-color: #2980b9;
        }
        .filter-form {
            background-color: #f9f9f9;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
            display: flex;
            flex-wrap: wrap;
            align-items: flex-end;
        }
        .form-group {
            margin-right: 20px;
            margin-bottom: 10px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
        }
        select, input[type="number"] {
            padding: 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
            min-width: 100px;
        }
        .button {
            display: inline-block;
            padding: 8px 16px;
            background-color: #4CAF50;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            border: none;
            cursor: pointer;
        }
        .button:hover {
            background-color: #45a049;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            padding: 12px 15px;
            border-bottom: 1px solid #ddd;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
            font-weight: bold;
        }
        tr:hover {
            background-color: #f9f9f9;
        }
        .summary-box {
            background-color: #f9f9f9;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
        }
        .summary-item {
            text-align: center;
            flex: 1;
        }
        .summary-item h3 {
            margin-top: 0;
            color: #333;
        }
        .summary-value {
            font-size: 24px;
            font-weight: bold;
            color: #2c3e50;
        }
        .message {
            padding: 10px;
            margin-bottom: 20px;
            border-radius: 4px;
        }
        .success {
            background-color: #dff0d8;
            color: #3c763d;
        }
        .error {
            background-color: #f2dede;
            color: #a94442;
        }
        .info {
            background-color: #d9edf7;
            color: #31708f;
        }
        .activity-bar {
            height: 20px;
            background-color: #3498db;
            border-radius: 10px;
            margin-top: 5px;
        }
        .activity-cell {
            width: 25%;
        }
        .bar-container {
            width: 100%;
            background-color: #eee;
            border-radius: 10px;
        }
        .route {
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Most Active Flights</h1>
            <a href="adminDashboard.jsp" class="back-button">Back to Dashboard</a>
        </header>
        
        <% if (!message.isEmpty()) { %>
            <div class="message <%= messageType %>">
                <%= message %>
            </div>
        <% } %>
        
        <div class="filter-form">
            <form method="get">
                <div class="form-group">
                    <label for="timeFrame">Time Frame</label>
                    <select id="timeFrame" name="timeFrame">
                        <option value="all" <%= "all".equals(timeFrame) ? "selected" : "" %>>All Time</option>
                        <option value="year" <%= "year".equals(timeFrame) ? "selected" : "" %>>This Year</option>
                        <option value="month" <%= "month".equals(timeFrame) ? "selected" : "" %>>This Month</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label for="airlineId">Airline</label>
                    <select id="airlineId" name="airlineId">
                        <option value="">All Airlines</option>
                        <% for (Map<String, String> airline : airlines) { %>
                            <option value="<%= airline.get("airlineId") %>" <%= airline.get("airlineId").equals(airlineId) ? "selected" : "" %>>
                                <%= airline.get("airlineName") %> (<%= airline.get("airlineId") %>)
                            </option>
                        <% } %>
                    </select>
                </div>
                
                <div class="form-group">
                    <label for="limit">Number of Flights</label>
                    <input type="number" id="limit" name="limit" value="<%= limit %>" min="5" max="100">
                </div>
                
                <div class="form-group">
                    <button type="submit" class="button">Apply Filters</button>
                </div>
            </form>
        </div>
        
        <div class="summary-box">
            <div class="summary-item">
                <h3>Total Flights</h3>
                <div class="summary-value"><%= activeFlights.size() %></div>
            </div>
            <div class="summary-item">
                <h3>Total Tickets</h3>
                <div class="summary-value"><%= totalTickets %></div>
            </div>
            <div class="summary-item">
                <h3>Total Revenue</h3>
                <div class="summary-value">$<%= String.format("%.2f", totalRevenue) %></div>
            </div>
        </div>
        
        <% if (!activeFlights.isEmpty()) { %>
            <table>
                <thead>
                    <tr>
                        <th>Rank</th>
                        <th>Flight</th>
                        <th>Route</th>
                        <th>Airline</th>
                        <th class="activity-cell">Activity</th>
                        <th>Revenue</th>
                    </tr>
                </thead>
                <tbody>
                    <% 
                        // Get max tickets for scaling bars
                        int maxTickets = (Integer) activeFlights.get(0).get("ticketCount");
                        
                        for (int i = 0; i < activeFlights.size(); i++) {
                            Map<String, Object> flight = activeFlights.get(i);
                            int ticketCount = (Integer) flight.get("ticketCount");
                            int barWidth = (int) ((double) ticketCount / maxTickets * 100);
                    %>
                        <tr>
                            <td><%= i+1 %></td>
                            <td>
                                <a href="adminRevenue.jsp?reportType=flight&reportValue=<%= flight.get("flightNumber") %>">
                                    <%= flight.get("flightNumber") %>
                                </a>
                                <div><small><%= flight.get("flightType") %></small></div>
                            </td>
                            <td class="route"><%= flight.get("depAirport") %> → <%= flight.get("arrAirport") %></td>
                            <td><%= flight.get("airlineName") %> (<%= flight.get("airlineId") %>)</td>
                            <td class="activity-cell">
                                <%= ticketCount %> tickets
                                <div class="bar-container">
                                    <div class="activity-bar" style="width: <%= barWidth %>%;"></div>
                                </div>
                            </td>
                            <td>$<%= String.format("%.2f", flight.get("totalRevenue")) %></td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
        <% } %>
    </div>
</body>
</html> 