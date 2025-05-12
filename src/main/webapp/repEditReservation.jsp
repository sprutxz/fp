<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.auth.DatabaseConnection" %>
<%
    // Check rep role
    if (session.getAttribute("userId") == null || !"customer_rep".equals(session.getAttribute("userRole"))) {
        response.sendRedirect("login.jsp"); return;
    }
    String ticketId = request.getParameter("ticketId");
    String targetUser = request.getParameter("targetUser");
    String message = "";
    boolean loaded = false;
    Map<String,Object> reservation = new HashMap<>();
    List<Map<String,Object>> availableSeats = new ArrayList<>();
    
    try (Connection conn = DatabaseConnection.getConnection()) {
        // Load existing reservation details
        String loadSql = "SELECT t.type, t.date, t.seat_no, t.aircraft_id, t.flight_number, t.fare, f.airline_id " +
                         "FROM Ticket t JOIN Flight f ON t.flight_number = f.flight_number " +
                         "WHERE t.ticket_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(loadSql)) {
            ps.setString(1, ticketId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    reservation.put("ticketType", rs.getString("type"));
                    reservation.put("travelDate", rs.getDate("date"));
                    reservation.put("seatNo", rs.getString("seat_no"));
                    reservation.put("aircraftId", rs.getString("aircraft_id"));
                    reservation.put("flightNumber", rs.getString("flight_number"));
                    reservation.put("fare", rs.getBigDecimal("fare"));
                    reservation.put("airlineId", rs.getString("airline_id"));
                    loaded = true;
                }
            }
        }
        if (loaded) {
            // Fetch available seats (excluding other tickets)
            String seatsSql = "SELECT s.seat_no, s.class FROM Seat s " +
                              "WHERE s.aircraft_id = ? " +
                              "AND s.seat_no NOT IN (" +
                              "    SELECT t2.seat_no FROM Ticket t2 " +
                              "    WHERE t2.flight_number = ? AND t2.aircraft_id = ? AND t2.date = ? AND t2.ticket_id <> ?" +
                              ")";
            try (PreparedStatement ps = conn.prepareStatement(seatsSql)) {
                ps.setString(1, (String) reservation.get("aircraftId"));
                ps.setString(2, (String) reservation.get("flightNumber"));
                ps.setString(3, (String) reservation.get("aircraftId"));
                ps.setDate(4, (java.sql.Date) reservation.get("travelDate"));
                ps.setString(5, ticketId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String,Object> seat = new HashMap<>();
                        seat.put("seatNo", rs.getString("seat_no"));
                        seat.put("class", rs.getString("class"));
                        availableSeats.add(seat);
                    }
                }
            }
        }
        // Handle update
        if ("POST".equalsIgnoreCase(request.getMethod())) {
            String newSeat = request.getParameter("seatNo");
            String newType = request.getParameter("ticketType");
            conn.setAutoCommit(false);
            // Update Ticket
            String updTicket = "UPDATE Ticket SET seat_no = ?, type = ? WHERE ticket_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(updTicket)) {
                ps.setString(1, newSeat);
                ps.setString(2, newType);
                ps.setString(3, ticketId);
                ps.executeUpdate();
            }
            // Update Travel
            String updTravel = "UPDATE Travel SET seat_no = ? " +
                               "WHERE user_id = ? AND flight_number = ? AND airline_id = ? AND travel_date = ?";
            try (PreparedStatement ps = conn.prepareStatement(updTravel)) {
                ps.setString(1, newSeat);
                ps.setString(2, targetUser);
                ps.setString(3, (String) reservation.get("flightNumber"));
                ps.setString(4, (String) reservation.get("airlineId"));
                ps.setDate(5, (java.sql.Date) reservation.get("travelDate"));
                ps.executeUpdate();
            }
            conn.commit(); conn.setAutoCommit(true);
            message = "Reservation updated successfully.";
        }
    } catch (Exception e) {
        message = "Error: " + e.getMessage();
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Edit Reservation</title>
    <style>
        body { font-family: Arial, sans-serif; background: #f5f5f5; }
        .container { max-width: 600px; margin: 50px auto; background: white; padding: 20px; border-radius: 5px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        .button { padding: 8px 16px; background: #4CAF50; color: white; text-decoration: none; border-radius: 4px; }
        .button:hover { background: #45a049; }
        .message { padding: 10px; margin-bottom: 20px; border-radius: 4px; }
        .success { background: #d4edda; color: #155724; }
        .error { background: #f8d7da; color: #721c24; }
    </style>
</head>
<body>
    <div class="container">
        <h2>Edit Reservation</h2>
        <div style="text-align: right; margin-bottom: 20px;">
            <a href="repFlightReservations.jsp?targetUser=<%= targetUser %>" class="button">Back to Reservations</a>
        </div>
        <% if (!message.isEmpty()) { %>
            <div class="message <%= message.startsWith("Error") ? "error" : "success" %>"><%= message %></div>
        <% } %>
        <% if (!loaded) { %>
            <p>Reservation not found.</p>
        <% } else { %>
            <p><strong>Flight:</strong> <%= reservation.get("flightNumber") %></p>
            <p><strong>Date:</strong> <%= reservation.get("travelDate") %></p>
            <p><strong>Fare:</strong> <%= reservation.get("fare") %></p>
            <form method="post">
                <label for="seatNo">Seat:</label>
                <select name="seatNo" id="seatNo">
                    <% for (Map<String,Object> seat : availableSeats) { %>
                        <option value="<%= seat.get("seatNo") %>" <%= seat.get("seatNo").equals(reservation.get("seatNo")) ? "selected" : "" %>><%= seat.get("seatNo") %> - <%= seat.get("class") %></option>
                    <% } %>
                </select>
                <label for="ticketType">Class:</label>
                <select name="ticketType" id="ticketType">
                    <option value="Economy" <%= "Economy".equals(reservation.get("ticketType")) ? "selected" : "" %>>Economy</option>
                    <option value="Business" <%= "Business".equals(reservation.get("ticketType")) ? "selected" : "" %>>Business</option>
                    <option value="First" <%= "First".equals(reservation.get("ticketType")) ? "selected" : "" %>>First</option>
                </select>
                <button type="submit" class="button">Update Reservation</button>
            </form>
        <% } %>
    </div>
</body>
</html> 