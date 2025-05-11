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
    List<Map<String, Object>> reportResults = new ArrayList<>();
    String message = "";
    String messageType = "";
    String reportType = request.getParameter("reportType");
    String reportValue = request.getParameter("reportValue");
    String reportTitle = "";
    boolean doGenerate = (reportType != null && reportValue != null && !reportValue.trim().isEmpty());
    
    if (doGenerate) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            String sql = "";
            
            // Revenue by Flight Number
            if ("flight".equals(reportType)) {
                reportTitle = "Revenue Summary for Flight " + reportValue;
                
                sql = "SELECT f.flight_number, f.airline_id, a.airline_name, f.dep_airport_id, f.arr_airport_id, " +
                      "COUNT(t.ticket_id) as tickets_sold, SUM(t.fare) as total_revenue " +
                      "FROM Flight f " +
                      "JOIN Travel tr ON f.flight_number = tr.flight_number " +
                      "JOIN Ticket t ON tr.user_id = t.user_id AND tr.seat_no = t.seat_no AND tr.aircraft_id = t.aircraft_id " +
                      "JOIN Airline a ON f.airline_id = a.airline_id " +
                      "WHERE f.flight_number = ? " +
                      "GROUP BY f.flight_number, f.airline_id, a.airline_name, f.dep_airport_id, f.arr_airport_id";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, reportValue);
                rs = pstmt.executeQuery();
                
                if (rs.next()) {
                    Map<String, Object> result = new HashMap<>();
                    result.put("flightNumber", rs.getString("flight_number"));
                    result.put("airlineId", rs.getString("airline_id"));
                    result.put("airlineName", rs.getString("airline_name"));
                    result.put("depAirport", rs.getString("dep_airport_id"));
                    result.put("arrAirport", rs.getString("arr_airport_id"));
                    result.put("ticketsSold", rs.getInt("tickets_sold"));
                    result.put("totalRevenue", rs.getDouble("total_revenue"));
                    reportResults.add(result);
                    
                    // Get monthly breakdown
                    rs.close();
                    pstmt.close();
                    
                    sql = "SELECT YEAR(t.date) as year, MONTH(t.date) as month, " +
                          "COUNT(t.ticket_id) as tickets_sold, SUM(t.fare) as monthly_revenue " +
                          "FROM Flight f " +
                          "JOIN Travel tr ON f.flight_number = tr.flight_number " +
                          "JOIN Ticket t ON tr.user_id = t.user_id AND tr.seat_no = t.seat_no AND tr.aircraft_id = t.aircraft_id " +
                          "WHERE f.flight_number = ? " +
                          "GROUP BY YEAR(t.date), MONTH(t.date) " +
                          "ORDER BY YEAR(t.date) DESC, MONTH(t.date) DESC " +
                          "LIMIT 12";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setString(1, reportValue);
                    rs = pstmt.executeQuery();
                    
                    List<Map<String, Object>> monthlyData = new ArrayList<>();
                    while (rs.next()) {
                        Map<String, Object> monthly = new HashMap<>();
                        monthly.put("year", rs.getInt("year"));
                        monthly.put("month", rs.getInt("month"));
                        monthly.put("ticketsSold", rs.getInt("tickets_sold"));
                        monthly.put("monthlyRevenue", rs.getDouble("monthly_revenue"));
                        monthlyData.add(monthly);
                    }
                    
                    if (!monthlyData.isEmpty()) {
                        result.put("monthlyData", monthlyData);
                    }
                } else {
                    message = "No data found for flight " + reportValue;
                    messageType = "info";
                }
            }
            // Revenue by Airline
            else if ("airline".equals(reportType)) {
                reportTitle = "Revenue Summary for Airline " + reportValue;
                
                sql = "SELECT a.airline_id, a.airline_name, COUNT(t.ticket_id) as tickets_sold, SUM(t.fare) as total_revenue " +
                      "FROM Airline a " +
                      "JOIN Flight f ON a.airline_id = f.airline_id " +
                      "JOIN Travel tr ON f.flight_number = tr.flight_number " +
                      "JOIN Ticket t ON tr.user_id = t.user_id AND tr.seat_no = t.seat_no AND tr.aircraft_id = t.aircraft_id " +
                      "WHERE a.airline_id = ? OR a.airline_name LIKE ? " +
                      "GROUP BY a.airline_id, a.airline_name";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, reportValue);
                pstmt.setString(2, "%" + reportValue + "%");
                rs = pstmt.executeQuery();
                
                if (rs.next()) {
                    Map<String, Object> result = new HashMap<>();
                    result.put("airlineId", rs.getString("airline_id"));
                    result.put("airlineName", rs.getString("airline_name"));
                    result.put("ticketsSold", rs.getInt("tickets_sold"));
                    result.put("totalRevenue", rs.getDouble("total_revenue"));
                    reportResults.add(result);
                    
                    reportTitle = "Revenue Summary for Airline " + result.get("airlineName") + " (" + result.get("airlineId") + ")";
                    
                    // Get top flights for this airline
                    rs.close();
                    pstmt.close();
                    
                    sql = "SELECT f.flight_number, f.dep_airport_id, f.arr_airport_id, " +
                          "COUNT(t.ticket_id) as tickets_sold, SUM(t.fare) as flight_revenue " +
                          "FROM Flight f " +
                          "JOIN Travel tr ON f.flight_number = tr.flight_number " +
                          "JOIN Ticket t ON tr.user_id = t.user_id AND tr.seat_no = t.seat_no AND tr.aircraft_id = t.aircraft_id " +
                          "WHERE f.airline_id = ? " +
                          "GROUP BY f.flight_number, f.dep_airport_id, f.arr_airport_id " +
                          "ORDER BY flight_revenue DESC " +
                          "LIMIT 10";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setString(1, result.get("airlineId").toString());
                    rs = pstmt.executeQuery();
                    
                    List<Map<String, Object>> topFlights = new ArrayList<>();
                    while (rs.next()) {
                        Map<String, Object> flight = new HashMap<>();
                        flight.put("flightNumber", rs.getString("flight_number"));
                        flight.put("depAirport", rs.getString("dep_airport_id"));
                        flight.put("arrAirport", rs.getString("arr_airport_id"));
                        flight.put("ticketsSold", rs.getInt("tickets_sold"));
                        flight.put("flightRevenue", rs.getDouble("flight_revenue"));
                        topFlights.add(flight);
                    }
                    
                    if (!topFlights.isEmpty()) {
                        result.put("topFlights", topFlights);
                    }
                } else {
                    message = "No data found for airline " + reportValue;
                    messageType = "info";
                }
            }
            // Revenue by Customer
            else if ("customer".equals(reportType)) {
                reportTitle = "Revenue Summary for Customer " + reportValue;
                
                sql = "SELECT u.user_id, u.first_name, u.last_name, COUNT(t.ticket_id) as tickets_purchased, SUM(t.fare) as total_spent " +
                      "FROM User u " +
                      "JOIN Ticket t ON u.user_id = t.user_id " +
                      "WHERE u.user_id = ? OR CONCAT(u.first_name, ' ', u.last_name) LIKE ? " +
                      "GROUP BY u.user_id, u.first_name, u.last_name";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, reportValue);
                pstmt.setString(2, "%" + reportValue + "%");
                rs = pstmt.executeQuery();
                
                while (rs.next()) {
                    Map<String, Object> result = new HashMap<>();
                    result.put("userId", rs.getString("user_id"));
                    result.put("firstName", rs.getString("first_name"));
                    result.put("lastName", rs.getString("last_name"));
                    result.put("ticketsPurchased", rs.getInt("tickets_purchased"));
                    result.put("totalSpent", rs.getDouble("total_spent"));
                    reportResults.add(result);
                    
                    reportTitle = "Revenue Summary for Customer " + result.get("firstName") + " " + result.get("lastName") + " (" + result.get("userId") + ")";
                    
                    // Get recent tickets for this customer
                    String userId = rs.getString("user_id");
                    
                    rs.close();
                    pstmt.close();
                    
                    sql = "SELECT t.ticket_id, t.fare, t.type, t.date, t.seat_no, t.aircraft_id, " +
                          "f.flight_number, f.dep_airport_id, f.arr_airport_id, f.airline_id, a.airline_name " +
                          "FROM Ticket t " +
                          "JOIN Travel tr ON t.user_id = tr.user_id AND t.seat_no = tr.seat_no AND t.aircraft_id = tr.aircraft_id " +
                          "JOIN Flight f ON tr.flight_number = f.flight_number " +
                          "JOIN Airline a ON f.airline_id = a.airline_id " +
                          "WHERE t.user_id = ? " +
                          "ORDER BY t.date DESC " +
                          "LIMIT 5";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setString(1, userId);
                    rs = pstmt.executeQuery();
                    
                    List<Map<String, Object>> recentTickets = new ArrayList<>();
                    while (rs.next()) {
                        Map<String, Object> ticket = new HashMap<>();
                        ticket.put("ticketId", rs.getString("ticket_id"));
                        ticket.put("fare", rs.getDouble("fare"));
                        ticket.put("type", rs.getString("type"));
                        ticket.put("date", rs.getDate("date"));
                        ticket.put("seatNo", rs.getString("seat_no"));
                        ticket.put("aircraftId", rs.getString("aircraft_id"));
                        ticket.put("flightNumber", rs.getString("flight_number"));
                        ticket.put("depAirport", rs.getString("dep_airport_id"));
                        ticket.put("arrAirport", rs.getString("arr_airport_id"));
                        ticket.put("airlineId", rs.getString("airline_id"));
                        ticket.put("airlineName", rs.getString("airline_name"));
                        recentTickets.add(ticket);
                    }
                    
                    if (!recentTickets.isEmpty()) {
                        result.put("recentTickets", recentTickets);
                    }
                }
                
                if (reportResults.isEmpty()) {
                    message = "No customers found matching: " + reportValue;
                    messageType = "info";
                }
            }
        } catch (Exception e) {
            message = "Error generating report: " + e.getMessage();
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
    }
    
    // Month name mapping
    String[] monthNames = {"January", "February", "March", "April", "May", "June", 
                          "July", "August", "September", "October", "November", "December"};
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Revenue Summary</title>
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
        .search-form {
            background-color: #f9f9f9;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .form-group {
            margin-bottom: 15px;
            display: inline-block;
            margin-right: 20px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
        }
        input[type="text"], select {
            padding: 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
            min-width: 200px;
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
            flex-wrap: wrap;
            justify-content: space-between;
        }
        .summary-item {
            text-align: center;
            flex: 1;
            min-width: 150px;
            margin: 10px;
        }
        .summary-item h3 {
            margin: 0 0 10px 0;
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
        .section {
            margin-bottom: 30px;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Revenue Summary</h1>
            <a href="adminDashboard.jsp" class="back-button">Back to Dashboard</a>
        </header>
        
        <% if (!message.isEmpty()) { %>
            <div class="message <%= messageType %>">
                <%= message %>
            </div>
        <% } %>
        
        <div class="search-form">
            <h2>Generate Revenue Report</h2>
            <form method="get">
                <div class="form-group">
                    <label for="reportType">Report Type</label>
                    <select id="reportType" name="reportType" required>
                        <option value="flight" <%= "flight".equals(reportType) ? "selected" : "" %>>By Flight Number</option>
                        <option value="airline" <%= "airline".equals(reportType) ? "selected" : "" %>>By Airline</option>
                        <option value="customer" <%= "customer".equals(reportType) ? "selected" : "" %>>By Customer</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label for="reportValue">Search Value</label>
                    <input type="text" id="reportValue" name="reportValue" value="<%= reportValue != null ? reportValue : "" %>" required>
                </div>
                
                <button type="submit" class="button">Generate Report</button>
            </form>
        </div>
        
        <% if (doGenerate && !reportResults.isEmpty()) { %>
            <h2><%= reportTitle %></h2>
            
            <% 
                // Flight revenue report
                if ("flight".equals(reportType)) {
                    Map<String, Object> flightData = reportResults.get(0);
            %>
                <div class="summary-box">
                    <div class="summary-item">
                        <h3>Flight Number</h3>
                        <div class="summary-value"><%= flightData.get("flightNumber") %></div>
                    </div>
                    <div class="summary-item">
                        <h3>Airline</h3>
                        <div class="summary-value"><%= flightData.get("airlineName") %> (<%= flightData.get("airlineId") %>)</div>
                    </div>
                    <div class="summary-item">
                        <h3>Route</h3>
                        <div class="summary-value"><%= flightData.get("depAirport") %> → <%= flightData.get("arrAirport") %></div>
                    </div>
                    <div class="summary-item">
                        <h3>Tickets Sold</h3>
                        <div class="summary-value"><%= flightData.get("ticketsSold") %></div>
                    </div>
                    <div class="summary-item">
                        <h3>Total Revenue</h3>
                        <div class="summary-value">$<%= String.format("%.2f", flightData.get("totalRevenue")) %></div>
                    </div>
                </div>
                
                <% if (flightData.get("monthlyData") != null) { %>
                    <div class="section">
                        <h3>Monthly Revenue Breakdown</h3>
                        <table>
                            <thead>
                                <tr>
                                    <th>Month</th>
                                    <th>Tickets Sold</th>
                                    <th>Revenue</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% 
                                    List<Map<String, Object>> monthlyData = (List<Map<String, Object>>) flightData.get("monthlyData");
                                    for (Map<String, Object> month : monthlyData) {
                                        int monthIndex = (Integer) month.get("month") - 1;
                                        String monthName = monthNames[monthIndex];
                                %>
                                    <tr>
                                        <td><%= monthName %> <%= month.get("year") %></td>
                                        <td><%= month.get("ticketsSold") %></td>
                                        <td>$<%= String.format("%.2f", month.get("monthlyRevenue")) %></td>
                                    </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                <% } %>
            <% 
                }
                // Airline revenue report
                else if ("airline".equals(reportType)) {
                    Map<String, Object> airlineData = reportResults.get(0);
            %>
                <div class="summary-box">
                    <div class="summary-item">
                        <h3>Airline</h3>
                        <div class="summary-value"><%= airlineData.get("airlineName") %> (<%= airlineData.get("airlineId") %>)</div>
                    </div>
                    <div class="summary-item">
                        <h3>Tickets Sold</h3>
                        <div class="summary-value"><%= airlineData.get("ticketsSold") %></div>
                    </div>
                    <div class="summary-item">
                        <h3>Total Revenue</h3>
                        <div class="summary-value">$<%= String.format("%.2f", airlineData.get("totalRevenue")) %></div>
                    </div>
                </div>
                
                <% if (airlineData.get("topFlights") != null) { %>
                    <div class="section">
                        <h3>Top Revenue-Generating Flights</h3>
                        <table>
                            <thead>
                                <tr>
                                    <th>Flight Number</th>
                                    <th>Route</th>
                                    <th>Tickets Sold</th>
                                    <th>Revenue</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% 
                                    List<Map<String, Object>> topFlights = (List<Map<String, Object>>) airlineData.get("topFlights");
                                    for (Map<String, Object> flight : topFlights) {
                                %>
                                    <tr>
                                        <td><%= flight.get("flightNumber") %></td>
                                        <td><%= flight.get("depAirport") %> → <%= flight.get("arrAirport") %></td>
                                        <td><%= flight.get("ticketsSold") %></td>
                                        <td>$<%= String.format("%.2f", flight.get("flightRevenue")) %></td>
                                    </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                <% } %>
            <% 
                }
                // Customer revenue report
                else if ("customer".equals(reportType)) {
                    for (Map<String, Object> customerData : reportResults) {
            %>
                <div class="summary-box">
                    <div class="summary-item">
                        <h3>Customer</h3>
                        <div class="summary-value"><%= customerData.get("firstName") %> <%= customerData.get("lastName") %></div>
                        <div>(<%= customerData.get("userId") %>)</div>
                    </div>
                    <div class="summary-item">
                        <h3>Tickets Purchased</h3>
                        <div class="summary-value"><%= customerData.get("ticketsPurchased") %></div>
                    </div>
                    <div class="summary-item">
                        <h3>Total Revenue</h3>
                        <div class="summary-value">$<%= String.format("%.2f", customerData.get("totalSpent")) %></div>
                    </div>
                </div>
                
                <% if (customerData.get("recentTickets") != null) { %>
                    <div class="section">
                        <h3>Recent Tickets</h3>
                        <table>
                            <thead>
                                <tr>
                                    <th>Ticket ID</th>
                                    <th>Flight</th>
                                    <th>Route</th>
                                    <th>Date</th>
                                    <th>Type</th>
                                    <th>Fare</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% 
                                    List<Map<String, Object>> recentTickets = (List<Map<String, Object>>) customerData.get("recentTickets");
                                    for (Map<String, Object> ticket : recentTickets) {
                                %>
                                    <tr>
                                        <td><%= ticket.get("ticketId") %></td>
                                        <td><%= ticket.get("flightNumber") %> (<%= ticket.get("airlineName") %>)</td>
                                        <td><%= ticket.get("depAirport") %> → <%= ticket.get("arrAirport") %></td>
                                        <td><%= ticket.get("date") %></td>
                                        <td><%= ticket.get("type") %></td>
                                        <td>$<%= String.format("%.2f", ticket.get("fare")) %></td>
                                    </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                <% } %>
                
            <% 
                    }
                }
            %>
            
        <% } %>
    </div>
</body>
</html> 