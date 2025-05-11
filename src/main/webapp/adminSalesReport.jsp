<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
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
    List<Map<String, Object>> monthlySales = new ArrayList<>();
    String message = "";
    String messageType = "";
    
    // Get filter parameters
    int year = Calendar.getInstance().get(Calendar.YEAR); // Default to current year
    int month = Calendar.getInstance().get(Calendar.MONTH) + 1; // Default to current month (1-12)
    
    // Parse request parameters if provided
    String yearParam = request.getParameter("year");
    String monthParam = request.getParameter("month");
    
    if (yearParam != null && !yearParam.isEmpty()) {
        try {
            year = Integer.parseInt(yearParam);
        } catch (NumberFormatException e) {
            // Use default current year if invalid
        }
    }
    
    if (monthParam != null && !monthParam.isEmpty()) {
        try {
            month = Integer.parseInt(monthParam);
            if (month < 1 || month > 12) {
                month = Calendar.getInstance().get(Calendar.MONTH) + 1;
            }
        } catch (NumberFormatException e) {
            // Use default current month if invalid
        }
    }
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = DatabaseConnection.getConnection();
        
        // Query to get total sales for the month
        String sql = "SELECT DAY(t.date) as day, COUNT(t.ticket_id) as tickets_sold, SUM(t.fare) as daily_revenue " +
                     "FROM Ticket t " +
                     "WHERE YEAR(t.date) = ? AND MONTH(t.date) = ? " +
                     "GROUP BY DAY(t.date) " +
                     "ORDER BY day";
        
        pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, year);
        pstmt.setInt(2, month);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> daySales = new HashMap<>();
            daySales.put("day", rs.getInt("day"));
            daySales.put("ticketsSold", rs.getInt("tickets_sold"));
            daySales.put("revenue", rs.getDouble("daily_revenue"));
            monthlySales.add(daySales);
        }
        
        if (monthlySales.isEmpty()) {
            message = "No sales data found for " + getMonthName(month) + " " + year + ".";
            messageType = "info";
        }
        
        // Get airline breakdown for the month
        rs.close();
        pstmt.close();
        
        sql = "SELECT a.airline_id, a.airline_name, COUNT(t.ticket_id) as tickets_sold, SUM(t.fare) as revenue " +
              "FROM Ticket t " +
              "JOIN Travel tr ON t.user_id = tr.user_id AND t.seat_no = tr.seat_no AND t.aircraft_id = tr.aircraft_id " +
              "JOIN Flight f ON tr.flight_number = f.flight_number " +
              "JOIN Airline a ON f.airline_id = a.airline_id " +
              "WHERE YEAR(t.date) = ? AND MONTH(t.date) = ? " +
              "GROUP BY a.airline_id, a.airline_name " +
              "ORDER BY revenue DESC";
        
        pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, year);
        pstmt.setInt(2, month);
        rs = pstmt.executeQuery();
        
        List<Map<String, Object>> airlineBreakdown = new ArrayList<>();
        while (rs.next()) {
            Map<String, Object> airline = new HashMap<>();
            airline.put("airlineId", rs.getString("airline_id"));
            airline.put("airlineName", rs.getString("airline_name"));
            airline.put("ticketsSold", rs.getInt("tickets_sold"));
            airline.put("revenue", rs.getDouble("revenue"));
            airlineBreakdown.add(airline);
        }
        
        request.setAttribute("airlineBreakdown", airlineBreakdown);
        
        // Get flight class breakdown for the month
        rs.close();
        pstmt.close();
        
        sql = "SELECT t.type, COUNT(t.ticket_id) as tickets_sold, SUM(t.fare) as revenue " +
              "FROM Ticket t " +
              "WHERE YEAR(t.date) = ? AND MONTH(t.date) = ? " +
              "GROUP BY t.type " +
              "ORDER BY revenue DESC";
        
        pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, year);
        pstmt.setInt(2, month);
        rs = pstmt.executeQuery();
        
        List<Map<String, Object>> classBreakdown = new ArrayList<>();
        while (rs.next()) {
            Map<String, Object> ticketClass = new HashMap<>();
            ticketClass.put("type", rs.getString("type"));
            ticketClass.put("ticketsSold", rs.getInt("tickets_sold"));
            ticketClass.put("revenue", rs.getDouble("revenue"));
            classBreakdown.add(ticketClass);
        }
        
        request.setAttribute("classBreakdown", classBreakdown);
        
    } catch (Exception e) {
        message = "Error retrieving sales data: " + e.getMessage();
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
    
    // Calculate monthly totals
    int totalTickets = 0;
    double totalRevenue = 0;
    for (Map<String, Object> day : monthlySales) {
        totalTickets += (Integer) day.get("ticketsSold");
        totalRevenue += (Double) day.get("revenue");
    }
    
    // Month name mapping
    String monthName = getMonthName(month);
    
    // Calculate previous and next month/year
    int prevMonth = month > 1 ? month - 1 : 12;
    int prevYear = month > 1 ? year : year - 1;
    int nextMonth = month < 12 ? month + 1 : 1;
    int nextYear = month < 12 ? year : year + 1;
%>

<%!
    // Method to get month name
    private String getMonthName(int month) {
        String[] monthNames = {"January", "February", "March", "April", "May", "June", 
                              "July", "August", "September", "October", "November", "December"};
        return monthNames[month - 1];
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Monthly Sales Report</title>
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
        h1, h2, h3 {
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
        .month-navigation {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
        .month-selector {
            text-align: center;
            flex-grow: 1;
        }
        .nav-button {
            padding: 8px 16px;
            background-color: #3498db;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            margin: 0 10px;
        }
        .nav-button:hover {
            background-color: #2980b9;
        }
        .summary-box {
            background-color: #f9f9f9;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-around;
        }
        .summary-item {
            text-align: center;
            padding: 0 15px;
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
        .breakdown-section {
            margin: 30px 0;
        }
        .two-column {
            display: flex;
            gap: 20px;
        }
        .column {
            flex: 1;
        }
        .chart {
            margin-top: 20px;
            height: 300px;
            border: 1px solid #ddd;
            border-radius: 4px;
            background-color: #f9f9f9;
            position: relative;
            overflow: hidden;
        }
        .bar {
            position: absolute;
            bottom: 0;
            width: 20px;
            background-color: #3498db;
            border-top-left-radius: 4px;
            border-top-right-radius: 4px;
            transition: height 0.3s ease;
        }
        .bar-label {
            position: absolute;
            bottom: -25px;
            text-align: center;
            width: 30px;
            font-size: 11px;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Monthly Sales Report</h1>
            <a href="adminDashboard.jsp" class="back-button">Back to Dashboard</a>
        </header>
        
        <% if (!message.isEmpty()) { %>
            <div class="message <%= messageType %>">
                <%= message %>
            </div>
        <% } %>
        
        <div class="month-navigation">
            <a href="?year=<%= prevYear %>&month=<%= prevMonth %>" class="nav-button">« Previous Month</a>
            <div class="month-selector">
                <h2><%= monthName %> <%= year %></h2>
            </div>
            <a href="?year=<%= nextYear %>&month=<%= nextMonth %>" class="nav-button">Next Month »</a>
        </div>
        
        <div class="summary-box">
            <div class="summary-item">
                <h3>Total Tickets Sold</h3>
                <div class="summary-value"><%= totalTickets %></div>
            </div>
            <div class="summary-item">
                <h3>Total Revenue</h3>
                <div class="summary-value">$<%= String.format("%.2f", totalRevenue) %></div>
            </div>
            <div class="summary-item">
                <h3>Daily Average</h3>
                <div class="summary-value">
                    <% if (!monthlySales.isEmpty()) { %>
                        $<%= String.format("%.2f", totalRevenue / monthlySales.size()) %>
                    <% } else { %>
                        $0.00
                    <% } %>
                </div>
            </div>
        </div>
        
        <% if (!monthlySales.isEmpty()) { %>
            <h2>Revenue Chart</h2>
            <p>Daily sales for <%= monthName %> <%= year %></p>
            
            <h2>Daily Breakdown</h2>
            <table>
                <thead>
                    <tr>
                        <th>Date</th>
                        <th>Tickets Sold</th>
                        <th>Revenue</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (Map<String, Object> day : monthlySales) { %>
                        <tr>
                            <td><%= monthName %> <%= day.get("day") %>, <%= year %></td>
                            <td><%= day.get("ticketsSold") %></td>
                            <td>$<%= String.format("%.2f", day.get("revenue")) %></td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
            
            <div class="breakdown-section two-column">
                <div class="column">
                    <h2>Sales by Airline</h2>
                    <table>
                        <thead>
                            <tr>
                                <th>Airline</th>
                                <th>Tickets</th>
                                <th>Revenue</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% 
                                List<Map<String, Object>> airlineBreakdown = 
                                    (List<Map<String, Object>>) request.getAttribute("airlineBreakdown");
                                
                                if (airlineBreakdown != null) {
                                    for (Map<String, Object> airline : airlineBreakdown) {
                            %>
                                <tr>
                                    <td><%= airline.get("airlineName") %> (<%= airline.get("airlineId") %>)</td>
                                    <td><%= airline.get("ticketsSold") %></td>
                                    <td>$<%= String.format("%.2f", airline.get("revenue")) %></td>
                                </tr>
                            <% 
                                    }
                                }
                            %>
                        </tbody>
                    </table>
                </div>
                
                <div class="column">
                    <h2>Sales by Class</h2>
                    <table>
                        <thead>
                            <tr>
                                <th>Class</th>
                                <th>Tickets</th>
                                <th>Revenue</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% 
                                List<Map<String, Object>> classBreakdown = 
                                    (List<Map<String, Object>>) request.getAttribute("classBreakdown");
                                
                                if (classBreakdown != null) {
                                    for (Map<String, Object> ticketClass : classBreakdown) {
                            %>
                                <tr>
                                    <td><%= ticketClass.get("type") %></td>
                                    <td><%= ticketClass.get("ticketsSold") %></td>
                                    <td>$<%= String.format("%.2f", ticketClass.get("revenue")) %></td>
                                </tr>
                            <% 
                                    }
                                }
                            %>
                        </tbody>
                    </table>
                </div>
            </div>
        <% } %>
    </div>
</body>
</html> 