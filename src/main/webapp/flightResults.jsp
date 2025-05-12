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
        .book-button {
            padding: 5px 10px;
            background-color: #4285F4;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            font-size: 0.9em;
        }
        .book-button:hover {
            background-color: #3367D6;
        }
        .filter-sort-container form {
            display: flex;
            flex-direction: column;
        }
        .filter-sort-container form .form-group {
            margin-bottom: 10px;
        }
        .filter-sort-container form .filter-row {
            display: flex;
            gap: 20px;
        }
        .filter-sort-container form .filter-row .form-group {
            margin-bottom: 0;
            flex: 1;
        }
    </style>
</head>
<body>
    <div class="container">
        <h2>Flight Search Results</h2>
        <div class="filter-sort-container">
            <form action="flightSearchProcess.jsp" method="post">
                <input type="hidden" name="depAirport" value="<%= request.getParameter("depAirport") %>" />
                <input type="hidden" name="arrAirport" value="<%= request.getParameter("arrAirport") %>" />
                <input type="hidden" name="depDate" value="<%= request.getParameter("depDate") %>" />
                <input type="hidden" name="tripType" value="<%= request.getParameter("tripType") %>" />
                <% if ("roundtrip".equals(request.getParameter("tripType"))) { %>
                    <input type="hidden" name="returnDate" value="<%= request.getParameter("returnDate") %>" />
                <% } %>
                <% if (request.getParameter("flexible") != null) { %>
                    <input type="hidden" name="flexible" value="on" />
                <% } %>
                <div class="form-group">
                    <label for="sortBy">Sort by:</label>
                    <select name="sortBy" id="sortBy">
                        <option value="" <%= "".equals(request.getParameter("sortBy")) ? "selected" : "" %>>None</option>
                        <option value="fare" <%= "fare".equals(request.getParameter("sortBy")) ? "selected" : "" %>>Fare</option>
                        <option value="dep_time" <%= "dep_time".equals(request.getParameter("sortBy")) ? "selected" : "" %>>Departure Time</option>
                        <option value="arr_time" <%= "arr_time".equals(request.getParameter("sortBy")) ? "selected" : "" %>>Arrival Time</option>
                        <option value="duration" <%= "duration".equals(request.getParameter("sortBy")) ? "selected" : "" %>>Duration</option>
                    </select>
                </div>
                <div class="filter-row">
                    <div class="form-group">
                        <label for="minFare">Min Fare:</label>
                        <input type="number" name="minFare" id="minFare" step="0.01" value="<%= request.getParameter("minFare") != null ? request.getParameter("minFare") : "" %>" />
                    </div>
                    <div class="form-group">
                        <label for="maxFare">Max Fare:</label>
                        <input type="number" name="maxFare" id="maxFare" step="0.01" value="<%= request.getParameter("maxFare") != null ? request.getParameter("maxFare") : "" %>" />
                    </div>
                </div>
                <div class="form-group">
                    <label for="airlineNameFilter">Airline Name:</label>
                    <input type="text" name="airlineNameFilter" id="airlineNameFilter" value="<%= request.getParameter("airlineNameFilter") != null ? request.getParameter("airlineNameFilter") : "" %>" />
                </div>
                <div class="filter-row">
                    <div class="form-group">
                        <label for="minDepTime">Earliest Dep:</label>
                        <input type="time" name="minDepTime" id="minDepTime" value="<%= request.getParameter("minDepTime") != null ? request.getParameter("minDepTime") : "" %>" />
                    </div>
                    <div class="form-group">
                        <label for="maxDepTime">Latest Dep:</label>
                        <input type="time" name="maxDepTime" id="maxDepTime" value="<%= request.getParameter("maxDepTime") != null ? request.getParameter("maxDepTime") : "" %>" />
                    </div>
                </div>
                <div class="filter-row">
                    <div class="form-group">
                        <label for="minArrTime">Earliest Arr:</label>
                        <input type="time" name="minArrTime" id="minArrTime" value="<%= request.getParameter("minArrTime") != null ? request.getParameter("minArrTime") : "" %>" />
                    </div>
                    <div class="form-group">
                        <label for="maxArrTime">Latest Arr:</label>
                        <input type="time" name="maxArrTime" id="maxArrTime" value="<%= request.getParameter("maxArrTime") != null ? request.getParameter("maxArrTime") : "" %>" />
                    </div>
                </div>
                <div class="form-group">
                    <button type="submit">Apply Filters/Sort</button>
                </div>
            </form>
        </div>
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
                    <th>Action</th>
                </tr>
                <% for (Flight f : outboundFlights) { %>
                    <tr>
                        <td><%= f.getTravelDate() %></td>
                        <td><%= f.getFlightNumber() %></td>
                        <td><%= f.getDepAirportId() %> to <%= f.getArrAirportId() %></td>
                        <td><%= f.getDepTime() %> - <%= f.getArrTime() %></td>
                        <td><%= f.getAirlineName() %></td>
                        <td><%= f.getFare() %></td>
                        <td>
                            <a href="bookFlight.jsp?flightNumber=<%= f.getFlightNumber() %>&travelDate=<%= f.getTravelDate() %>&airlineId=<%= f.getAirlineId() %>&aircraftId=<%= f.getAircraftId() %>&fare=<%= f.getFare() %>" class="book-button">Book</a>
                        </td>
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
                        <th>Action</th>
                    </tr>
                    <% for (Flight f : returnFlights) { %>
                        <tr>
                            <td><%= f.getTravelDate() %></td>
                            <td><%= f.getFlightNumber() %></td>
                            <td><%= f.getDepAirportId() %> to <%= f.getArrAirportId() %></td>
                            <td><%= f.getDepTime() %> - <%= f.getArrTime() %></td>
                            <td><%= f.getAirlineName() %></td>
                            <td><%= f.getFare() %></td>
                            <td>
                                <a href="bookFlight.jsp?flightNumber=<%= f.getFlightNumber() %>&travelDate=<%= f.getTravelDate() %>&airlineId=<%= f.getAirlineId() %>&aircraftId=<%= f.getAircraftId() %>&fare=<%= f.getFare() %>" class="book-button">Book</a>
                            </td>
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