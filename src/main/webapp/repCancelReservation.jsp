<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="com.auth.DatabaseConnection" %>
<%
    // Check rep role
    if (session.getAttribute("userId") == null || !"customer_rep".equals(session.getAttribute("userRole"))) {
        response.sendRedirect("login.jsp"); return;
    }
    String ticketId = request.getParameter("ticketId");
    String targetUser = request.getParameter("targetUser");
    String message = "";
    if (ticketId != null && !ticketId.isEmpty()) {
        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            // Retrieve reservation details
            String fetchSql = "SELECT t.user_id, t.flight_number, t.seat_no, t.aircraft_id, t.date, f.airline_id " +
                              "FROM Ticket t JOIN Flight f ON t.flight_number = f.flight_number " +
                              "WHERE t.ticket_id = ?";
            String userId = null, flightNumber = null, seatNo = null, aircraftId = null, airlineId = null;
            Date travelDate = null;
            try (PreparedStatement ps = conn.prepareStatement(fetchSql)) {
                ps.setString(1, ticketId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        userId = rs.getString("user_id");
                        flightNumber = rs.getString("flight_number");
                        seatNo = rs.getString("seat_no");
                        aircraftId = rs.getString("aircraft_id");
                        travelDate = rs.getDate("date");
                        airlineId = rs.getString("airline_id");
                    }
                }
            }
            if (userId != null) {
                // Delete from Travel
                String delTravel = "DELETE FROM Travel WHERE user_id = ? AND flight_number = ? AND airline_id = ? AND travel_date = ? AND seat_no = ? AND aircraft_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(delTravel)) {
                    ps.setString(1, userId);
                    ps.setString(2, flightNumber);
                    ps.setString(3, airlineId);
                    ps.setDate(4, travelDate);
                    ps.setString(5, seatNo);
                    ps.setString(6, aircraftId);
                    ps.executeUpdate();
                }
                // Delete from Ticket
                String delTicket = "DELETE FROM Ticket WHERE ticket_id = ?";
                int deleted;
                try (PreparedStatement ps = conn.prepareStatement(delTicket)) {
                    ps.setString(1, ticketId);
                    deleted = ps.executeUpdate();
                }
                conn.commit(); conn.setAutoCommit(true);
                if (deleted > 0) {
                    message = "Reservation cancelled successfully.";
                } else {
                    message = "Failed to cancel reservation.";
                }
            } else {
                message = "Reservation not found.";
            }
        } catch (Exception e) {
            message = "Error cancelling reservation: " + e.getMessage();
        }
    } else {
        message = "Ticket ID not provided.";
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Cancel Reservation</title>
    <style>
        body { font-family: Arial, sans-serif; background: #f5f5f5; }
        .container { max-width: 600px; margin: 50px auto; background: white; padding: 20px; border-radius: 5px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        .message { padding: 10px; margin-bottom: 20px; border-radius: 4px; }
        .success { background: #d4edda; color: #155724; }
        .error { background: #f8d7da; color: #721c24; }
        .button { padding: 8px 16px; background: #4CAF50; color: white; text-decoration: none; border-radius: 4px; }
        .button:hover { background: #45a049; }
    </style>
</head>
<body>
    <div class="container">
        <h2>Cancel Reservation</h2>
        <div class="message <%= message.startsWith("Error") ? "error" : "success" %>"><%= message %></div>
        <div style="text-align: right;">
            <a href="repFlightReservations.jsp?targetUser=<%= targetUser %>" class="button">Back to Reservations</a>
        </div>
    </div>
</body>
</html> 