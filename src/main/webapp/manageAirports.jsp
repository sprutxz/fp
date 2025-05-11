<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.auth.DatabaseConnection" %>
<%
    if (session.getAttribute("userId") == null || !"customer_rep".equals(session.getAttribute("userRole"))) {
        response.sendRedirect("login.jsp"); return;
    }
    String message="";
    String action=request.getParameter("action");
    String aid=request.getParameter("airportId");
    String name=request.getParameter("airportName");
    Connection conn=null; PreparedStatement stmt=null;
    try{
        conn=DatabaseConnection.getConnection();
        if(action!=null){
            if("add".equals(action)){
                stmt=conn.prepareStatement("INSERT INTO Airport (airport_id, airport_name) VALUES (?, ?)");
                stmt.setString(1, aid); stmt.setString(2, name);
                stmt.executeUpdate(); message="Airport added."; stmt.close();
            } else if("update".equals(action)){
                stmt=conn.prepareStatement("UPDATE Airport SET airport_name=? WHERE airport_id=?");
                stmt.setString(1, name); stmt.setString(2, aid);
                stmt.executeUpdate(); message="Airport updated."; stmt.close();
            } else if("delete".equals(action)){
                stmt=conn.prepareStatement("DELETE FROM Airport WHERE airport_id=?");
                stmt.setString(1, aid);
                stmt.executeUpdate(); message="Airport deleted."; stmt.close();
            }
        }
    } catch(Exception e){ message="Error: "+e.getMessage(); }
    finally{ if(stmt!=null)try{stmt.close();}catch(Exception ignored){} if(conn!=null)try{conn.close();}catch(Exception ignored){} }
    // fetch list
    List<Map<String,Object>> list=new ArrayList<>();
    try{
        conn=DatabaseConnection.getConnection(); stmt=conn.prepareStatement("SELECT airport_id, airport_name FROM Airport");
        ResultSet rs=stmt.executeQuery(); while(rs.next()){ Map<String,Object> m=new HashMap<>(); m.put("airportId",rs.getString("airport_id")); m.put("airportName",rs.getString("airport_name")); list.add(m);} rs.close(); stmt.close();
    }catch(Exception ignored){}
    finally{ if(stmt!=null)try{stmt.close();}catch(Exception ignored){} if(conn!=null)try{conn.close();}catch(Exception ignored){} }
%>
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Manage Airports</title><style>table,th,td{border:1px solid #ddd;border-collapse:collapse;padding:8px;}th{background:#f2f2f2;} .button{padding:6px 12px;background:#4CAF50;color:#fff;text-decoration:none;border-radius:4px;} .error{color:red;}</style></head>
<body>
    <h2>Airport Management</h2>
    <a href="repDashboard.jsp" class="button">Back to Dashboard</a>
    <% if(!message.isEmpty()){ %><p class="error"><%=message%></p><% } %>
    <h3>Add Airport</h3>
    <form method="post" action="manageAirports.jsp">
        <input type="hidden" name="action" value="add" />
        <label>ID:<input type="text" name="airportId" required /></label>
        <label>Name:<input type="text" name="airportName" required /></label>
        <button type="submit" class="button">Add</button>
    </form>
    <h3>Existing Airports</h3>
    <table>
        <tr><th>ID</th><th>Name</th><th>Actions</th></tr>
        <% for(Map<String,Object> m: list){ %>
            <tr>
                <td><%=m.get("airportId")%></td>
                <td><%=m.get("airportName")%></td>
                <td>
                    <form method="post" style="display:inline;" action="manageAirports.jsp">
                        <input type="hidden" name="action" value="update" />
                        <input type="hidden" name="airportId" value="<%=m.get("airportId")%>" />
                        <input type="text" name="airportName" value="<%=m.get("airportName")%>" required />
                        <button type="submit" class="button">Update</button>
                    </form>
                    <form method="post" style="display:inline;" action="manageAirports.jsp" onsubmit="return confirm('Delete airport?');">
                        <input type="hidden" name="action" value="delete" />
                        <input type="hidden" name="airportId" value="<%=m.get("airportId")%>" />
                        <button type="submit" class="button" style="background:#f44336;">Delete</button>
                    </form>
                </td>
            </tr>
        <% } %>
    </table>
</body>
</html> 