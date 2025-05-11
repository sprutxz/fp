<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="com.auth.DatabaseConnection" %>
<%@ page import="java.util.*" %>
<%@ page import="java.sql.Date" %>
<%@ page import="java.math.BigDecimal" %>

<%
    // Check if user is logged in
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    String userId = (String)session.getAttribute("userId");
    String flightNumber = request.getParameter("flightNumber");
    String travelDateStr = request.getParameter("travelDate");
    String airlineId = request.getParameter("airlineId");
    String aircraftId = request.getParameter("aircraftId");
    String fareStr = request.getParameter("fare");
    
    // Error message for notifications
    String errorMessage = "";
    String successMessage = "";
    
    // Flight details
    Map<String, Object> flightDetails = new HashMap<>();
    List<Map<String, Object>> availableSeats = new ArrayList<>();
    boolean isFullFlight = false;
    int totalSeats = 0;
    int bookedSeats = 0;
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = DatabaseConnection.getConnection();
        
        // Get flight details
        String sql = "SELECT f.flight_number, f.flight_type, f.dep_time, f.arr_time, " +
                     "f.dep_airport_id, f.arr_airport_id, f.aircraft_id, f.airline_id, " +
                     "a.airline_name, f.price " +
                     "FROM Flight f " +
                     "JOIN Airline a ON f.airline_id = a.airline_id " +
                     "WHERE f.flight_number = ?";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, flightNumber);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            flightDetails.put("flightNumber", rs.getString("flight_number"));
            flightDetails.put("flightType", rs.getString("flight_type"));
            flightDetails.put("depTime", rs.getTime("dep_time"));
            flightDetails.put("arrTime", rs.getTime("arr_time"));
            flightDetails.put("depAirport", rs.getString("dep_airport_id"));
            flightDetails.put("arrAirport", rs.getString("arr_airport_id"));
            flightDetails.put("aircraftId", rs.getString("aircraft_id"));
            flightDetails.put("airlineId", rs.getString("airline_id"));
            flightDetails.put("airlineName", rs.getString("airline_name"));
            flightDetails.put("fare", rs.getBigDecimal("price"));
            flightDetails.put("travelDate", Date.valueOf(travelDateStr));
        }
        
        // Get total seats for aircraft
        rs.close();
        pstmt.close();
        sql = "SELECT num_seats FROM Aircraft WHERE aircraft_id = ?";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, aircraftId);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            totalSeats = rs.getInt("num_seats");
        }
        
        // Get all available seats
        rs.close();
        pstmt.close();
        sql = "SELECT s.seat_no, s.class " +
              "FROM Seat s " +
              "WHERE s.aircraft_id = ? " +
              "AND s.seat_no NOT IN (" +
              "    SELECT t.seat_no " +
              "    FROM Ticket t " +
              "    WHERE t.flight_number = ? " +
              "    AND t.aircraft_id = ? " +
              "    AND t.date = ?" +
              ")";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, aircraftId);
        pstmt.setString(2, flightNumber);
        pstmt.setString(3, aircraftId);
        pstmt.setDate(4, Date.valueOf(travelDateStr));
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> seat = new HashMap<>();
            seat.put("seatNo", rs.getString("seat_no"));
            seat.put("class", rs.getString("class"));
            availableSeats.add(seat);
        }
        
        // Count booked seats
        rs.close();
        pstmt.close();
        sql = "SELECT COUNT(*) AS booked_count " +
              "FROM Ticket " +
              "WHERE flight_number = ? " +
              "AND aircraft_id = ? " +
              "AND date = ?";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, flightNumber);
        pstmt.setString(2, aircraftId);
        pstmt.setDate(3, Date.valueOf(travelDateStr));
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            bookedSeats = rs.getInt("booked_count");
        }
        
        // Check if flight is full
        isFullFlight = (availableSeats.isEmpty() || bookedSeats >= totalSeats);
        
        // Process form submission for booking
        if ("POST".equalsIgnoreCase(request.getMethod())) {
            String selectedSeat = request.getParameter("seatNo");
            String ticketType = request.getParameter("ticketType");
            
            // Check if user wants to join waiting list
            boolean joinWaitingList = "true".equals(request.getParameter("joinWaitingList"));
            
            if (joinWaitingList && isFullFlight) {
                // Add to waiting list
                rs.close();
                pstmt.close();
                sql = "INSERT INTO Waiting_List (user_id, flight_number, airline_id, request_date, status) " +
                      "VALUES (?, ?, ?, NOW(), 'waiting')";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, userId);
                pstmt.setString(2, flightNumber);
                pstmt.setString(3, airlineId);
                
                int result = pstmt.executeUpdate();
                if (result > 0) {
                    successMessage = "You have been added to the waiting list for this flight.";
                } else {
                    errorMessage = "Failed to add you to the waiting list. Please try again.";
                }
            } else if (!isFullFlight && selectedSeat != null && !selectedSeat.isEmpty()) {
                // Book the ticket
                String ticketId = "TKT" + System.currentTimeMillis();
                BigDecimal bookingFee = new BigDecimal("25.00"); // Standard booking fee
                
                // Begin transaction
                conn.setAutoCommit(false);
                
                try {
                    // Insert into Ticket table
                    pstmt.close();
                    sql = "INSERT INTO Ticket (ticket_id, user_id, type, date, seat_no, aircraft_id, flight_number, fare) " +
                          "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setString(1, ticketId);
                    pstmt.setString(2, userId);
                    pstmt.setString(3, ticketType);
                    pstmt.setDate(4, Date.valueOf(travelDateStr));
                    pstmt.setString(5, selectedSeat);
                    pstmt.setString(6, aircraftId);
                    pstmt.setString(7, flightNumber);
                    pstmt.setBigDecimal(8, new BigDecimal(fareStr));
                    pstmt.executeUpdate();
                    
                    // Insert into Travel table
                    pstmt.close();
                    sql = "INSERT INTO Travel (user_id, flight_number, airline_id, travel_date, booking_fee, seat_no, aircraft_id) " +
                          "VALUES (?, ?, ?, ?, ?, ?, ?)";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setString(1, userId);
                    pstmt.setString(2, flightNumber);
                    pstmt.setString(3, airlineId);
                    pstmt.setDate(4, Date.valueOf(travelDateStr));
                    pstmt.setBigDecimal(5, bookingFee);
                    pstmt.setString(6, selectedSeat);
                    pstmt.setString(7, aircraftId);
                    pstmt.executeUpdate();
                    
                    // Commit transaction
                    conn.commit();
                    successMessage = "Your flight has been booked successfully! Ticket ID: " + ticketId;
                    
                    // Refresh available seats after booking
                    rs.close();
                    pstmt.close();
                    sql = "SELECT s.seat_no, s.class " +
                          "FROM Seat s " +
                          "WHERE s.aircraft_id = ? " +
                          "AND s.seat_no NOT IN (" +
                          "    SELECT t.seat_no " +
                          "    FROM Ticket t " +
                          "    WHERE t.flight_number = ? " +
                          "    AND t.aircraft_id = ? " +
                          "    AND t.date = ?" +
                          ")";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setString(1, aircraftId);
                    pstmt.setString(2, flightNumber);
                    pstmt.setString(3, aircraftId);
                    pstmt.setDate(4, Date.valueOf(travelDateStr));
                    rs = pstmt.executeQuery();
                    
                    // Clear and repopulate available seats
                    availableSeats.clear();
                    while (rs.next()) {
                        Map<String, Object> seat = new HashMap<>();
                        seat.put("seatNo", rs.getString("seat_no"));
                        seat.put("class", rs.getString("class"));
                        availableSeats.add(seat);
                    }
                    
                    // Recheck if the flight is now full after booking
                    rs.close();
                    pstmt.close();
                    sql = "SELECT COUNT(*) AS booked_count " +
                          "FROM Ticket " +
                          "WHERE flight_number = ? " +
                          "AND aircraft_id = ? " +
                          "AND date = ?";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setString(1, flightNumber);
                    pstmt.setString(2, aircraftId);
                    pstmt.setDate(3, Date.valueOf(travelDateStr));
                    rs = pstmt.executeQuery();
                    
                    if (rs.next()) {
                        bookedSeats = rs.getInt("booked_count");
                    }
                    
                    isFullFlight = (availableSeats.isEmpty() || bookedSeats >= totalSeats);
                } catch (SQLException e) {
                    // Rollback in case of error
                    conn.rollback();
                    errorMessage = "Error booking flight: " + e.getMessage();
                } finally {
                    conn.setAutoCommit(true);
                }
            } else if (isFullFlight && !joinWaitingList) {
                errorMessage = "This flight is full. Please join the waiting list or select a different flight.";
            } else {
                errorMessage = "Please select a seat to book this flight.";
            }
        }
    } catch (Exception e) {
        errorMessage = "Error: " + e.getMessage();
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
    <title>Book Flight</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            padding: 0;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        h2, h3 {
            color: #333;
        }
        .flight-details {
            background-color: #f9f9f9;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            border-left: 4px solid #4285F4;
        }
        .detail-row {
            display: flex;
            margin-bottom: 8px;
        }
        .detail-label {
            font-weight: bold;
            width: 140px;
        }
        .success-message {
            padding: 10px;
            background-color: #d4edda;
            color: #155724;
            border-radius: 4px;
            margin-bottom: 20px;
        }
        .error-message {
            padding: 10px;
            background-color: #f8d7da;
            color: #721c24;
            border-radius: 4px;
            margin-bottom: 20px;
        }
        .booking-form {
            margin-top: 20px;
        }
        .form-group {
            margin-bottom: 15px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
        }
        select, input[type="submit"] {
            width: 100%;
            padding: 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        input[type="submit"] {
            background-color: #4CAF50;
            color: white;
            border: none;
            cursor: pointer;
            margin-top: 15px;
        }
        input[type="submit"]:hover {
            background-color: #45a049;
        }
        .waiting-list-note {
            margin-top: 20px;
            padding: 10px;
            background-color: #fff3cd;
            color: #856404;
            border-radius: 4px;
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
    </style>
</head>
<body>
    <div class="container">
        <h2>Book Flight</h2>
        
        <% if (!errorMessage.isEmpty()) { %>
            <div class="error-message"><%= errorMessage %></div>
        <% } %>
        
        <% if (!successMessage.isEmpty()) { %>
            <div class="success-message"><%= successMessage %></div>
        <% } %>
        
        <div class="flight-details">
            <h3>Flight Information</h3>
            <div class="detail-row">
                <div class="detail-label">Flight Number:</div>
                <div><%= flightDetails.get("flightNumber") %></div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Airline:</div>
                <div><%= flightDetails.get("airlineName") %></div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Route:</div>
                <div><%= flightDetails.get("depAirport") %> to <%= flightDetails.get("arrAirport") %></div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Date:</div>
                <div><%= flightDetails.get("travelDate") %></div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Departure:</div>
                <div><%= flightDetails.get("depTime") %></div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Arrival:</div>
                <div><%= flightDetails.get("arrTime") %></div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Base Fare:</div>
                <div>$<%= flightDetails.get("fare") %></div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Booking Fee:</div>
                <div>$25.00</div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Total:</div>
                <div>$<%= new BigDecimal(fareStr).add(new BigDecimal("25.00")) %></div>
            </div>
        </div>
        
        <% if (isFullFlight) { %>
            <div class="waiting-list-note">
                <h3>Flight is Full</h3>
                <p>This flight is currently full. You can join the waiting list to be notified if a seat becomes available.</p>
                
                <form class="booking-form" method="post">
                    <input type="hidden" name="joinWaitingList" value="true">
                    <input type="submit" value="Join Waiting List">
                </form>
            </div>
        <% } else { %>
            <form class="booking-form" method="post">
                <div class="form-group">
                    <label for="seatNo">Select Seat:</label>
                    <select name="seatNo" id="seatNo" required>
                        <option value="">-- Select a Seat --</option>
                        <% for (Map<String, Object> seat : availableSeats) { %>
                            <option value="<%= seat.get("seatNo") %>">
                                <%= seat.get("seatNo") %> (<%= seat.get("class") %> Class)
                            </option>
                        <% } %>
                    </select>
                </div>
                
                <div class="form-group">
                    <label for="ticketType">Ticket Type:</label>
                    <select name="ticketType" id="ticketType" required>
                        <option value="">-- Select Ticket Type --</option>
                        <option value="Economy">Economy</option>
                        <option value="Business">Business</option>
                        <option value="First">First Class</option>
                    </select>
                </div>
                
                <input type="submit" value="Book Flight">
            </form>
        <% } %>
        
        <a href="flightResults.jsp" class="button">Back to Flight Results</a>
        <a href="dashboard.jsp" class="button">Back to Dashboard</a>
    </div>
</body>
</html> 