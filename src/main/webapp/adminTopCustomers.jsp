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
    List<Map<String, Object>> topCustomers = new ArrayList<>();
    String message = "";
    String messageType = "";
    
    // Get filter parameters
    String timeFrame = request.getParameter("timeFrame");
    if (timeFrame == null) {
        timeFrame = "all"; // Default to all time
    }
    
    int limit = 25; // Default limit
    try {
        String limitParam = request.getParameter("limit");
        if (limitParam != null && !limitParam.isEmpty()) {
            limit = Integer.parseInt(limitParam);
        }
    } catch (NumberFormatException e) {
        // Use default limit if invalid
    }
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = DatabaseConnection.getConnection();
        
        // SQL query with date filtering based on time frame
        String dateFilter = "";
        if ("month".equals(timeFrame)) {
            dateFilter = "AND YEAR(t.date) = YEAR(CURRENT_DATE) AND MONTH(t.date) = MONTH(CURRENT_DATE)";
        } else if ("year".equals(timeFrame)) {
            dateFilter = "AND YEAR(t.date) = YEAR(CURRENT_DATE)";
        }
        
        String sql = "SELECT u.user_id, u.first_name, u.last_name, " +
                    "COUNT(t.ticket_id) as ticket_count, " +
                    "SUM(t.fare) as total_revenue, " +
                    "MAX(t.date) as last_purchase " +
                    "FROM User u " +
                    "JOIN Ticket t ON u.user_id = t.user_id " +
                    "JOIN Customer c ON u.user_id = c.user_id " +
                    "WHERE 1=1 " + dateFilter + " " +
                    "GROUP BY u.user_id, u.first_name, u.last_name " +
                    "ORDER BY total_revenue DESC " +
                    "LIMIT ?";
        
        pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, limit);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> customer = new HashMap<>();
            customer.put("userId", rs.getString("user_id"));
            customer.put("firstName", rs.getString("first_name"));
            customer.put("lastName", rs.getString("last_name"));
            customer.put("ticketCount", rs.getInt("ticket_count"));
            customer.put("totalRevenue", rs.getDouble("total_revenue"));
            customer.put("lastPurchase", rs.getDate("last_purchase"));
            topCustomers.add(customer);
        }
        
        if (topCustomers.isEmpty()) {
            message = "No customer data found for the selected time frame.";
            messageType = "info";
        }
        
    } catch (Exception e) {
        message = "Error retrieving top customers: " + e.getMessage();
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
    
    // Calculate total revenue
    double totalRevenueAll = 0;
    for (Map<String, Object> customer : topCustomers) {
        totalRevenueAll += (Double) customer.get("totalRevenue");
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Top Revenue-Generating Customers</title>
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
        .revenue-bar {
            height: 20px;
            background-color: #3498db;
            border-radius: 10px;
            margin-top: 5px;
        }
        .revenue-cell {
            width: 30%;
        }
        .bar-container {
            width: 100%;
            background-color: #eee;
            border-radius: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Top Revenue-Generating Customers</h1>
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
                    <label for="limit">Number of Customers</label>
                    <input type="number" id="limit" name="limit" value="<%= limit %>" min="5" max="100">
                </div>
                
                <div class="form-group">
                    <button type="submit" class="button">Apply Filters</button>
                </div>
            </form>
        </div>
        
        <div class="summary-box">
            <div class="summary-item">
                <h3>Total Customers</h3>
                <div class="summary-value"><%= topCustomers.size() %></div>
            </div>
            <div class="summary-item">
                <h3>Total Revenue</h3>
                <div class="summary-value">$<%= String.format("%.2f", totalRevenueAll) %></div>
            </div>
            <% if (!topCustomers.isEmpty()) { %>
                <div class="summary-item">
                    <h3>Top Customer</h3>
                    <div class="summary-value"><%= topCustomers.get(0).get("firstName") %> <%= topCustomers.get(0).get("lastName") %></div>
                </div>
            <% } %>
        </div>
        
        <% if (!topCustomers.isEmpty()) { %>
            <table>
                <thead>
                    <tr>
                        <th>Rank</th>
                        <th>Customer</th>
                        <th>Tickets Purchased</th>
                        <th class="revenue-cell">Revenue</th>
                        <th>Last Purchase</th>
                    </tr>
                </thead>
                <tbody>
                    <% 
                        // Get max revenue for scaling bars
                        double maxRevenue = (Double) topCustomers.get(0).get("totalRevenue");
                        
                        for (int i = 0; i < topCustomers.size(); i++) {
                            Map<String, Object> customer = topCustomers.get(i);
                            double revenue = (Double) customer.get("totalRevenue");
                            int barWidth = (int) (revenue / maxRevenue * 100);
                    %>
                        <tr>
                            <td><%= i+1 %></td>
                            <td>
                                <a href="adminRevenue.jsp?reportType=customer&reportValue=<%= customer.get("userId") %>">
                                    <%= customer.get("firstName") %> <%= customer.get("lastName") %>
                                </a>
                                <div class="user-id">(<%= customer.get("userId") %>)</div>
                            </td>
                            <td><%= customer.get("ticketCount") %></td>
                            <td class="revenue-cell">
                                $<%= String.format("%.2f", revenue) %>
                                <div class="bar-container">
                                    <div class="revenue-bar" style="width: <%= barWidth %>%;"></div>
                                </div>
                            </td>
                            <td><%= customer.get("lastPurchase") %></td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
        <% } %>
    </div>
</body>
</html> 