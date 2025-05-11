<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.auth.User" %>
<%@ page import="com.auth.UserDAO" %>
<%@ page import="java.sql.SQLException" %>

<%
    String userId = request.getParameter("userId");
    String password = request.getParameter("password");
    
    UserDAO userDAO = new UserDAO();
    User user = null;
    boolean isValidUser = false;
    String message = "";
    
    try {
        user = userDAO.validate(userId, password);
        if (user != null) {
            isValidUser = true;
            session.setAttribute("user", user);
            session.setAttribute("userId", userId);
            session.setAttribute("firstName", user.getFirstName());
            session.setAttribute("lastName", user.getLastName());
            
            // Get and store the user's role
            String userRole = userDAO.getUserRole(userId);
            session.setAttribute("userRole", userRole);
            
            session.setMaxInactiveInterval(30*60); // 30 minutes
            message = "Login successful!";
        } else {
            message = "Invalid User ID or password";
        }
    } catch (ClassNotFoundException | SQLException e) {
        message = "An error occurred: " + e.getMessage();
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Login Result</title>
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
        .result-container {
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            max-width: 400px;
            width: 100%;
            text-align: center;
        }
        h2 {
            margin-bottom: 20px;
            color: #333;
        }
        .message {
            padding: 10px;
            margin-bottom: 20px;
            border-radius: 4px;
        }
        .success {
            background-color: #dff0d8;
            color: #3c763d;
        }
        .error {
            background-color: #f2dede;
            color: #a94442;
        }
        .button {
            display: inline-block;
            padding: 8px 16px;
            background-color: #4CAF50;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            margin: 10px 5px;
        }
        .button:hover {
            background-color: #45a049;
        }
        .logout {
            background-color: #f44336;
        }
        .logout:hover {
            background-color: #d32f2f;
        }
    </style>
</head>
<body>
    <div class="result-container">
        <h2>Login Result</h2>
        <div class="message <%= isValidUser ? "success" : "error" %>">
            <%= message %>
        </div>
        <% if (isValidUser) { %>
            <p>Welcome, <%= user.getFirstName() %> <%= user.getLastName() %>!</p>
            <%-- Redirect to appropriate dashboard based on user role --%>
            <% 
                String userRole = (String) session.getAttribute("userRole");
                String dashboardPage = "dashboard.jsp";
                
                if ("admin".equals(userRole)) {
                    dashboardPage = "adminDashboard.jsp";
                } else if ("customer_rep".equals(userRole)) {
                    dashboardPage = "repDashboard.jsp";
                }
            %>
            <a href="<%= dashboardPage %>" class="button">Go to Dashboard</a>
            <a href="logout.jsp" class="button logout">Logout</a>
        <% } else { %>
            <a href="login.jsp" class="button">Try Again</a>
        <% } %>
    </div>
</body>
</html>