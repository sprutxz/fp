package com.auth;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Date;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

public class FlightDAO {

    /**
     * Search flights between two airports.
     * @param depAirport departure airport ID
     * @param arrAirport arrival airport ID
     * @param searchDate date of search
     * @return list of flights matching route
     * @throws ClassNotFoundException
     * @throws SQLException
     */
    public List<Flight> searchFlights(String depAirport, String arrAirport, Date searchDate) throws ClassNotFoundException, SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<Flight> list = new ArrayList<>();
        try {
            conn = DatabaseConnection.getConnection();
            String sql = "SELECT f.flight_number, f.flight_type, f.dep_time, f.arr_time, f.dep_airport_id, f.arr_airport_id, "
                       + "f.aircraft_id, f.airline_id, f.price as fare, a.airline_name "
                       + "FROM Flight f "
                       + "JOIN Airline a ON f.airline_id = a.airline_id "
                       + "WHERE f.dep_airport_id = ? AND f.arr_airport_id = ?";
            stmt = conn.prepareStatement(sql);
            stmt.setString(1, depAirport);
            stmt.setString(2, arrAirport);
            rs = stmt.executeQuery();
            while (rs.next()) {
                Flight f = new Flight();
                f.setFlightNumber(rs.getString("flight_number"));
                f.setFlightType(rs.getString("flight_type"));
                f.setDepTime(rs.getTime("dep_time"));
                f.setArrTime(rs.getTime("arr_time"));
                f.setDepAirportId(rs.getString("dep_airport_id"));
                f.setArrAirportId(rs.getString("arr_airport_id"));
                f.setAircraftId(rs.getString("aircraft_id"));
                f.setAirlineId(rs.getString("airline_id"));
                f.setAirlineName(rs.getString("airline_name"));
                f.setFare(rs.getBigDecimal("fare"));
                f.setTravelDate(searchDate);
                list.add(f);
            }
        } finally {
            if (rs != null) rs.close();
            if (stmt != null) stmt.close();
            if (conn != null) conn.close();
        }
        return list;
    }
} 