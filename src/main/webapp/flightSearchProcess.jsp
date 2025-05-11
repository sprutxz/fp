<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.util.List" %>
<%@ page import="com.auth.FlightDAO" %>
<%@ page import="com.auth.Flight" %>
<%@ page import="com.auth.FlightUtils" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.sql.Time" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.sql.Date" %>
<%
    String depAirport = request.getParameter("depAirport");
    String arrAirport = request.getParameter("arrAirport");
    String tripType = request.getParameter("tripType");
    String depDateStr = request.getParameter("depDate");
    String returnDateStr = request.getParameter("returnDate");
    boolean flexible = request.getParameter("flexible") != null;

    FlightDAO dao = new FlightDAO();
    List<Flight> outboundFlights = new java.util.ArrayList<>();
    List<Flight> returnFlights = new java.util.ArrayList<>();
    String error = null;
    try {
        LocalDate localDepDate = LocalDate.parse(depDateStr);
        if (flexible) {
            for (int i = -3; i <= 3; i++) {
                Date searchDate = Date.valueOf(localDepDate.plusDays(i));
                List<Flight> flights = dao.searchFlights(depAirport, arrAirport, searchDate);
                outboundFlights.addAll(flights);
            }
        } else {
            Date searchDate = Date.valueOf(localDepDate);
            List<Flight> flights = dao.searchFlights(depAirport, arrAirport, searchDate);
            outboundFlights.addAll(flights);
        }
        if ("roundtrip".equals(tripType) && returnDateStr != null && !returnDateStr.isEmpty()) {
            LocalDate localReturnDate = LocalDate.parse(returnDateStr);
            if (flexible) {
                for (int i = -3; i <= 3; i++) {
                    Date searchDate = Date.valueOf(localReturnDate.plusDays(i));
                    List<Flight> flights = dao.searchFlights(arrAirport, depAirport, searchDate);
                    returnFlights.addAll(flights);
                }
            } else {
                Date searchDate = Date.valueOf(localReturnDate);
                List<Flight> flights = dao.searchFlights(arrAirport, depAirport, searchDate);
                returnFlights.addAll(flights);
            }
        }
    } catch (Exception e) {
        error = e.getMessage();
    }

    // Apply filtering and sorting
    String sortBy = request.getParameter("sortBy");
    String minFareStr = request.getParameter("minFare");
    String maxFareStr = request.getParameter("maxFare");
    String airlineNameFilter = request.getParameter("airlineNameFilter");
    String minDepTimeStr = request.getParameter("minDepTime");
    String maxDepTimeStr = request.getParameter("maxDepTime");
    String minArrTimeStr = request.getParameter("minArrTime");
    String maxArrTimeStr = request.getParameter("maxArrTime");

    BigDecimal minFare = (minFareStr != null && !minFareStr.isEmpty()) ? new BigDecimal(minFareStr) : null;
    BigDecimal maxFare = (maxFareStr != null && !maxFareStr.isEmpty()) ? new BigDecimal(maxFareStr) : null;
    Time minDepTime = (minDepTimeStr != null && !minDepTimeStr.isEmpty()) ? Time.valueOf(minDepTimeStr + ":00") : null;
    Time maxDepTime = (maxDepTimeStr != null && !maxDepTimeStr.isEmpty()) ? Time.valueOf(maxDepTimeStr + ":00") : null;
    Time minArrTime = (minArrTimeStr != null && !minArrTimeStr.isEmpty()) ? Time.valueOf(minArrTimeStr + ":00") : null;
    Time maxArrTime = (maxArrTimeStr != null && !maxArrTimeStr.isEmpty()) ? Time.valueOf(maxArrTimeStr + ":00") : null;

    outboundFlights = FlightUtils.filterFlights(outboundFlights, minFare, maxFare, airlineNameFilter, minDepTime, maxDepTime, minArrTime, maxArrTime);
    returnFlights = FlightUtils.filterFlights(returnFlights, minFare, maxFare, airlineNameFilter, minDepTime, maxDepTime, minArrTime, maxArrTime);

    FlightUtils.sortFlights(outboundFlights, sortBy);
    FlightUtils.sortFlights(returnFlights, sortBy);

    request.setAttribute("tripType", tripType);
    request.setAttribute("outboundFlights", outboundFlights);
    request.setAttribute("returnFlights", returnFlights);
    request.setAttribute("error", error);
%>
<jsp:forward page="flightResults.jsp" /> 