<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="com.auth.DatabaseConnection" %>
<%@ page import="com.auth.User" %>
<%@ page import="java.util.*" %>
<%
    // Check if user is logged in and is an admin
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    String userRole = (String) session.getAttribute("userRole");
    if (!"admin".equals(userRole)) {
        response.sendRedirect("dashboard.jsp");
        return;
    }
    
    // Initialize variables
    List<Map<String, String>> users = new ArrayList<>();
    String message = "";
    String messageType = "";
    
    // Process form submissions
    String action = request.getParameter("action");
    
    if (action != null) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false); // Start transaction
            
            // Add User
            if (action.equals("add")) {
                String userId = request.getParameter("userId");
                String firstName = request.getParameter("firstName");
                String lastName = request.getParameter("lastName");
                String password = request.getParameter("password");
                String role = request.getParameter("role");
                
                // Insert into User table
                String sql = "INSERT INTO User (user_id, first_name, last_name, password) VALUES (?, ?, ?, ?)";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, userId);
                pstmt.setString(2, firstName);
                pstmt.setString(3, lastName);
                pstmt.setString(4, password);
                pstmt.executeUpdate();
                pstmt.close();
                
                // Insert into role-specific table
                if (role.equals("admin")) {
                    sql = "INSERT INTO Admin (user_id) VALUES (?)";
                } else if (role.equals("customer_rep")) {
                    sql = "INSERT INTO Customer_Rep (user_id) VALUES (?)";
                } else if (role.equals("customer")) {
                    String accountNo = "ACC" + System.currentTimeMillis() % 10000; // Generate simple account number
                    sql = "INSERT INTO Customer (user_id, account_no) VALUES (?, ?)";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setString(1, userId);
                    pstmt.setString(2, accountNo);
                    pstmt.executeUpdate();
                }
                
                if (!role.equals("customer")) {
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setString(1, userId);
                    pstmt.executeUpdate();
                }
                
                conn.commit();
                message = "User added successfully!";
                messageType = "success";
            }
            // Delete User
            else if (action.equals("delete")) {
                String userId = request.getParameter("userId");
                
                // Check if it's the current admin
                if (userId.equals(session.getAttribute("userId"))) {
                    message = "You cannot delete your own account!";
                    messageType = "error";
                } else {
                    // Delete from role-specific tables first (due to foreign key constraints)
                    String[] roleTables = {"Admin", "Customer_Rep", "Customer"};
                    for (String table : roleTables) {
                        String sql = "DELETE FROM " + table + " WHERE user_id = ?";
                        pstmt = conn.prepareStatement(sql);
                        pstmt.setString(1, userId);
                        pstmt.executeUpdate();
                        pstmt.close();
                    }
                    
                    // Delete from User table
                    String sql = "DELETE FROM User WHERE user_id = ?";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setString(1, userId);
                    pstmt.executeUpdate();
                    
                    conn.commit();
                    message = "User deleted successfully!";
                    messageType = "success";
                }
            }
            // Edit User
            else if (action.equals("edit")) {
                String userId = request.getParameter("userId");
                String firstName = request.getParameter("firstName");
                String lastName = request.getParameter("lastName");
                String password = request.getParameter("password");
                
                String sql = "UPDATE User SET first_name = ?, last_name = ?, password = ? WHERE user_id = ?";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, firstName);
                pstmt.setString(2, lastName);
                pstmt.setString(3, password);
                pstmt.setString(4, userId);
                pstmt.executeUpdate();
                
                conn.commit();
                message = "User updated successfully!";
                messageType = "success";
            }
            
        } catch (Exception e) {
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            message = "Error: " + e.getMessage();
            messageType = "error";
        } finally {
            if (pstmt != null) {
                try {
                    pstmt.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
    }
    
    // Fetch all users
    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;
    
    try {
        conn = DatabaseConnection.getConnection();
        stmt = conn.createStatement();
        
        // Get all users with their roles
        String sql = "SELECT u.user_id, u.first_name, u.last_name, u.password, " +
                    "CASE " +
                    "    WHEN a.user_id IS NOT NULL THEN 'Admin' " +
                    "    WHEN cr.user_id IS NOT NULL THEN 'Customer Rep' " +
                    "    WHEN c.user_id IS NOT NULL THEN 'Customer' " +
                    "    ELSE 'Unknown' " +
                    "END AS role, " +
                    "c.account_no " +
                    "FROM User u " +
                    "LEFT JOIN Admin a ON u.user_id = a.user_id " +
                    "LEFT JOIN Customer_Rep cr ON u.user_id = cr.user_id " +
                    "LEFT JOIN Customer c ON u.user_id = c.user_id " +
                    "ORDER BY role, u.last_name, u.first_name";
        rs = stmt.executeQuery(sql);
        
        while (rs.next()) {
            Map<String, String> user = new HashMap<>();
            user.put("userId", rs.getString("user_id"));
            user.put("firstName", rs.getString("first_name"));
            user.put("lastName", rs.getString("last_name"));
            user.put("password", rs.getString("password"));
            user.put("role", rs.getString("role"));
            user.put("accountNo", rs.getString("account_no"));
            users.add(user);
        }
    } catch (Exception e) {
        message = "Error loading users: " + e.getMessage();
        messageType = "error";
    } finally {
        if (rs != null) {
            try {
                rs.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
        if (stmt != null) {
            try {
                stmt.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
        if (conn != null) {
            try {
                conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>User Management</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
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
        .back-button {
            padding: 8px 16px;
            background-color: #3498db;
            color: white;
            text-decoration: none;
            border-radius: 4px;
        }
        .back-button:hover {
            background-color: #2980b9;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            padding: 12px 15px;
            border-bottom: 1px solid #ddd;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
            font-weight: bold;
        }
        tr:hover {
            background-color: #f9f9f9;
        }
        .form-area {
            margin-top: 30px;
            background-color: #f9f9f9;
            padding: 20px;
            border-radius: 5px;
        }
        .form-group {
            margin-bottom: 15px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
        }
        input[type="text"], input[type="password"], select {
            width: 100%;
            padding: 8px;
            box-sizing: border-box;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        .button-group {
            margin-top: 20px;
        }
        .action-button {
            display: inline-block;
            padding: 8px 16px;
            background-color: #4CAF50;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            border: none;
            cursor: pointer;
            margin-right: 10px;
        }
        .action-button:hover {
            background-color: #45a049;
        }
        .action-button.edit {
            background-color: #3498db;
        }
        .action-button.edit:hover {
            background-color: #2980b9;
        }
        .action-button.delete {
            background-color: #e74c3c;
        }
        .action-button.delete:hover {
            background-color: #c0392b;
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
        .hidden {
            display: none;
        }
    </style>
    <script>
        function confirmDelete(userId, userName) {
            return confirm("Are you sure you want to delete user " + userName + "?");
        }
        
        function editUser(userId, firstName, lastName, password) {
            document.getElementById('editForm').classList.remove('hidden');
            document.getElementById('addForm').classList.add('hidden');
            
            document.getElementById('editUserId').value = userId;
            document.getElementById('editFirstName').value = firstName;
            document.getElementById('editLastName').value = lastName;
            document.getElementById('editPassword').value = password;
            
            // Scroll to the form
            document.getElementById('editForm').scrollIntoView();
        }
        
        function showAddForm() {
            document.getElementById('addForm').classList.remove('hidden');
            document.getElementById('editForm').classList.add('hidden');
            
            // Clear form fields
            document.getElementById('userId').value = '';
            document.getElementById('firstName').value = '';
            document.getElementById('lastName').value = '';
            document.getElementById('password').value = '';
            
            // Scroll to the form
            document.getElementById('addForm').scrollIntoView();
        }
    </script>
</head>
<body>
    <div class="container">
        <header>
            <h1>User Management</h1>
            <a href="adminDashboard.jsp" class="back-button">Back to Dashboard</a>
        </header>
        
        <% if (!message.isEmpty()) { %>
            <div class="message <%= messageType %>">
                <%= message %>
            </div>
        <% } %>
        
        <div class="content">
            <button onclick="showAddForm()" class="action-button">Add New User</button>
            
            <h2>User List</h2>
            <table>
                <thead>
                    <tr>
                        <th>User ID</th>
                        <th>First Name</th>
                        <th>Last Name</th>
                        <th>Role</th>
                        <th>Account No</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (Map<String, String> user : users) { %>
                        <tr>
                            <td><%= user.get("userId") %></td>
                            <td><%= user.get("firstName") %></td>
                            <td><%= user.get("lastName") %></td>
                            <td><%= user.get("role") %></td>
                            <td><%= user.get("accountNo") != null ? user.get("accountNo") : "-" %></td>
                            <td>
                                <button 
                                    onclick="editUser('<%= user.get("userId").replace("'", "\\'") %>', '<%= user.get("firstName").replace("'", "\\'") %>', '<%= user.get("lastName").replace("'", "\\'") %>', '<%= user.get("password").replace("'", "\\'") %>')" 
                                    class="action-button edit">Edit</button>
                                <form method="post" style="display:inline;" onsubmit="return confirmDelete('<%= user.get("userId").replace("'", "\\'") %>', '<%= user.get("firstName").replace("'", "\\'") + " " + user.get("lastName").replace("'", "\\'") %>')">
                                    <input type="hidden" name="action" value="delete">
                                    <input type="hidden" name="userId" value="<%= user.get("userId") %>">
                                    <button type="submit" class="action-button delete">Delete</button>
                                </form>
                            </td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
            
            <!-- Add User Form -->
            <div id="addForm" class="form-area hidden">
                <h2>Add New User</h2>
                <form method="post">
                    <input type="hidden" name="action" value="add">
                    
                    <div class="form-group">
                        <label for="userId">User ID</label>
                        <input type="text" id="userId" name="userId" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="firstName">First Name</label>
                        <input type="text" id="firstName" name="firstName" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="lastName">Last Name</label>
                        <input type="text" id="lastName" name="lastName" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="password">Password</label>
                        <input type="password" id="password" name="password" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="role">Role</label>
                        <select id="role" name="role" required>
                            <option value="admin">Admin</option>
                            <option value="customer_rep">Customer Representative</option>
                            <option value="customer">Customer</option>
                        </select>
                    </div>
                    
                    <div class="button-group">
                        <button type="submit" class="action-button">Add User</button>
                    </div>
                </form>
            </div>
            
            <!-- Edit User Form -->
            <div id="editForm" class="form-area hidden">
                <h2>Edit User</h2>
                <form method="post">
                    <input type="hidden" name="action" value="edit">
                    <input type="hidden" id="editUserId" name="userId">
                    
                    <div class="form-group">
                        <label for="editFirstName">First Name</label>
                        <input type="text" id="editFirstName" name="firstName" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="editLastName">Last Name</label>
                        <input type="text" id="editLastName" name="lastName" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="editPassword">Password</label>
                        <input type="password" id="editPassword" name="password" required>
                    </div>
                    
                    <div class="button-group">
                        <button type="submit" class="action-button">Update User</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</body>
</html>