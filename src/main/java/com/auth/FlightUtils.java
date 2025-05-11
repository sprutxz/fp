package com.auth;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.math.BigDecimal;
import java.sql.Time;

public class FlightUtils {
    public static List<Flight> filterFlights(List<Flight> flights, BigDecimal minFare, BigDecimal maxFare, String airlineNameFilter,
                                             Time minDepTime, Time maxDepTime, Time minArrTime, Time maxArrTime) {
        List<Flight> result = new ArrayList<>();
        for (Flight f : flights) {
            if (minFare != null && f.getFare().compareTo(minFare) < 0) continue;
            if (maxFare != null && f.getFare().compareTo(maxFare) > 0) continue;
            if (airlineNameFilter != null && !airlineNameFilter.isEmpty() && 
                (f.getAirlineName() == null || !f.getAirlineName().toLowerCase().contains(airlineNameFilter.toLowerCase()))) continue;
            if (minDepTime != null && f.getDepTime().before(minDepTime)) continue;
            if (maxDepTime != null && f.getDepTime().after(maxDepTime)) continue;
            if (minArrTime != null && f.getArrTime().before(minArrTime)) continue;
            if (maxArrTime != null && f.getArrTime().after(maxArrTime)) continue;
            result.add(f);
        }
        return result;
    }

    public static void sortFlights(List<Flight> flights, String sortBy) {
        if (sortBy == null || sortBy.isEmpty()) return;
        Comparator<Flight> comp = null;
        switch (sortBy) {
            case "fare":
                comp = Comparator.comparing(Flight::getFare);
                break;
            case "dep_time":
                comp = Comparator.comparing(Flight::getDepTime);
                break;
            case "arr_time":
                comp = Comparator.comparing(Flight::getArrTime);
                break;
            case "duration":
                comp = Comparator.comparingLong(f -> f.getArrTime().getTime() - f.getDepTime().getTime());
                break;
        }
        if (comp != null) {
            flights.sort(comp);
        }
    }
} 