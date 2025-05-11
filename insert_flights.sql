USE userdb;
-- make sure you have these airports, airline and an aircraft first
INSERT IGNORE INTO Airport (airport_id, airport_name)
  VALUES ('JFK','John F. Kennedy Intl'), ('LAX','Los Angeles Intl');

INSERT IGNORE INTO Airline (airline_id, airline_name)
  VALUES ('AA','American Airlines');

INSERT IGNORE INTO Aircraft (aircraft_id, airline_id, num_seats)
  VALUES ('AC100','AA',180);

-- some one-way flights
INSERT INTO Flight
  (flight_number, flight_type, dep_time, arr_time, dep_airport_id, arr_airport_id, aircraft_id, airline_id)
VALUES
  ('AA100','Commercial','08:00:00','11:00:00','JFK','LAX','AC100','AA'),
  ('AA101','Commercial','14:00:00','17:00:00','JFK','LAX','AC100','AA');

-- flights in the opposite direction for round-trips
INSERT INTO Flight
  (flight_number, flight_type, dep_time, arr_time, dep_airport_id, arr_airport_id, aircraft_id, airline_id)
VALUES
  ('AA200','Commercial','09:00:00','12:00:00','LAX','JFK','AC100','AA'),
  ('AA201','Commercial','15:00:00','18:00:00','LAX','JFK','AC100','AA');

-- add service days (you need Days table populated; if you followed schema it probably has day_no 1–7)
-- for simplicity let's assume Flights run every day:
INSERT INTO Days (day_no, day) VALUES
  (1, 'Monday'),
  (2, 'Tuesday'),
  (3, 'Wednesday'),
  (4, 'Thursday'),
  (5, 'Friday'),
  (6, 'Saturday'),
  (7, 'Sunday');

INSERT INTO Flies_on (flight_number, airline_id, day_no)
SELECT f.flight_number, f.airline_id, d.day_no
FROM Flight f JOIN Days d ON 1=1;