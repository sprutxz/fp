-- Create the database
CREATE DATABASE IF NOT EXISTS userdb;
USE userdb;

-- airline_system.sql

CREATE TABLE User (
    user_id VARCHAR(20),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    password VARCHAR(50),
    PRIMARY KEY (user_id)
);

CREATE TABLE Customer (
    user_id VARCHAR(20),
    account_no VARCHAR(20), 
    PRIMARY KEY (user_id),
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);

CREATE TABLE Admin (
    user_id VARCHAR(20),
    PRIMARY KEY (user_id),
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);

CREATE TABLE Customer_Rep (
    user_id VARCHAR(20),
    PRIMARY KEY (user_id),
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);

CREATE TABLE Airline (
    airline_id VARCHAR(20),
    airline_name VARCHAR(50),
    PRIMARY KEY (airline_id)
);

CREATE TABLE Airport (
    airport_id VARCHAR(20),
    airport_name VARCHAR(50),
    PRIMARY KEY (airport_id)
);

CREATE TABLE Aircraft (
    aircraft_id VARCHAR(20),
    airline_id VARCHAR(20) NOT NULL,
    num_seats INT,
    PRIMARY KEY (aircraft_id),
    FOREIGN KEY (airline_id) REFERENCES Airline(airline_id)
);

CREATE TABLE Seat (
    seat_no VARCHAR(10),
    aircraft_id VARCHAR(20) NOT NULL,
    class VARCHAR(20),
    PRIMARY KEY (seat_no, aircraft_id),
    FOREIGN KEY (aircraft_id) REFERENCES Aircraft(aircraft_id)
);

CREATE TABLE Flight (
    flight_number VARCHAR(20),
    flight_type VARCHAR(20),
    dep_time TIME,
    arr_time TIME,
    dep_airport_id VARCHAR(20) NOT NULL,
    arr_airport_id VARCHAR(20) NOT NULL,
    aircraft_id VARCHAR(20) NOT NULL,
    airline_id VARCHAR(20) NOT NULL,
    PRIMARY KEY (flight_number),
    FOREIGN KEY (dep_airport_id) REFERENCES Airport(airport_id),
    FOREIGN KEY (arr_airport_id) REFERENCES Airport(airport_id),
    FOREIGN KEY (aircraft_id) REFERENCES Aircraft(aircraft_id),
    FOREIGN KEY (airline_id) REFERENCES Airline(airline_id)
);

CREATE TABLE Days (
    day_no INT,
    day VARCHAR(10),
    PRIMARY KEY (day_no)
);

CREATE TABLE Flies_on (
    flight_number VARCHAR(20),
    airline_id VARCHAR(20),
    day_no INT,
    PRIMARY KEY (flight_number, airline_id, day_no),
    FOREIGN KEY (flight_number) REFERENCES Flight(flight_number),
    FOREIGN KEY (airline_id) REFERENCES Airline(airline_id),
    FOREIGN KEY (day_no) REFERENCES Days(day_no)
);

CREATE TABLE Ticket (
    ticket_id VARCHAR(20),
    user_id VARCHAR(20) NOT NULL,
    type VARCHAR(20),
    fare DECIMAL(10,2),
    date DATE,
    seat_no VARCHAR(10),
    aircraft_id VARCHAR(20),
    PRIMARY KEY (ticket_id),
    FOREIGN KEY (user_id) REFERENCES User(user_id),
    FOREIGN KEY (seat_no, aircraft_id) REFERENCES Seat(seat_no, aircraft_id)
);

CREATE TABLE Travel (
    user_id VARCHAR(20) NOT NULL,
    flight_number VARCHAR(20),
    airline_id VARCHAR(20),
    travel_date DATE,
    booking_fee DECIMAL(10,2),
    seat_no VARCHAR(10),
    aircraft_id VARCHAR(20),
    PRIMARY KEY (user_id, flight_number, airline_id, travel_date),
    FOREIGN KEY (user_id) REFERENCES User(user_id),
    FOREIGN KEY (flight_number) REFERENCES Flight(flight_number),
    FOREIGN KEY (airline_id) REFERENCES Airline(airline_id),
    FOREIGN KEY (seat_no, aircraft_id) REFERENCES Seat(seat_no, aircraft_id)
);