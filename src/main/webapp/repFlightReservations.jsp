<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.auth.DatabaseConnection" %>
<%@ page import="java.sql.Date" %>
<%@ page import="java.math.BigDecimal" %>
<%
    // Check login and role
    if (session.getAttribute("userId") == null || !"customer_rep".equals(session.getAttribute("userRole"))) {
        response.sendRedirect("login.jsp");
        return;
    }
    String repId = (String) session.getAttribute("userId");
    String targetUser = request.getParameter("targetUser");
    String message = "";
    List<Map<String, Object>> existing = new ArrayList<>();
    List<Map<String, Object>> searchResults = new ArrayList<>();
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        conn = DatabaseConnection.getConnection();
        if (targetUser != null && !targetUser.isEmpty()) {
            // Fetch existing upcoming reservations for target user
            String sql = "SELECT t.ticket_id, t.date AS travel_date, t.seat_no, t.aircraft_id, t.flight_number, " +
                         "f.dep_airport_id, f.arr_airport_id, f.dep_time, f.arr_time, a.airline_name, t.fare " +
                         "FROM Ticket t " +
                         "JOIN Flight f ON t.flight_number = f.flight_number " +
                         "JOIN Airline a ON f.airline_id = a.airline_id " +
                         "WHERE t.user_id = ? AND t.date >= CURDATE() ORDER BY t.date";
            stmt = conn.prepareStatement(sql);
            stmt.setString(1, targetUser);
            rs = stmt.executeQuery();
            while (rs.next()) {
                Map<String, Object> rec = new HashMap<>();
                rec.put("ticketId", rs.getString("ticket_id"));
                rec.put("travelDate", rs.getDate("travel_date"));
                rec.put("flightNumber", rs.getString("flight_number"));
                rec.put("airlineName", rs.getString("airline_name"));
                rec.put("depAirport", rs.getString("dep_airport_id"));
                rec.put("arrAirport", rs.getString("arr_airport_id"));
                rec.put("depTime", rs.getTime("dep_time"));
                rec.put("arrTime", rs.getTime("arr_time"));
                rec.put("seatNo", rs.getString("seat_no"));
                rec.put("fare", rs.getBigDecimal("fare"));
                existing.add(rec);
            }
            rs.close(); stmt.close();
            // Handle flight search
            String dep = request.getParameter("depAirport");
            String arr = request.getParameter("arrAirport");
            String dateStr = request.getParameter("travelDate");
            if (dep != null && arr != null && dateStr != null && !dep.isEmpty() && !arr.isEmpty() && !dateStr.isEmpty()) {
                Date travelDate = Date.valueOf(dateStr);
                String sql2 = "SELECT f.flight_number, f.flight_type, f.dep_time, f.arr_time, f.dep_airport_id, f.arr_airport_id, " +
                              "f.aircraft_id, f.airline_id, a.airline_name, f.price AS fare " +
                              "FROM Flight f JOIN Airline a ON f.airline_id = a.airline_id " +
                              "WHERE f.dep_airport_id = ? AND f.arr_airport_id = ?";
                stmt = conn.prepareStatement(sql2);
                stmt.setString(1, dep);
                stmt.setString(2, arr);
                rs = stmt.executeQuery();
                while (rs.next()) {
                    Map<String, Object> f = new HashMap<>();
                    f.put("flightNumber", rs.getString("flight_number"));
                    f.put("flightType", rs.getString("flight_type"));
                    f.put("depTime", rs.getTime("dep_time"));
                    f.put("arrTime", rs.getTime("arr_time"));
                    f.put("depAirport", rs.getString("dep_airport_id"));
                    f.put("arrAirport", rs.getString("arr_airport_id"));
                    f.put("aircraftId", rs.getString("aircraft_id"));
                    f.put("airlineId", rs.getString("airline_id"));
                    f.put("airlineName", rs.getString("airline_name"));
                    f.put("fare", rs.getBigDecimal("fare"));
                    f.put("travelDate", travelDate);
                    searchResults.add(f);
                }
                rs.close(); stmt.close();
            }
        }
    } catch (Exception e) {
        message = "Error: " + e.getMessage();
    } finally {
        if (rs != null) try{rs.close();}catch(Exception ignored){}
        if (stmt != null) try{stmt.close();}catch(Exception ignored){}
        if (conn != null) try{conn.close();}catch(Exception ignored){}
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Flight Reservations Management</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f5f5f5; }
        .container { max-width: 1000px; margin: 50px auto; background: white; padding: 20px; border-radius: 5px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h2 { color: #333; }
        form { margin-bottom: 20px; }
        label { margin-right: 10px; }
        input, select { padding: 6px; margin-right: 10px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { padding: 8px; border: 1px solid #ddd; text-align: left; }
        th { background-color: #f2f2f2; }
        .button { padding: 6px 12px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 4px; }
        .button:hover { background-color: #45a049; }
        .error { color: #d9534f; }
    </style>
</head>
<body>
    <div class="container">
        <h2>Manage Flight Reservations</h2>
        <div style="text-align: right; margin-bottom: 20px;">
            <a href="repDashboard.jsp" class="button">Back to Dashboard</a>
        </div>
        <% if (!message.isEmpty()) { %>
            <p class="error"><%= message %></p>
        <% } %>
        <form method="get" action="repFlightReservations.jsp">
            <label for="targetUser">Customer User ID:</label>
            <input type="text" name="targetUser" id="targetUser" value="<%= targetUser!=null?targetUser:"" %>" required />
            <button type="submit" class="button">Load Customer</button>
        </form>
        <% if (targetUser != null && !targetUser.isEmpty()) { %>
            <h3>Existing Upcoming Reservations for <%= targetUser %></h3>
            <% if (existing.isEmpty()) { %>
                <p>No upcoming reservations found.</p>
            <% } else { %>
                <table>
                    <tr><th>Ticket ID</th><th>Flight</th><th>Date</th><th>Seat</th><th>Fare</th><th>Actions</th></tr>
                    <% for (Map<String,Object> rec : existing) { %>
                        <tr>
                            <td><%= rec.get("ticketId") %></td>
                            <td><%= rec.get("airlineName") %> <%= rec.get("flightNumber") %></td>
                            <td><%= rec.get("travelDate") %></td>
                            <td><%= rec.get("seatNo") %></td>
                            <td><%= rec.get("fare") %></td>
                            <td>
                                <a href="repEditReservation.jsp?ticketId=<%= rec.get("ticketId") %>&targetUser=<%= targetUser %>" class="button">Edit</a>
                                <a href="repCancelReservation.jsp?ticketId=<%= rec.get("ticketId") %>&targetUser=<%= targetUser %>" class="button">Cancel</a>
                            </td>
                        </tr>
                    <% } %>
                </table>
            <% } %>
            <hr />
            <h3>Search Flights to Book</h3>
            <form method="get" action="repFlightReservations.jsp">
                <input type="hidden" name="targetUser" value="<%= targetUser %>" />
                <label for="depAirport">From:</label>
                <input type="text" name="depAirport" id="depAirport" required />
                <label for="arrAirport">To:</label>
                <input type="text" name="arrAirport" id="arrAirport" required />
                <label for="travelDate">Date:</label>
                <input type="date" name="travelDate" id="travelDate" required />
                <button type="submit" class="button">Search Flights</button>
            </form>
            <% if (!searchResults.isEmpty()) { %>
                <h3>Available Flights</h3>
                <table>
                    <tr><th>Flight</th><th>Date</th><th>Departure</th><th>Arrival</th><th>Fare</th><th>Action</th></tr>
                    <% for (Map<String,Object> f : searchResults) { %>
                        <tr>
                            <td><%= f.get("airlineName") %> <%= f.get("flightNumber") %></td>
                            <td><%= f.get("travelDate") %></td>
                            <td><%= f.get("depTime") %></td>
                            <td><%= f.get("arrTime") %></td>
                            <td><%= f.get("fare") %></td>
                            <td>
                                <a href="repBookFlight.jsp?targetUser=<%= targetUser %>&flightNumber=<%= f.get("flightNumber") %>&aircraftId=<%= f.get("aircraftId") %>" class="button">Book</a>
                            </td>
                        </tr>
                    <% } %>
                </table>
            <% } %>
        <% } %>
    </div>
</body>
</html> 