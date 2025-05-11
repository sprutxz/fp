<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Ensure user is logged in
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Search Flights</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            background-color: #f5f5f5;
        }
        .search-container {
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            width: 400px;
        }
        h2 {
            text-align: center;
            color: #333;
        }
        .form-group {
            margin-bottom: 15px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
        }
        input[type="text"], input[type="date"] {
            width: 100%;
            padding: 8px;
            box-sizing: border-box;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        .options {
            margin-bottom: 15px;
        }
        .options label {
            margin-right: 10px;
            font-weight: normal;
        }
        button {
            width: 100%;
            padding: 10px;
            background-color: #4CAF50;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
        }
        button:hover {
            background-color: #45a049;
        }
    </style>
    <script>
        function toggleReturn() {
            var tripType = document.querySelector('input[name="tripType"]:checked').value;
            document.getElementById('returnDateGroup').style.display = tripType === 'roundtrip' ? 'block' : 'none';
        }
        window.onload = function() { toggleReturn(); };
    </script>
</head>
<body>
    <div class="search-container">
        <h2>Search Flights</h2>
        <form action="flightSearchProcess.jsp" method="post">
            <div class="options">
                <label><input type="radio" name="tripType" value="oneway" checked onchange="toggleReturn()"> One-way</label>
                <label><input type="radio" name="tripType" value="roundtrip" onchange="toggleReturn()"> Round-trip</label>
            </div>
            <div class="form-group">
                <label for="depAirport">Departure Airport ID:</label>
                <input type="text" id="depAirport" name="depAirport" required>
            </div>
            <div class="form-group">
                <label for="arrAirport">Arrival Airport ID:</label>
                <input type="text" id="arrAirport" name="arrAirport" required>
            </div>
            <div class="form-group">
                <label for="depDate">Departure Date:</label>
                <input type="date" id="depDate" name="depDate" required>
            </div>
            <div class="form-group" id="returnDateGroup" style="display:none;">
                <label for="returnDate">Return Date:</label>
                <input type="date" id="returnDate" name="returnDate">
            </div>
            <div class="form-group">
                <label><input type="checkbox" name="flexible"> Flexible Dates (+/- 3 days)</label>
            </div>
            <div class="form-group">
                <label for="sortBy">Sort by:</label>
                <select id="sortBy" name="sortBy">
                    <option value="">None</option>
                    <option value="fare">Fare</option>
                    <option value="dep_time">Departure Time</option>
                    <option value="arr_time">Arrival Time</option>
                    <option value="duration">Duration</option>
                </select>
            </div>
            <div class="form-group">
                <label for="minFare">Min Fare:</label>
                <input type="number" id="minFare" name="minFare" step="0.01">
            </div>
            <div class="form-group">
                <label for="maxFare">Max Fare:</label>
                <input type="number" id="maxFare" name="maxFare" step="0.01">
            </div>
            <div class="form-group">
                <label for="airlineFilter">Airline ID:</label>
                <input type="text" id="airlineFilter" name="airlineFilter">
            </div>
            <div class="form-group">
                <label for="minDepTime">Earliest Departure:</label>
                <input type="time" id="minDepTime" name="minDepTime">
            </div>
            <div class="form-group">
                <label for="maxDepTime">Latest Departure:</label>
                <input type="time" id="maxDepTime" name="maxDepTime">
            </div>
            <div class="form-group">
                <label for="minArrTime">Earliest Arrival:</label>
                <input type="time" id="minArrTime" name="minArrTime">
            </div>
            <div class="form-group">
                <label for="maxArrTime">Latest Arrival:</label>
                <input type="time" id="maxArrTime" name="maxArrTime">
            </div>
            <button type="submit">Search Flights</button>
        </form>
    </div>
</body>
</html> 