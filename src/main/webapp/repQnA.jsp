<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.auth.DatabaseConnection" %>
<%
    if (session.getAttribute("userId")==null || !"customer_rep".equals(session.getAttribute("userRole"))) { response.sendRedirect("login.jsp"); return; }
    String repId=(String)session.getAttribute("userId");
    String action=request.getParameter("action");
    String qid=request.getParameter("questionId");
    String answer=request.getParameter("answerText");
    String message="";
    if ("answer".equals(action) && qid!=null && answer!=null && !answer.trim().isEmpty()) {
        try (Connection conn=DatabaseConnection.getConnection();
             PreparedStatement stmt=conn.prepareStatement("UPDATE QnA SET answer_text=?, answer_date=NOW(), rep_id=? WHERE question_id=?")) {
            stmt.setString(1, answer);
            stmt.setString(2, repId);
            stmt.setInt(3, Integer.parseInt(qid));
            int updated=stmt.executeUpdate();
            message = updated>0?"Answer submitted." : "Failed to submit answer.";
        } catch (Exception e) { message="Error: "+e.getMessage(); }
    }
    // Fetch all questions (answered and unanswered)
    List<Map<String,Object>> list = new ArrayList<>();
    try (Connection conn = DatabaseConnection.getConnection();
         PreparedStatement stmt = conn.prepareStatement(
             "SELECT q.question_id, q.customer_id, q.question_text, q.question_date, q.answer_text, q.answer_date, u.first_name, u.last_name " +
             "FROM QnA q JOIN User u ON q.customer_id = u.user_id " +
             "ORDER BY q.question_date DESC")) {
        try (ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> m = new HashMap<>();
                m.put("questionId", rs.getInt("question_id"));
                m.put("customerName", rs.getString("first_name") + " " + rs.getString("last_name"));
                m.put("questionText", rs.getString("question_text"));
                m.put("questionTimestamp", rs.getTimestamp("question_date"));
                m.put("answerText", rs.getString("answer_text"));
                m.put("answerTimestamp", rs.getTimestamp("answer_date"));
                list.add(m);
            }
        }
    } catch (Exception e) { /* ignore */ }
%>
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Q&A Management</title><style>.container{max-width:800px;margin:20px auto;font-family:Arial;} .card{border:1px solid #ddd;padding:15px;margin-bottom:15px;border-radius:5px;background:#f9f9f9;} textarea{width:100%;height:80px;} .button{padding:6px 12px;background:#4CAF50;color:white;text-decoration:none;border-radius:4px;border:none;cursor:pointer;} .error{color:red;} .success{color:green;}</style></head>
<body><div class="container">
    <h2>Reply to Customer Questions</h2>
    <div style="text-align: right; margin-bottom: 20px;">
        <a href="repDashboard.jsp" class="button">Back to Dashboard</a>
    </div>
    <% if (!message.isEmpty()) { %><p class="<%= message.startsWith("Error")?"error":"success" %>"><%= message %></p><% } %>
    <% if (list.isEmpty()) { %>
        <p>No questions found.</p>
    <% } else { %>
        <% for (Map<String,Object> m : list) { %>
            <div class="card">
                <p><strong>Customer:</strong> <%= m.get("customerName") %></p>
                <p><strong>Timestamp:</strong> <%= m.get("questionTimestamp") %></p>
                <p><strong>Question:</strong> <%= m.get("questionText") %></p>
                <% if (m.get("answerText") == null) { %>
                    <form method="post" action="repQnA.jsp">
                        <input type="hidden" name="action" value="answer" />
                        <input type="hidden" name="questionId" value="<%= m.get("questionId") %>" />
                        <textarea name="answerText" placeholder="Your answer..." required></textarea><br/>
                        <button type="submit" class="button">Submit Answer</button>
                    </form>
                <% } else { %>
                    <div class="answer">
                        <p><strong>Answer:</strong> <%= m.get("answerText") %></p>
                        <p><strong>Answered On:</strong> <%= m.get("answerTimestamp") %></p>
                    </div>
                <% } %>
            </div>
        <% } %>
    <% } %>
</div></body></html> 