<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Check if user is logged in
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Dashboard</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 800px;
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
        h1 {
            color: #333;
            margin: 0;
        }
        .user-info {
            display: flex;
            align-items: center;
        }
        .username {
            margin-right: 15px;
            font-weight: bold;
        }
        .logout-button {
            padding: 8px 16px;
            background-color: #f44336;
            color: white;
            text-decoration: none;
            border-radius: 4px;
        }
        .logout-button:hover {
            background-color: #d32f2f;
        }
        .button {
            padding: 8px 16px;
            background-color: #4CAF50;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            margin-top: 15px;
        }
        .button:hover {
            background-color: #45a049;
        }
        .content {
            padding: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Dashboard</h1>
            <div class="user-info">
                <span class="username">Welcome, <%= session.getAttribute("firstName") %> <%= session.getAttribute("lastName") %>!</span>
                <a href="logout.jsp" class="logout-button">Logout</a>
            </div>
        </header>
        <div class="content">
            <h2>Your Dashboard Content</h2>
            <p>This is a secure area only accessible to logged-in users.</p>
            <p>You have successfully authenticated with the system.</p>
            <a href="flightSearch.jsp" class="button">Search Flights</a>
        </div>
    </div>
</body>
</html>