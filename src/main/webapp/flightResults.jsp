<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.auth.Flight" %>
<%@ page import="java.util.List" %>
<%@ page import="java.sql.Date" %>
<%
    String tripType = (String) request.getAttribute("tripType");
    List<Flight> outboundFlights = (List<Flight>) request.getAttribute("outboundFlights");
    List<Flight> returnFlights = (List<Flight>) request.getAttribute("returnFlights");
    String error = (String) request.getAttribute("error");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Flight Search Results</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
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
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 8px;
            border: 1px solid #ddd;
            text-align: center;
        }
        th {
            background-color: #f2f2f2;
        }
        .error-message {
            color: red;
            margin-bottom: 15px;
        }
        .button {
            display: inline-block;
            padding: 8px 16px;
            background-color: #4CAF50;
            color: white;
            text-decoration: none;
            border-radius: 4px;
        }
        .button:hover {
            background-color: #45a049;
        }
    </style>
</head>
<body>
    <div class="container">
        <h2>Flight Search Results</h2>
        <% if (error != null) { %>
            <div class="error-message"><%= error %></div>
        <% } else { %>
            <h3>Outbound Flights</h3>
            <table>
                <tr>
                    <th>Date</th>
                    <th>Flight No.</th>
                    <th>Route</th>
                    <th>Times</th>
                    <th>Airline</th>
                    <th>Fare</th>
                </tr>
                <% for (Flight f : outboundFlights) { %>
                    <tr>
                        <td><%= f.getTravelDate() %></td>
                        <td><%= f.getFlightNumber() %></td>
                        <td><%= f.getDepAirportId() %> to <%= f.getArrAirportId() %></td>
                        <td><%= f.getDepTime() %> - <%= f.getArrTime() %></td>
                        <td><%= f.getAirlineId() %></td>
                        <td><%= f.getFare() %></td>
                    </tr>
                <% } %>
            </table>
            <% if ("roundtrip".equals(tripType)) { %>
                <h3>Return Flights</h3>
                <table>
                    <tr>
                        <th>Date</th>
                        <th>Flight No.</th>
                        <th>Route</th>
                        <th>Times</th>
                        <th>Airline</th>
                        <th>Fare</th>
                    </tr>
                    <% for (Flight f : returnFlights) { %>
                        <tr>
                            <td><%= f.getTravelDate() %></td>
                            <td><%= f.getFlightNumber() %></td>
                            <td><%= f.getDepAirportId() %> to <%= f.getArrAirportId() %></td>
                            <td><%= f.getDepTime() %> - <%= f.getArrTime() %></td>
                            <td><%= f.getAirlineId() %></td>
                            <td><%= f.getFare() %></td>
                        </tr>
                    <% } %>
                </table>
            <% } %>
        <% } %>
        <a href="flightSearch.jsp" class="button">New Search</a>
        <a href="dashboard.jsp" class="button">Back to Dashboard</a>
    </div>
</body>
</html> 