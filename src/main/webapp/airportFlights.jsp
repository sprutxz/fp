<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.auth.DatabaseConnection" %>
<%
    if (session.getAttribute("userId")==null || !"customer_rep".equals(session.getAttribute("userRole"))) { response.sendRedirect("login.jsp"); return; }
    String airportId = request.getParameter("airportId");
    String message="";
    List<Map<String,Object>> departing=new ArrayList<>();
    List<Map<String,Object>> arriving=new ArrayList<>();
    if (airportId!=null && !airportId.isEmpty()) {
        try (Connection conn=DatabaseConnection.getConnection()) {
            // Departing
            try (PreparedStatement stmt=conn.prepareStatement("SELECT f.flight_number, a.airline_name, f.dep_time, f.arr_time, f.arr_airport_id FROM Flight f JOIN Airline a ON f.airline_id=a.airline_id WHERE f.dep_airport_id = ?")) {
                stmt.setString(1, airportId);
                try (ResultSet rs=stmt.executeQuery()) {
                    while (rs.next()) {
                        Map<String,Object> m=new HashMap<>();
                        m.put("flightNumber", rs.getString("flight_number"));
                        m.put("airlineName", rs.getString("airline_name"));
                        m.put("depTime", rs.getTime("dep_time"));
                        m.put("arrTime", rs.getTime("arr_time"));
                        m.put("otherAirport", rs.getString("arr_airport_id"));
                        departing.add(m);
                    }
                }
            }
            // Arriving
            try (PreparedStatement stmt=conn.prepareStatement("SELECT f.flight_number, a.airline_name, f.dep_time, f.arr_time, f.dep_airport_id FROM Flight f JOIN Airline a ON f.airline_id=a.airline_id WHERE f.arr_airport_id = ?")) {
                stmt.setString(1, airportId);
                try (ResultSet rs=stmt.executeQuery()) {
                    while (rs.next()) {
                        Map<String,Object> m=new HashMap<>();
                        m.put("flightNumber", rs.getString("flight_number"));
                        m.put("airlineName", rs.getString("airline_name"));
                        m.put("depTime", rs.getTime("dep_time"));
                        m.put("arrTime", rs.getTime("arr_time"));
                        m.put("otherAirport", rs.getString("dep_airport_id"));
                        arriving.add(m);
                    }
                }
            }
        } catch (Exception e) { message="Error: "+e.getMessage(); }
    }
%>
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Flights by Airport</title><style>table,th,td{border:1px solid #ddd;border-collapse:collapse;padding:8px;}th{background:#f2f2f2;} .button{padding:6px 12px;background:#4CAF50;color:white;text-decoration:none;border-radius:4px;} .error{color:red;} h3{margin-top:20px;} </style></head>
<body>
    <h2>Flights for Airport</h2>
    <div style="text-align: right; margin-bottom: 20px;">
        <a href="repDashboard.jsp" class="button">Back to Dashboard</a>
    </div>
    <form method="get" action="airportFlights.jsp">
        <label>Airport ID: <input type="text" name="airportId" value="<%= airportId!=null?airportId:"" %>" required/></label>
        <button type="submit" class="button">Search</button>
    </form>
    <% if (!message.isEmpty()) { %><p class="error"><%=message%></p><% } %>
    <% if (airportId!=null && !airportId.isEmpty()) { %>
        <h3>Departing Flights from <%= airportId %></h3>
        <% if (departing.isEmpty()) { %><p>No departing flights.</p><% } else { %>
            <table><tr><th>Flight</th><th>Airline</th><th>Dep Time</th><th>Arr Time</th><th>Arriving Airport</th></tr>
            <% for(Map<String,Object> m: departing) { %>
                <tr><td><%=m.get("flightNumber")%></td><td><%=m.get("airlineName")%></td><td><%=m.get("depTime")%></td><td><%=m.get("arrTime")%></td><td><%=m.get("otherAirport")%></td></tr>
            <% } %></table>
        <% } %>
        <h3>Arriving Flights to <%= airportId %></h3>
        <% if (arriving.isEmpty()) { %><p>No arriving flights.</p><% } else { %>
            <table><tr><th>Flight</th><th>Airline</th><th>Dep Time</th><th>Arr Time</th><th>Departing Airport</th></tr>
            <% for(Map<String,Object> m: arriving) { %>
                <tr><td><%=m.get("flightNumber")%></td><td><%=m.get("airlineName")%></td><td><%=m.get("depTime")%></td><td><%=m.get("arrTime")%></td><td><%=m.get("otherAirport")%></td></tr>
            <% } %></table>
        <% } %>
    <% } %>
</body>
</html> 