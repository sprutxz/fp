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
            String sql = "SELECT f.flight_number, f.flight_type, f.dep_time, f.arr_time, f.dep_airport_id, f.arr_airport_id, f.aircraft_id, f.airline_id, MIN(t.fare) AS fare "
                       + "FROM Flight f LEFT JOIN Ticket t ON t.date = ? AND t.aircraft_id = f.aircraft_id "
                       + "WHERE f.dep_airport_id = ? AND f.arr_airport_id = ? "
                       + "GROUP BY f.flight_number, f.flight_type, f.dep_time, f.arr_time, f.dep_airport_id, f.arr_airport_id, f.aircraft_id, f.airline_id";
            stmt = conn.prepareStatement(sql);
            stmt.setDate(1, searchDate);
            stmt.setString(2, depAirport);
            stmt.setString(3, arrAirport);
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
                BigDecimal fare = rs.getBigDecimal("fare");
                f.setFare(fare != null ? fare : BigDecimal.ZERO);
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