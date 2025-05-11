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
    List<Map<String, Object>> pastFlights = new ArrayList<>();
    String errorMessage = "";
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = DatabaseConnection.getConnection();
        
        // Get all past flights for the current user (where travel_date is in the past)
        String sql = "SELECT t.ticket_id, t.type as ticket_type, t.fare, t.date, t.seat_no, " +
                     "f.flight_number, f.flight_type, f.dep_time, f.arr_time, " +
                     "f.dep_airport_id, f.arr_airport_id, a.airline_id, a.airline_name, tr.booking_fee " +
                     "FROM Ticket t " +
                     "JOIN Travel tr ON t.user_id = tr.user_id AND t.flight_number = tr.flight_number AND t.seat_no = tr.seat_no " +
                     "JOIN Flight f ON t.flight_number = f.flight_number " +
                     "JOIN Airline a ON f.airline_id = a.airline_id " +
                     "WHERE t.user_id = ? AND t.date < CURRENT_DATE " +
                     "ORDER BY t.date DESC";
        
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
            pastFlights.add(flight);
        }
    } catch (Exception e) {
        errorMessage = "Error retrieving past flights: " + e.getMessage();
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
    <title>Past Flights</title>
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
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Past Flight Reservations</h1>
            <a href="dashboard.jsp" class="button">Back to Dashboard</a>
        </header>
        
        <% if (!errorMessage.isEmpty()) { %>
            <div class="error-message"><%= errorMessage %></div>
        <% } %>
        
        <div class="flights-container">
            <% if (pastFlights.isEmpty()) { %>
                <div class="empty-state">
                    <h2>No Past Flights Found</h2>
                    <p>You don't have any past flight reservations.</p>
                </div>
            <% } else { %>
                <% for (Map<String, Object> flight : pastFlights) { %>
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
                            </div>
                        </div>
                    </div>
                <% } %>
            <% } %>
        </div>
    </div>
</body>
</html> 