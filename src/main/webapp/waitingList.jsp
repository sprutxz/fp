<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.auth.DatabaseConnection" %>
<%
    // Check if user is logged in
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    String userId = (String) session.getAttribute("userId");
    
    // Initialize variables
    List<Map<String, Object>> waitingList = new ArrayList<>();
    List<Map<String, Object>> notifications = new ArrayList<>();
    String errorMessage = "";
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = DatabaseConnection.getConnection();
        
        // Get all waiting list entries for the current user
        String sql = "SELECT w.flight_number, w.airline_id, w.request_date, w.status, " +
                     "w.notification_date, f.flight_type, f.dep_time, f.arr_time, " +
                     "f.dep_airport_id, f.arr_airport_id, a.airline_name " +
                     "FROM Waiting_List w " +
                     "JOIN Flight f ON w.flight_number = f.flight_number " +
                     "JOIN Airline a ON w.airline_id = a.airline_id " +
                     "WHERE w.user_id = ? " +
                     "ORDER BY w.request_date DESC";
        
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, userId);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> entry = new HashMap<>();
            entry.put("flightNumber", rs.getString("flight_number"));
            entry.put("airlineId", rs.getString("airline_id"));
            entry.put("airlineName", rs.getString("airline_name"));
            entry.put("requestDate", rs.getTimestamp("request_date"));
            entry.put("status", rs.getString("status"));
            entry.put("notificationDate", rs.getTimestamp("notification_date"));
            entry.put("flightType", rs.getString("flight_type"));
            entry.put("depTime", rs.getTime("dep_time"));
            entry.put("arrTime", rs.getTime("arr_time"));
            entry.put("depAirport", rs.getString("dep_airport_id"));
            entry.put("arrAirport", rs.getString("arr_airport_id"));
            waitingList.add(entry);
        }
        
        // Get all notifications for the user
        rs.close();
        pstmt.close();
        
        sql = "SELECT notification_id, message, notification_date, is_read " +
              "FROM Notification " +
              "WHERE user_id = ? " +
              "ORDER BY notification_date DESC";
        
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, userId);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> notification = new HashMap<>();
            notification.put("notificationId", rs.getInt("notification_id"));
            notification.put("message", rs.getString("message"));
            notification.put("notificationDate", rs.getTimestamp("notification_date"));
            notification.put("isRead", rs.getBoolean("is_read"));
            notifications.add(notification);
        }
        
        // Mark all notifications as read
        pstmt.close();
        sql = "UPDATE Notification SET is_read = 1 WHERE user_id = ? AND is_read = 0";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, userId);
        pstmt.executeUpdate();
        
    } catch (Exception e) {
        errorMessage = "Error retrieving waiting list: " + e.getMessage();
    } finally {
        if (rs != null) rs.close();
        if (pstmt != null) pstmt.close();
        if (conn != null) conn.close();
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Flight Waiting List</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 900px;
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
        .section {
            margin-bottom: 30px;
        }
        .waiting-list-container, .notifications-container {
            margin-top: 20px;
        }
        .list-card {
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 15px;
            background-color: #f9f9f9;
        }
        .list-header {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        .list-date {
            font-weight: bold;
            color: #555;
        }
        .list-details {
            display: flex;
            justify-content: space-between;
            flex-wrap: wrap;
        }
        .detail-column {
            flex: 1;
            min-width: 200px;
            margin-right: 15px;
        }
        .detail-group {
            margin-bottom: 12px;
        }
        .detail-label {
            font-size: 0.8em;
            color: #777;
            margin-bottom: 3px;
        }
        .detail-value {
            font-weight: bold;
        }
        .error-message {
            color: #d9534f;
            padding: 10px;
            background-color: #f8d7da;
            border-radius: 4px;
            margin-bottom: 15px;
        }
        .empty-state {
            text-align: center;
            padding: 20px 0;
            color: #777;
        }
        .button {
            display: inline-block;
            padding: 8px 16px;
            background-color: #6c757d;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            margin-top: 15px;
        }
        .button:hover {
            background-color: #5a6268;
        }
        .status-waiting {
            color: #fd7e14;
            font-weight: bold;
        }
        .status-notified {
            color: #28a745;
            font-weight: bold;
        }
        .status-booked {
            color: #007bff;
            font-weight: bold;
        }
        .status-expired {
            color: #dc3545;
            font-weight: bold;
        }
        .notification-card {
            border-left: 4px solid #2196F3;
            padding: 12px;
            margin-bottom: 15px;
            background-color: #e7f3fe;
        }
        .notification-header {
            display: flex;
            justify-content: space-between;
            margin-bottom: 8px;
            color: #555;
            font-size: 0.9em;
        }
        .notification-message {
            color: #333;
        }
        .info-box {
            background-color: #e7f3fe;
            border-left: 4px solid #2196F3;
            padding: 12px;
            margin-bottom: 20px;
        }
        .action-btn {
            display: inline-block;
            padding: 6px 12px;
            background-color: #4CAF50;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            font-size: 0.9em;
        }
        .action-btn:hover {
            background-color: #45a049;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Flight Waiting List</h1>
            <a href="dashboard.jsp" class="button">Back to Dashboard</a>
        </header>
        
        <% if (!errorMessage.isEmpty()) { %>
            <div class="error-message"><%= errorMessage %></div>
        <% } %>
        
        <div class="info-box">
            <p>When a seat becomes available for a flight you're waiting for, you'll receive a notification. You'll need to book the flight quickly before someone else does.</p>
        </div>
        
        <div class="section">
            <h2>Your Notifications</h2>
            <div class="notifications-container">
                <% if (notifications.isEmpty()) { %>
                    <div class="empty-state">
                        <p>You don't have any notifications yet.</p>
                    </div>
                <% } else { %>
                    <% for (Map<String, Object> notification : notifications) { %>
                        <div class="notification-card">
                            <div class="notification-header">
                                <span><%= notification.get("notificationDate") %></span>
                                <span><%= ((Boolean)notification.get("isRead")) ? "Read" : "New" %></span>
                            </div>
                            <div class="notification-message">
                                <%= notification.get("message") %>
                            </div>
                        </div>
                    <% } %>
                <% } %>
            </div>
        </div>
        
        <div class="section">
            <h2>Your Waiting List</h2>
            <div class="waiting-list-container">
                <% if (waitingList.isEmpty()) { %>
                    <div class="empty-state">
                        <h3>You're not on any waiting lists</h3>
                        <p>When flights are full, you can join the waiting list to be notified when a seat becomes available.</p>
                        <a href="flightSearch.jsp" class="button">Search for Flights</a>
                    </div>
                <% } else { %>
                    <% for (Map<String, Object> entry : waitingList) { %>
                        <div class="list-card">
                            <div class="list-header">
                                <span class="list-date">Request Date: <%= entry.get("requestDate") %></span>
                                <span>
                                    Status: 
                                    <% 
                                        String status = (String)entry.get("status");
                                        if ("waiting".equals(status)) { 
                                    %>
                                        <span class="status-waiting">Waiting</span>
                                    <% } else if ("notified".equals(status)) { %>
                                        <span class="status-notified">Seat Available!</span>
                                    <% } else if ("booked".equals(status)) { %>
                                        <span class="status-booked">Booked</span>
                                    <% } else { %>
                                        <span class="status-expired">Expired</span>
                                    <% } %>
                                </span>
                            </div>
                            <div class="list-details">
                                <div class="detail-column">
                                    <div class="detail-group">
                                        <div class="detail-label">Flight</div>
                                        <div class="detail-value"><%= entry.get("airlineName") %> <%= entry.get("flightNumber") %></div>
                                    </div>
                                    <div class="detail-group">
                                        <div class="detail-label">Route</div>
                                        <div class="detail-value"><%= entry.get("depAirport") %> → <%= entry.get("arrAirport") %></div>
                                    </div>
                                    <div class="detail-group">
                                        <div class="detail-label">Time</div>
                                        <div class="detail-value"><%= entry.get("depTime") %> - <%= entry.get("arrTime") %></div>
                                    </div>
                                </div>
                                <div class="detail-column">
                                    <div class="detail-group">
                                        <div class="detail-label">Flight Type</div>
                                        <div class="detail-value"><%= entry.get("flightType") %></div>
                                    </div>
                                    <% if ("notified".equals(status)) { %>
                                        <div class="detail-group">
                                            <div class="detail-label">Notification Date</div>
                                            <div class="detail-value"><%= entry.get("notificationDate") %></div>
                                        </div>
                                        <div class="detail-group">
                                            <a href="flightSearch.jsp" class="action-btn">Book Now</a>
                                        </div>
                                    <% } %>
                                </div>
                            </div>
                        </div>
                    <% } %>
                <% } %>
            </div>
        </div>
    </div>
</body>
</html> 