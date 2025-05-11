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
    List<Map<String, Object>> cancelableFlights = new ArrayList<>();
    String errorMessage = "";
    String successMessage = "";
    
    // Check for cancel action
    String action = request.getParameter("action");
    String ticketId = request.getParameter("ticketId");
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = DatabaseConnection.getConnection();
        
        // Process cancellation if requested
        if ("cancel".equals(action) && ticketId != null && !ticketId.isEmpty()) {
            // First, check if the ticket exists and is eligible for cancellation
            String checkSql = "SELECT t.ticket_id, t.type, t.flight_number, t.aircraft_id, t.seat_no, t.date " +
                              "FROM Ticket t " +
                              "WHERE t.ticket_id = ? AND t.user_id = ? " +
                              "AND (t.type = 'Business' OR t.type = 'First') " +
                              "AND t.date >= CURRENT_DATE";
            
            pstmt = conn.prepareStatement(checkSql);
            pstmt.setString(1, ticketId);
            pstmt.setString(2, userId);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                String flightNumber = rs.getString("flight_number");
                String aircraftId = rs.getString("aircraft_id");
                String seatNo = rs.getString("seat_no");
                Date travelDate = rs.getDate("date");
                
                // Begin transaction
                conn.setAutoCommit(false);
                
                try {
                    // Delete from Travel table
                    String deleteTravel = "DELETE FROM Travel " +
                                         "WHERE user_id = ? AND flight_number = ? " +
                                         "AND seat_no = ? AND aircraft_id = ? " +
                                         "AND travel_date = ?";
                    pstmt = conn.prepareStatement(deleteTravel);
                    pstmt.setString(1, userId);
                    pstmt.setString(2, flightNumber);
                    pstmt.setString(3, seatNo);
                    pstmt.setString(4, aircraftId);
                    pstmt.setDate(5, travelDate);
                    pstmt.executeUpdate();
                    
                    // Delete from Ticket table
                    String deleteTicket = "DELETE FROM Ticket " +
                                         "WHERE ticket_id = ? AND user_id = ?";
                    pstmt = conn.prepareStatement(deleteTicket);
                    pstmt.setString(1, ticketId);
                    pstmt.setString(2, userId);
                    pstmt.executeUpdate();
                    
                    // Check if there are any waiting list entries for this flight
                    String checkWaitlist = "SELECT w.user_id, w.request_date " +
                                          "FROM Waiting_List w " +
                                          "WHERE w.flight_number = ? " +
                                          "AND w.status = 'waiting' " +
                                          "ORDER BY w.request_date ASC " +
                                          "LIMIT 1";
                    pstmt = conn.prepareStatement(checkWaitlist);
                    pstmt.setString(1, flightNumber);
                    rs = pstmt.executeQuery();
                    
                    if (rs.next()) {
                        // There's someone on the waiting list
                        String waitingUserId = rs.getString("user_id");
                        
                        // Update their waiting list status to 'notified'
                        String updateWaitlist = "UPDATE Waiting_List " +
                                             "SET status = 'notified', notification_date = NOW() " +
                                             "WHERE user_id = ? AND flight_number = ? AND status = 'waiting'";
                        pstmt = conn.prepareStatement(updateWaitlist);
                        pstmt.setString(1, waitingUserId);
                        pstmt.setString(2, flightNumber);
                        pstmt.executeUpdate();
                        
                        // Insert notification
                        String insertNotification = "INSERT INTO Notification (user_id, message, notification_date, is_read) " +
                                                 "VALUES (?, ?, NOW(), 0)";
                        pstmt = conn.prepareStatement(insertNotification);
                        pstmt.setString(1, waitingUserId);
                        pstmt.setString(2, "A seat is now available on flight " + flightNumber + " on " + travelDate + ". Please book your ticket soon!");
                        pstmt.executeUpdate();
                    }
                    
                    // Commit transaction
                    conn.commit();
                    successMessage = "Your flight reservation has been successfully canceled.";
                } catch (SQLException e) {
                    // Rollback on error
                    conn.rollback();
                    errorMessage = "Error canceling flight: " + e.getMessage();
                } finally {
                    conn.setAutoCommit(true);
                }
            } else {
                errorMessage = "Unable to cancel this flight. Either the ticket does not exist, or it's not eligible for cancellation.";
            }
        }
        
        // Get all cancelable flights (business or first class tickets for future dates)
        String sql = "SELECT t.ticket_id, t.type as ticket_type, t.fare, t.date, t.seat_no, " +
                     "f.flight_number, f.flight_type, f.dep_time, f.arr_time, " +
                     "f.dep_airport_id, f.arr_airport_id, a.airline_id, a.airline_name, tr.booking_fee " +
                     "FROM Ticket t " +
                     "JOIN Travel tr ON t.user_id = tr.user_id AND t.flight_number = tr.flight_number AND t.seat_no = tr.seat_no " +
                     "JOIN Flight f ON t.flight_number = f.flight_number " +
                     "JOIN Airline a ON f.airline_id = a.airline_id " +
                     "WHERE t.user_id = ? AND t.date >= CURRENT_DATE " +
                     "AND (t.type = 'Business' OR t.type = 'First') " +
                     "ORDER BY t.date ASC";
        
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, userId);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> flight = new HashMap<>();
            flight.put("ticketId", rs.getString("ticket_id"));
            flight.put("ticketType", rs.getString("ticket_type"));
            flight.put("fare", rs.getBigDecimal("fare"));
            flight.put("travelDate", rs.getDate("date"));
            flight.put("seatNo", rs.getString("seat_no"));
            flight.put("flightNumber", rs.getString("flight_number"));
            flight.put("flightType", rs.getString("flight_type"));
            flight.put("depTime", rs.getTime("dep_time"));
            flight.put("arrTime", rs.getTime("arr_time"));
            flight.put("depAirport", rs.getString("dep_airport_id"));
            flight.put("arrAirport", rs.getString("arr_airport_id"));
            flight.put("airlineId", rs.getString("airline_id"));
            flight.put("airlineName", rs.getString("airline_name"));
            flight.put("bookingFee", rs.getBigDecimal("booking_fee"));
            cancelableFlights.add(flight);
        }
    } catch (Exception e) {
        errorMessage = "Error retrieving flights: " + e.getMessage();
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
    <title>Manage Bookings</title>
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
        h1, h2 {
            color: #333;
        }
        .flights-container {
            margin-top: 20px;
        }
        .flight-card {
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 15px;
            background-color: #f9f9f9;
        }
        .flight-header {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        .flight-date {
            font-weight: bold;
            color: #555;
        }
        .flight-details {
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
        .success-message {
            color: #28a745;
            padding: 10px;
            background-color: #d4edda;
            border-radius: 4px;
            margin-bottom: 15px;
        }
        .empty-state {
            text-align: center;
            padding: 40px 0;
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
        .cancel-button {
            display: inline-block;
            padding: 6px 12px;
            background-color: #dc3545;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            font-size: 0.9em;
        }
        .cancel-button:hover {
            background-color: #c82333;
        }
        .info-box {
            background-color: #e7f3fe;
            border-left: 4px solid #2196F3;
            padding: 12px;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Manage Bookings</h1>
            <a href="dashboard.jsp" class="button">Back to Dashboard</a>
        </header>
        
        <div class="info-box">
            <p>You can cancel Business Class and First Class reservations. Economy class tickets cannot be canceled.</p>
        </div>
        
        <% if (!errorMessage.isEmpty()) { %>
            <div class="error-message"><%= errorMessage %></div>
        <% } %>
        
        <% if (!successMessage.isEmpty()) { %>
            <div class="success-message"><%= successMessage %></div>
        <% } %>
        
        <div class="flights-container">
            <% if (cancelableFlights.isEmpty()) { %>
                <div class="empty-state">
                    <h2>No Cancelable Reservations</h2>
                    <p>You don't have any Business or First Class reservations that can be canceled.</p>
                    <a href="upcomingFlights.jsp" class="button">View All Upcoming Flights</a>
                </div>
            <% } else { %>
                <h2>Your Cancelable Reservations</h2>
                <% for (Map<String, Object> flight : cancelableFlights) { %>
                    <div class="flight-card">
                        <div class="flight-header">
                            <span class="flight-date"><%= flight.get("travelDate") %></span>
                            <span>Ticket ID: <%= flight.get("ticketId") %></span>
                        </div>
                        <div class="flight-details">
                            <div class="detail-column">
                                <div class="detail-group">
                                    <div class="detail-label">Flight</div>
                                    <div class="detail-value"><%= flight.get("airlineName") %> <%= flight.get("flightNumber") %></div>
                                </div>
                                <div class="detail-group">
                                    <div class="detail-label">Route</div>
                                    <div class="detail-value"><%= flight.get("depAirport") %> → <%= flight.get("arrAirport") %></div>
                                </div>
                                <div class="detail-group">
                                    <div class="detail-label">Time</div>
                                    <div class="detail-value"><%= flight.get("depTime") %> - <%= flight.get("arrTime") %></div>
                                </div>
                            </div>
                            <div class="detail-column">
                                <div class="detail-group">
                                    <div class="detail-label">Seat</div>
                                    <div class="detail-value"><%= flight.get("seatNo") %></div>
                                </div>
                                <div class="detail-group">
                                    <div class="detail-label">Class</div>
                                    <div class="detail-value"><%= flight.get("ticketType") %></div>
                                </div>
                                <div class="detail-group">
                                    <div class="detail-label">Flight Type</div>
                                    <div class="detail-value"><%= flight.get("flightType") %></div>
                                </div>
                            </div>
                            <div class="detail-column">
                                <div class="detail-group">
                                    <div class="detail-label">Fare</div>
                                    <div class="detail-value">$<%= flight.get("fare") %></div>
                                </div>
                                <div class="detail-group">
                                    <div class="detail-label">Booking Fee</div>
                                    <div class="detail-value">$<%= flight.get("bookingFee") %></div>
                                </div>
                                <div class="detail-group">
                                    <div class="detail-label">Total</div>
                                    <div class="detail-value">$<%= ((java.math.BigDecimal)flight.get("fare")).add((java.math.BigDecimal)flight.get("bookingFee")) %></div>
                                </div>
                                <div class="detail-group">
                                    <a href="manageBookings.jsp?action=cancel&ticketId=<%= flight.get("ticketId") %>" 
                                       class="cancel-button" 
                                       onclick="return confirm('Are you sure you want to cancel this reservation?');">
                                        Cancel Reservation
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                <% } %>
            <% } %>
        </div>
    </div>
</body>
</html> 