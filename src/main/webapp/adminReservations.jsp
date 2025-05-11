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
    List<Map<String, Object>> reservations = new ArrayList<>();
    String message = "";
    String messageType = "";
    
    // Get search parameters
    String searchType = request.getParameter("searchType");
    String searchValue = request.getParameter("searchValue");
    boolean doSearch = (searchType != null && searchValue != null && !searchValue.trim().isEmpty());
    
    if (doSearch) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            String sql = "";
            
            // Search by flight number
            if ("flightNumber".equals(searchType)) {
                sql = "SELECT t.ticket_id, t.user_id, u.first_name, u.last_name, t.fare, " +
                      "t.type as ticket_type, t.date, t.seat_no, t.aircraft_id, " +
                      "f.flight_number, f.flight_type, f.dep_time, f.arr_time, " +
                      "f.dep_airport_id, f.arr_airport_id, f.airline_id, a.airline_name " +
                      "FROM Ticket t " +
                      "JOIN User u ON t.user_id = u.user_id " +
                      "JOIN Travel tr ON t.user_id = tr.user_id AND t.seat_no = tr.seat_no AND t.aircraft_id = tr.aircraft_id " +
                      "JOIN Flight f ON tr.flight_number = f.flight_number " +
                      "JOIN Airline a ON f.airline_id = a.airline_id " +
                      "WHERE f.flight_number = ? " +
                      "ORDER BY t.date DESC";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, searchValue);
            } 
            // Search by customer name
            else if ("customerName".equals(searchType)) {
                sql = "SELECT t.ticket_id, t.user_id, u.first_name, u.last_name, t.fare, " +
                      "t.type as ticket_type, t.date, t.seat_no, t.aircraft_id, " +
                      "f.flight_number, f.flight_type, f.dep_time, f.arr_time, " +
                      "f.dep_airport_id, f.arr_airport_id, f.airline_id, a.airline_name " +
                      "FROM Ticket t " +
                      "JOIN User u ON t.user_id = u.user_id " +
                      "JOIN Travel tr ON t.user_id = tr.user_id AND t.seat_no = tr.seat_no AND t.aircraft_id = tr.aircraft_id " +
                      "JOIN Flight f ON tr.flight_number = f.flight_number " +
                      "JOIN Airline a ON f.airline_id = a.airline_id " +
                      "WHERE CONCAT(u.first_name, ' ', u.last_name) LIKE ? " +
                      "ORDER BY t.date DESC";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, "%" + searchValue + "%");
            }
            
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                Map<String, Object> reservation = new HashMap<>();
                reservation.put("ticketId", rs.getString("ticket_id"));
                reservation.put("userId", rs.getString("user_id"));
                reservation.put("firstName", rs.getString("first_name"));
                reservation.put("lastName", rs.getString("last_name"));
                reservation.put("fare", rs.getDouble("fare"));
                reservation.put("ticketType", rs.getString("ticket_type"));
                reservation.put("date", rs.getDate("date"));
                reservation.put("seatNo", rs.getString("seat_no"));
                reservation.put("aircraftId", rs.getString("aircraft_id"));
                reservation.put("flightNumber", rs.getString("flight_number"));
                reservation.put("flightType", rs.getString("flight_type"));
                reservation.put("depTime", rs.getTime("dep_time"));
                reservation.put("arrTime", rs.getTime("arr_time"));
                reservation.put("depAirport", rs.getString("dep_airport_id"));
                reservation.put("arrAirport", rs.getString("arr_airport_id"));
                reservation.put("airlineId", rs.getString("airline_id"));
                reservation.put("airlineName", rs.getString("airline_name"));
                reservations.add(reservation);
            }
            
            if (reservations.isEmpty()) {
                message = "No reservations found for the specified search criteria.";
                messageType = "info";
            }
            
        } catch (Exception e) {
            message = "Error searching reservations: " + e.getMessage();
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
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Reservation List</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
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
        .reservation-details {
            background-color: #f9f9f9;
            padding: 15px;
            border-radius: 5px;
            margin-top: 10px;
        }
        .reservation-details h3 {
            margin-top: 0;
            color: #333;
        }
        .detail-row {
            display: flex;
            margin-bottom: 10px;
        }
        .detail-label {
            font-weight: bold;
            width: 150px;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Reservation List</h1>
            <a href="adminDashboard.jsp" class="back-button">Back to Dashboard</a>
        </header>
        
        <% if (!message.isEmpty()) { %>
            <div class="message <%= messageType %>">
                <%= message %>
            </div>
        <% } %>
        
        <div class="search-form">
            <h2>Search Reservations</h2>
            <form method="get">
                <div class="form-group">
                    <label for="searchType">Search By</label>
                    <select id="searchType" name="searchType" required>
                        <option value="flightNumber" <%= "flightNumber".equals(searchType) ? "selected" : "" %>>Flight Number</option>
                        <option value="customerName" <%= "customerName".equals(searchType) ? "selected" : "" %>>Customer Name</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label for="searchValue">Search Value</label>
                    <input type="text" id="searchValue" name="searchValue" value="<%= searchValue != null ? searchValue : "" %>" required>
                </div>
                
                <button type="submit" class="button">Search</button>
            </form>
        </div>
        
        <% if (doSearch && !reservations.isEmpty()) { %>
            <h2>Search Results</h2>
            <p>Found <%= reservations.size() %> reservation(s).</p>
            
            <% for (Map<String, Object> reservation : reservations) { %>
                <div class="reservation-details">
                    <h3>Ticket ID: <%= reservation.get("ticketId") %></h3>
                    
                    <div class="detail-row">
                        <div class="detail-label">Customer:</div>
                        <div><%= reservation.get("firstName") %> <%= reservation.get("lastName") %> (<%= reservation.get("userId") %>)</div>
                    </div>
                    
                    <div class="detail-row">
                        <div class="detail-label">Flight:</div>
                        <div><%= reservation.get("flightNumber") %> (<%= reservation.get("airlineName") %>)</div>
                    </div>
                    
                    <div class="detail-row">
                        <div class="detail-label">Route:</div>
                        <div><%= reservation.get("depAirport") %> → <%= reservation.get("arrAirport") %></div>
                    </div>
                    
                    <div class="detail-row">
                        <div class="detail-label">Time:</div>
                        <div><%= reservation.get("depTime") %> - <%= reservation.get("arrTime") %></div>
                    </div>
                    
                    <div class="detail-row">
                        <div class="detail-label">Date:</div>
                        <div><%= reservation.get("date") %></div>
                    </div>
                    
                    <div class="detail-row">
                        <div class="detail-label">Seat:</div>
                        <div><%= reservation.get("seatNo") %> (<%= reservation.get("aircraftId") %>)</div>
                    </div>
                    
                    <div class="detail-row">
                        <div class="detail-label">Ticket Type:</div>
                        <div><%= reservation.get("ticketType") %></div>
                    </div>
                    
                    <div class="detail-row">
                        <div class="detail-label">Fare:</div>
                        <div>$<%= String.format("%.2f", reservation.get("fare")) %></div>
                    </div>
                </div>
            <% } %>
        <% } %>
    </div>
</body>
</html> 