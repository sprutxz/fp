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

    // Handle question submission
    String postSuccessMessage = "";
    String postErrorMessage = "";
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String questionText = request.getParameter("questionText");
        if (questionText != null && !questionText.trim().isEmpty()) {
            Connection postConn = null;
            PreparedStatement postPstmt = null;
            try {
                postConn = DatabaseConnection.getConnection();
                String insertSql = "INSERT INTO QnA (customer_id, question_text, question_date) VALUES (?, ?, NOW())";
                postPstmt = postConn.prepareStatement(insertSql);
                postPstmt.setString(1, userId);
                postPstmt.setString(2, questionText);
                postPstmt.executeUpdate();
                postSuccessMessage = "Your question has been posted successfully.";
            } catch (Exception e) {
                postErrorMessage = "Error posting question: " + e.getMessage();
            } finally {
                if (postPstmt != null) postPstmt.close();
                if (postConn != null) postConn.close();
            }
        } else {
            postErrorMessage = "Question cannot be empty.";
        }
    }

    // Fetch Q&A entries
    String keyword = request.getParameter("keyword") != null ? request.getParameter("keyword").trim() : "";
    List<Map<String, Object>> qnaList = new ArrayList<>();
    String retrieveErrorMessage = "";

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    try {
        conn = DatabaseConnection.getConnection();
        if (!keyword.isEmpty()) {
            String sql = "SELECT question_id, customer_id, question_text, answer_text, question_date, answer_date " +
                         "FROM QnA WHERE question_text LIKE ? OR answer_text LIKE ? ORDER BY question_date DESC";
            pstmt = conn.prepareStatement(sql);
            String pattern = "%" + keyword + "%";
            pstmt.setString(1, pattern);
            pstmt.setString(2, pattern);
        } else {
            String sql = "SELECT question_id, customer_id, question_text, answer_text, question_date, answer_date " +
                         "FROM QnA ORDER BY question_date DESC";
            pstmt = conn.prepareStatement(sql);
        }
        rs = pstmt.executeQuery();
        while (rs.next()) {
            Map<String, Object> entry = new HashMap<>();
            entry.put("customerId", rs.getString("customer_id"));
            entry.put("questionId", rs.getInt("question_id"));
            entry.put("questionText", rs.getString("question_text"));
            entry.put("answerText", rs.getString("answer_text"));
            entry.put("questionDate", rs.getTimestamp("question_date"));
            entry.put("answerDate", rs.getTimestamp("answer_date"));
            qnaList.add(entry);
        }
    } catch (Exception e) {
        retrieveErrorMessage = "Error retrieving Q&A: " + e.getMessage();
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
    <title>My Questions & Answers</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5; }
        .container { max-width: 900px; margin: 50px auto; padding: 20px; background-color: white; border-radius: 5px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; border-bottom: 1px solid #eee; padding-bottom: 10px; }
        h1 { margin: 0; color: #333; }
        .search-form { margin-bottom: 20px; }
        .search-input { padding: 8px; width: 300px; border: 1px solid #ccc; border-radius: 4px; }
        .button { padding: 8px 16px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 4px; display: inline-block; margin-left: 5px; }
        .button:hover { background-color: #45a049; }
        .card { border: 1px solid #ddd; border-radius: 5px; padding: 15px; margin-bottom: 15px; background-color: #f9f9f9; }
        .card-header { font-weight: bold; margin-bottom: 10px; }
        .card-content { margin-bottom: 10px; }
        .answer { margin-left: 20px; color: #555; }
        .empty-state { text-align: center; padding: 20px; color: #777; }
        .error-message { color: #d9534f; padding: 10px; background-color: #f8d7da; border-radius: 4px; margin-bottom: 15px; }
        .success-message { color: #28a745; padding: 10px; background-color: #e7f9e7; border-radius: 4px; margin-bottom: 15px; }
        .form-group { margin-bottom: 15px; }
        label { font-weight: bold; display: block; margin-bottom: 5px; }
        textarea { width: 100%; padding: 10px; border: 1px solid #ccc; border-radius: 4px; resize: vertical; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>My Questions & Answers</h1>
            <a href="dashboard.jsp" class="button">Back to Dashboard</a>
        </header>
        <% if (!postSuccessMessage.isEmpty()) { %>
            <div class="success-message"><%= postSuccessMessage %></div>
        <% } %>
        <% if (!postErrorMessage.isEmpty()) { %>
            <div class="error-message"><%= postErrorMessage %></div>
        <% } %>
        <form method="post" action="qnaList.jsp">
            <div class="form-group">
                <label for="questionText">Your Question:</label>
                <textarea id="questionText" name="questionText" rows="4"></textarea>
            </div>
            <button type="submit" class="button">Submit Question</button>
        </form>
        <div class="search-form">
            <form method="get" action="qnaList.jsp">
                <input type="text" name="keyword" class="search-input" placeholder="Search questions and answers" value="<%= keyword %>"/>
                <button type="submit" class="button">Search</button>
            </form>
        </div>
        <% if (!retrieveErrorMessage.isEmpty()) { %>
            <div class="error-message"><%= retrieveErrorMessage %></div>
        <% } %>
        <% if (qnaList.isEmpty()) { %>
            <div class="empty-state">
                <p>You have not posted any questions yet.</p>
            </div>
        <% } else { %>
            <% for (Map<String, Object> entry : qnaList) { %>
                <div class="card">
                    <div class="card-header">Question by <%= entry.get("customerId") %> (<%= entry.get("questionDate") %>):</div>
                    <div class="card-content"><%= entry.get("questionText") %></div>
                    <% if (entry.get("answerText") != null) { %>
                        <div class="card-header">Answer (<%= entry.get("answerDate") %>):</div>
                        <div class="answer"><%= entry.get("answerText") %></div>
                    <% } else { %>
                        <div class="answer"><em>Not answered yet.</em></div>
                    <% } %>
                </div>
            <% } %>
        <% } %>
    </div>
</body>
</html> 