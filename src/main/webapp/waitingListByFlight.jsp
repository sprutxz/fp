<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.auth.DatabaseConnection" %>
<%
    if (session.getAttribute("userId")==null || !"customer_rep".equals(session.getAttribute("userRole"))) { response.sendRedirect("login.jsp"); return; }
    String flightNumber = request.getParameter("flightNumber");
    String message="";
    List<Map<String,Object>> list = new ArrayList<>();
    if (flightNumber!=null && !flightNumber.isEmpty()) {
        try (Connection conn=DatabaseConnection.getConnection();
             PreparedStatement stmt=conn.prepareStatement("SELECT user_id, request_date, status, notification_date FROM Waiting_List WHERE flight_number = ? ORDER BY request_date DESC")) {
            stmt.setString(1, flightNumber);
            try (ResultSet rs=stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String,Object> m=new HashMap<>();
                    m.put("userId", rs.getString("user_id"));
                    m.put("requestDate", rs.getTimestamp("request_date"));
                    m.put("status", rs.getString("status"));
                    m.put("notificationDate", rs.getTimestamp("notification_date"));
                    list.add(m);
                }
            }
        } catch (Exception e) { message = "Error: " + e.getMessage(); }
    }
%>
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Waiting List by Flight</title><style>table,th,td{border:1px solid #ddd;border-collapse:collapse;padding:8px;}th{background:#f2f2f2;} .button{padding:6px 12px;background:#4CAF50;color:white;text-decoration:none;border-radius:4px;} .error{color:red;}</style></head>
<body>
    <h2>Waiting List for Flight</h2>
    <div style="text-align: right; margin-bottom: 20px;">
        <a href="repDashboard.jsp" class="button">Back to Dashboard</a>
    </div>
    <form method="get" action="waitingListByFlight.jsp">
        <label>Flight Number: <input type="text" name="flightNumber" value="<%= flightNumber!=null?flightNumber:"" %>" required/></label>
        <button type="submit" class="button">View</button>
    </form>
    <% if (!message.isEmpty()) { %><p class="error"><%= message %></p><% } %>
    <% if (flightNumber!=null && !flightNumber.isEmpty()) { %>
        <% if (list.isEmpty()) { %>
            <p>No waiting list entries for flight <%= flightNumber %>.</p>
        <% } else { %>
            <table>
                <tr><th>User ID</th><th>Request Date</th><th>Status</th><th>Notification Date</th></tr>
                <% for (Map<String,Object> m: list) { %>
                    <tr>
                        <td><%= m.get("userId") %></td>
                        <td><%= m.get("requestDate") %></td>
                        <td><%= m.get("status") %></td>
                        <td><%= m.get("notificationDate") %></td>
                    </tr>
                <% } %>
            </table>
        <% } %>
    <% } %>
</body>
</html> 