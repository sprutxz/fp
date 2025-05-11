<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.auth.DatabaseConnection" %>
<%
    // Check rep role
    if (session.getAttribute("userId") == null || !"customer_rep".equals(session.getAttribute("userRole"))) {
        response.sendRedirect("login.jsp"); return;
    }
    String message = "";
    String action = request.getParameter("action");
    String aid = request.getParameter("aircraftId");
    String airlineId = request.getParameter("airlineId");
    String seatsStr = request.getParameter("numSeats");
    
    Connection conn = null;
    PreparedStatement stmt = null;
    
    try {
        conn = DatabaseConnection.getConnection();
        if (action != null) {
            if ("add".equals(action)) {
                String sql = "INSERT INTO Aircraft (aircraft_id, airline_id, num_seats) VALUES (?, ?, ?)";
                stmt = conn.prepareStatement(sql);
                stmt.setString(1, aid);
                stmt.setString(2, airlineId);
                stmt.setInt(3, Integer.parseInt(seatsStr));
                stmt.executeUpdate(); stmt.close();
                message = "Aircraft added successfully.";
            } else if ("update".equals(action)) {
                String sql = "UPDATE Aircraft SET airline_id = ?, num_seats = ? WHERE aircraft_id = ?";
                stmt = conn.prepareStatement(sql);
                stmt.setString(1, airlineId);
                stmt.setInt(2, Integer.parseInt(seatsStr));
                stmt.setString(3, aid);
                stmt.executeUpdate(); stmt.close();
                message = "Aircraft updated successfully.";
            } else if ("delete".equals(action)) {
                String sql = "DELETE FROM Aircraft WHERE aircraft_id = ?";
                stmt = conn.prepareStatement(sql);
                stmt.setString(1, aid);
                stmt.executeUpdate(); stmt.close();
                message = "Aircraft deleted successfully.";
            }
        }
    } catch (Exception e) {
        message = "Error: " + e.getMessage();
    } finally {
        if (stmt != null) try { stmt.close(); } catch(Exception ignored) {}
        if (conn != null) try { conn.close(); } catch(Exception ignored) {}
    }

    // Fetch all aircraft
    List<Map<String,Object>> list = new ArrayList<>();
    try {
        conn = DatabaseConnection.getConnection();
        String sql = "SELECT aircraft_id, airline_id, num_seats FROM Aircraft";
        stmt = conn.prepareStatement(sql);
        ResultSet rs = stmt.executeQuery();
        while (rs.next()) {
            Map<String,Object> m = new HashMap<>();
            m.put("aircraftId", rs.getString("aircraft_id"));
            m.put("airlineId", rs.getString("airline_id"));
            m.put("numSeats", rs.getInt("num_seats"));
            list.add(m);
        }
        rs.close(); stmt.close();
    } catch (Exception e) {}
    finally {
        if (stmt != null) try { stmt.close(); } catch(Exception ignored) {}
        if (conn != null) try { conn.close(); } catch(Exception ignored) {}
    }
%>
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Manage Aircraft</title><style>table, th, td {border:1px solid #ddd;border-collapse:collapse;padding:8px;} th{background:#f2f2f2;} .button{padding:6px 12px;background:#4CAF50;color:#fff;text-decoration:none;border-radius:4px;} .error{color:red;}</style></head>
<body>
    <h2>Aircraft Management</h2>
    <a href="repDashboard.jsp" class="button">Back to Dashboard</a>
    <% if (!message.isEmpty()) { %><p class="error"><%= message %></p><% } %>
    <h3>Add / Update Aircraft</h3>
    <form method="post" action="manageAircraft.jsp">
        <input type="hidden" name="action" value="add" />
        <label>ID:<input type="text" name="aircraftId" required /></label>
        <label>Airline ID:<input type="text" name="airlineId" required /></label>
        <label>Seats:<input type="number" name="numSeats" required /></label>
        <button type="submit" class="button">Add Aircraft</button>
    </form>
    <h3>Existing Aircraft</h3>
    <table>
        <tr><th>ID</th><th>Airline</th><th>Seats</th><th>Actions</th></tr>
        <% for (Map<String,Object> m : list) { %>
            <tr>
                <td><%= m.get("aircraftId") %></td>
                <td><%= m.get("airlineId") %></td>
                <td><%= m.get("numSeats") %></td>
                <td>
                    <form method="post" style="display:inline;" action="manageAircraft.jsp">
                        <input type="hidden" name="action" value="update" />
                        <input type="hidden" name="aircraftId" value="<%= m.get("aircraftId") %>" />
                        <input type="text" name="airlineId" value="<%= m.get("airlineId") %>" required />
                        <input type="number" name="numSeats" value="<%= m.get("numSeats") %>" required />
                        <button type="submit" class="button">Update</button>
                    </form>
                    <form method="post" style="display:inline;" action="manageAircraft.jsp" onsubmit="return confirm('Delete this aircraft?');">
                        <input type="hidden" name="action" value="delete" />
                        <input type="hidden" name="aircraftId" value="<%= m.get("aircraftId") %>" />
                        <button type="submit" class="button" style="background:#f44336;">Delete</button>
                    </form>
                </td>
            </tr>
        <% } %>
    </table>
</body>
</html> 