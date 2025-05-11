<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.auth.DatabaseConnection" %>
<%
    if (session.getAttribute("userId")==null || !"customer_rep".equals(session.getAttribute("userRole"))) { response.sendRedirect("login.jsp"); return;}    
    String message="";
    String action=request.getParameter("action");
    String fid=request.getParameter("flightNumber");
    String ftype=request.getParameter("flightType");
    String dep=request.getParameter("depAirport");
    String arr=request.getParameter("arrAirport");
    String dtime=request.getParameter("depTime");
    String atime=request.getParameter("arrTime");
    String aid=request.getParameter("aircraftId");
    String alid=request.getParameter("airlineId");
    String price=request.getParameter("price");
    Connection conn=null; PreparedStatement stmt=null;
    try{
        conn=DatabaseConnection.getConnection();
        if(action!=null){
            if("add".equals(action)){
                stmt=conn.prepareStatement("INSERT INTO Flight (flight_number, flight_type, dep_time, arr_time, dep_airport_id, arr_airport_id, aircraft_id, airline_id, price) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
                stmt.setString(1,fid); stmt.setString(2,ftype); stmt.setString(3,dtime); stmt.setString(4,atime);
                stmt.setString(5,dep); stmt.setString(6,arr); stmt.setString(7,aid); stmt.setString(8,alid); stmt.setBigDecimal(9,new java.math.BigDecimal(price));
                stmt.executeUpdate(); message="Flight added."; stmt.close();
            } else if("update".equals(action)){
                stmt=conn.prepareStatement("UPDATE Flight SET flight_type=?, dep_time=?, arr_time=?, dep_airport_id=?, arr_airport_id=?, aircraft_id=?, airline_id=?, price=? WHERE flight_number=?");
                stmt.setString(1,ftype); stmt.setString(2,dtime); stmt.setString(3,atime);
                stmt.setString(4,dep); stmt.setString(5,arr); stmt.setString(6,aid); stmt.setString(7,alid); stmt.setBigDecimal(8,new java.math.BigDecimal(price)); stmt.setString(9,fid);
                stmt.executeUpdate(); message="Flight updated."; stmt.close();
            } else if("delete".equals(action)){
                stmt=conn.prepareStatement("DELETE FROM Flight WHERE flight_number=?"); stmt.setString(1,fid); stmt.executeUpdate(); message="Flight deleted."; stmt.close();
            }
        }
    }catch(Exception e){ message="Error: "+e.getMessage(); }
    finally{ if(stmt!=null)try{stmt.close();}catch(Exception ignored){} if(conn!=null)try{conn.close();}catch(Exception ignored){} }
    List<Map<String,Object>> list=new ArrayList<>();
    try{ conn=DatabaseConnection.getConnection(); stmt=conn.prepareStatement("SELECT * FROM Flight"); ResultSet rs=stmt.executeQuery(); while(rs.next()){ Map<String,Object> m=new HashMap<>(); m.put("flightNumber",rs.getString("flight_number")); m.put("flightType",rs.getString("flight_type")); m.put("depTime",rs.getString("dep_time")); m.put("arrTime",rs.getString("arr_time")); m.put("depAirport",rs.getString("dep_airport_id")); m.put("arrAirport",rs.getString("arr_airport_id")); m.put("aircraftId",rs.getString("aircraft_id")); m.put("airlineId",rs.getString("airline_id")); m.put("price",rs.getBigDecimal("price")); list.add(m);} rs.close(); stmt.close(); }catch(Exception ignored){} finally{ if(stmt!=null)try{stmt.close();}catch(Exception ignored){} if(conn!=null)try{conn.close();}catch(Exception ignored){} }
%>
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Manage Flights</title><style>table,th,td{border:1px solid #ddd;border-collapse:collapse;padding:8px;}th{background:#f2f2f2;} .button{padding:6px 12px;background:#4CAF50;color:#fff;text-decoration:none;border-radius:4px;} .error{color:red;}</style></head>
<body>
    <h2>Flight Management</h2>
    <a href="repDashboard.jsp" class="button">Back to Dashboard</a>
    <% if(!message.isEmpty()){ %><p class="error"><%=message%></p><% } %>
    <h3>Add Flight</h3>
    <form method="post" action="manageFlights.jsp">
        <input type="hidden" name="action" value="add" />
        <label>Flight#:<input type="text" name="flightNumber" required /></label>
        <label>Type:<input type="text" name="flightType" required /></label>
        <label>Dep Airport:<input type="text" name="depAirport" required /></label>
        <label>Arr Airport:<input type="text" name="arrAirport" required /></label>
        <label>Dep Time:<input type="time" name="depTime" required /></label>
        <label>Arr Time:<input type="time" name="arrTime" required /></label>
        <label>Aircraft:<input type="text" name="aircraftId" required /></label>
        <label>Airline:<input type="text" name="airlineId" required /></label>
        <label>Price:<input type="number" step="0.01" name="price" required /></label>
        <button type="submit" class="button">Add</button>
    </form>
    <h3>Existing Flights</h3>
    <table>
        <tr><th>#</th><th>Type</th><th>Route</th><th>Times</th><th>Aircraft</th><th>Airline</th><th>Price</th><th>Actions</th></tr>
        <% for(Map<String,Object> m:list){ %>
            <tr>
                <td><%=m.get("flightNumber")%></td>
                <td><%=m.get("flightType")%></td>
                <td><%=m.get("depAirport")%>-><%=m.get("arrAirport")%></td>
                <td><%=m.get("depTime")%>-<%=m.get("arrTime")%></td>
                <td><%=m.get("aircraftId")%></td>
                <td><%=m.get("airlineId")%></td>
                <td><%=m.get("price")%></td>
                <td>
                    <form method="post" style="display:inline;" action="manageFlights.jsp">
                        <input type="hidden" name="action" value="update" />
                        <input type="hidden" name="flightNumber" value="<%=m.get("flightNumber")%>" />
                        <input type="text" name="flightType" value="<%=m.get("flightType")%>" size="6" required />
                        <input type="text" name="depAirport" value="<%=m.get("depAirport")%>" size="3" required />
                        <input type="text" name="arrAirport" value="<%=m.get("arrAirport")%>" size="3" required />
                        <input type="time" name="depTime" value="<%=m.get("depTime")%>" required />
                        <input type="time" name="arrTime" value="<%=m.get("arrTime")%>" required />
                        <input type="text" name="aircraftId" value="<%=m.get("aircraftId")%>" size="8" required />
                        <input type="text" name="airlineId" value="<%=m.get("airlineId")%>" size="3" required />
                        <input type="number" step="0.01" name="price" value="<%=m.get("price")%>" size="6" required />
                        <button type="submit" class="button">Update</button>
                    </form>
                    <form method="post" style="display:inline;" action="manageFlights.jsp" onsubmit="return confirm('Delete flight?');">
                        <input type="hidden" name="action" value="delete" />
                        <input type="hidden" name="flightNumber" value="<%=m.get("flightNumber")%>" />
                        <button type="submit" class="button" style="background:#f44336;">Delete</button>
                    </form>
                </td>
            </tr>
        <% } %>
    </table>
</body>
</html> 