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
    price DECIMAL(10,2) NOT NULL,
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
    date DATE,
    seat_no VARCHAR(10),
    aircraft_id VARCHAR(20),
    flight_number VARCHAR(20) NOT NULL,
    fare DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (ticket_id),
    FOREIGN KEY (user_id) REFERENCES User(user_id),
    FOREIGN KEY (seat_no, aircraft_id) REFERENCES Seat(seat_no, aircraft_id),
    FOREIGN KEY (flight_number) REFERENCES Flight(flight_number)
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

CREATE TABLE QnA (
    question_id INT AUTO_INCREMENT,
    customer_id VARCHAR(20) NOT NULL,
    rep_id VARCHAR(20),
    question_text TEXT NOT NULL,
    answer_text TEXT,
    question_date DATETIME NOT NULL,
    answer_date DATETIME,
    PRIMARY KEY (question_id),
    FOREIGN KEY (customer_id) REFERENCES Customer(user_id),
    FOREIGN KEY (rep_id) REFERENCES Customer_Rep(user_id)
);

-- New tables for waiting list and notifications

CREATE TABLE Waiting_List (
    user_id VARCHAR(20) NOT NULL,
    flight_number VARCHAR(20) NOT NULL,
    airline_id VARCHAR(20) NOT NULL,
    request_date DATETIME NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'waiting',
    notification_date DATETIME,
    PRIMARY KEY (user_id, flight_number),
    FOREIGN KEY (user_id) REFERENCES User(user_id),
    FOREIGN KEY (flight_number) REFERENCES Flight(flight_number),
    FOREIGN KEY (airline_id) REFERENCES Airline(airline_id)
);

CREATE TABLE Notification (
    notification_id INT AUTO_INCREMENT,
    user_id VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    notification_date DATETIME NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT 0,
    PRIMARY KEY (notification_id),
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);

-- Sample Data Insertion

-- Insert Users
INSERT INTO User VALUES ('admin01', 'Admin', 'User', 'admin123');
INSERT INTO User VALUES ('user01', 'John', 'Doe', 'password123');
INSERT INTO User VALUES ('john01', 'John', 'Smith', 'john123');
INSERT INTO User VALUES ('rep01', 'Sarah', 'Johnson', 'rep123');
INSERT INTO User VALUES ('user02', 'Jane', 'Williams', 'jane123');
INSERT INTO User VALUES ('user03', 'Michael', 'Brown', 'michael123');
INSERT INTO User VALUES ('user04', 'Emily', 'Davis', 'emily123');
INSERT INTO User VALUES ('user05', 'David', 'Miller', 'david123');

-- Insert User Roles
INSERT INTO Admin VALUES ('admin01');
INSERT INTO Customer VALUES ('user01', 'ACC001');
INSERT INTO Customer VALUES ('john01', 'ACC002');
INSERT INTO Customer VALUES ('user02', 'ACC003');
INSERT INTO Customer VALUES ('user03', 'ACC004');
INSERT INTO Customer VALUES ('user04', 'ACC005');
INSERT INTO Customer VALUES ('user05', 'ACC006');
INSERT INTO Customer_Rep VALUES ('rep01');

-- Insert Airlines
INSERT INTO Airline VALUES ('AA', 'American Airlines');
INSERT INTO Airline VALUES ('DL', 'Delta Air Lines');
INSERT INTO Airline VALUES ('UA', 'United Airlines');
INSERT INTO Airline VALUES ('B6', 'JetBlue Airways');
INSERT INTO Airline VALUES ('WN', 'Southwest Airlines');

-- Insert Airports
INSERT INTO Airport VALUES ('JFK', 'John F. Kennedy International Airport');
INSERT INTO Airport VALUES ('LAX', 'Los Angeles International Airport');
INSERT INTO Airport VALUES ('ORD', 'O\'Hare International Airport');
INSERT INTO Airport VALUES ('ATL', 'Hartsfield-Jackson Atlanta Airport');
INSERT INTO Airport VALUES ('SFO', 'San Francisco International Airport');
INSERT INTO Airport VALUES ('DFW', 'Dallas/Fort Worth International Airport');
INSERT INTO Airport VALUES ('MIA', 'Miami International Airport');
INSERT INTO Airport VALUES ('SEA', 'Seattle-Tacoma International Airport');
INSERT INTO Airport VALUES ('LAS', 'Harry Reid International Airport');
INSERT INTO Airport VALUES ('BOS', 'Boston Logan International Airport');

-- Insert Aircraft
INSERT INTO Aircraft VALUES ('B737-AA1', 'AA', 180);
INSERT INTO Aircraft VALUES ('B787-DL1', 'DL', 250);
INSERT INTO Aircraft VALUES ('A320-UA1', 'UA', 150);
INSERT INTO Aircraft VALUES ('A321-B61', 'B6', 200);
INSERT INTO Aircraft VALUES ('B737-WN1', 'WN', 175);
INSERT INTO Aircraft VALUES ('A320-AA2', 'AA', 150);
INSERT INTO Aircraft VALUES ('B777-DL2', 'DL', 300);
INSERT INTO Aircraft VALUES ('B737-UA2', 'UA', 180);

-- Insert Seats (Sample seats for each aircraft)
INSERT INTO Seat VALUES ('A1', 'B737-AA1', 'First');
INSERT INTO Seat VALUES ('B1', 'B737-AA1', 'First');
INSERT INTO Seat VALUES ('C1', 'B737-AA1', 'Business');
INSERT INTO Seat VALUES ('D1', 'B737-AA1', 'Economy');

INSERT INTO Seat VALUES ('A1', 'B787-DL1', 'First');
INSERT INTO Seat VALUES ('B1', 'B787-DL1', 'First');
INSERT INTO Seat VALUES ('C1', 'B787-DL1', 'Business');
INSERT INTO Seat VALUES ('D1', 'B787-DL1', 'Economy');

INSERT INTO Seat VALUES ('A1', 'A320-UA1', 'First');
INSERT INTO Seat VALUES ('B1', 'A320-UA1', 'Business');
INSERT INTO Seat VALUES ('C1', 'A320-UA1', 'Economy');
INSERT INTO Seat VALUES ('D1', 'A320-UA1', 'Economy');

INSERT INTO Seat VALUES ('A1', 'A321-B61', 'First');
INSERT INTO Seat VALUES ('B1', 'A321-B61', 'Business');
INSERT INTO Seat VALUES ('C1', 'A321-B61', 'Economy');
INSERT INTO Seat VALUES ('D1', 'A321-B61', 'Economy');

-- Insert more seats for other aircraft
INSERT INTO Seat VALUES ('A1', 'B737-WN1', 'Business');
INSERT INTO Seat VALUES ('B1', 'B737-WN1', 'Economy');
INSERT INTO Seat VALUES ('A1', 'A320-AA2', 'First');
INSERT INTO Seat VALUES ('B1', 'A320-AA2', 'Economy');
INSERT INTO Seat VALUES ('A1', 'B777-DL2', 'First');
INSERT INTO Seat VALUES ('B1', 'B777-DL2', 'Business');
INSERT INTO Seat VALUES ('A1', 'B737-UA2', 'First');
INSERT INTO Seat VALUES ('B1', 'B737-UA2', 'Economy');

-- Insert Flights
INSERT INTO Flight VALUES ('AA100', 'Domestic', '08:00:00', '11:30:00', 'JFK', 'LAX', 'B737-AA1', 'AA', 350.00);
INSERT INTO Flight VALUES ('DL200', 'Domestic', '09:15:00', '12:45:00', 'ATL', 'SFO', 'B787-DL1', 'DL', 750.00);
INSERT INTO Flight VALUES ('UA300', 'Domestic', '10:30:00', '13:00:00', 'ORD', 'MIA', 'A320-UA1', 'UA', 1200.00);
INSERT INTO Flight VALUES ('B6400', 'Domestic', '14:00:00', '17:30:00', 'BOS', 'LAS', 'A321-B61', 'B6', 400.00);
INSERT INTO Flight VALUES ('WN500', 'Domestic', '16:45:00', '19:15:00', 'DFW', 'SEA', 'B737-WN1', 'WN', 850.00);
INSERT INTO Flight VALUES ('AA101', 'International', '23:00:00', '05:30:00', 'JFK', 'LAX', 'A320-AA2', 'AA', 320.00);
INSERT INTO Flight VALUES ('DL201', 'Domestic', '06:30:00', '09:45:00', 'ATL', 'JFK', 'B777-DL2', 'DL', 1500.00);
INSERT INTO Flight VALUES ('UA301', 'Domestic', '11:15:00', '14:45:00', 'SFO', 'ORD', 'B737-UA2', 'UA', 380.00);

-- Insert Days
INSERT INTO Days VALUES (1, 'Monday');
INSERT INTO Days VALUES (2, 'Tuesday');
INSERT INTO Days VALUES (3, 'Wednesday');
INSERT INTO Days VALUES (4, 'Thursday');
INSERT INTO Days VALUES (5, 'Friday');
INSERT INTO Days VALUES (6, 'Saturday');
INSERT INTO Days VALUES (7, 'Sunday');

-- Insert Flies_on (Which days flights operate)
INSERT INTO Flies_on VALUES ('AA100', 'AA', 1);
INSERT INTO Flies_on VALUES ('AA100', 'AA', 3);
INSERT INTO Flies_on VALUES ('AA100', 'AA', 5);
INSERT INTO Flies_on VALUES ('DL200', 'DL', 2);
INSERT INTO Flies_on VALUES ('DL200', 'DL', 4);
INSERT INTO Flies_on VALUES ('DL200', 'DL', 6);
INSERT INTO Flies_on VALUES ('UA300', 'UA', 1);
INSERT INTO Flies_on VALUES ('UA300', 'UA', 4);
INSERT INTO Flies_on VALUES ('UA300', 'UA', 7);
INSERT INTO Flies_on VALUES ('B6400', 'B6', 1);
INSERT INTO Flies_on VALUES ('B6400', 'B6', 2);
INSERT INTO Flies_on VALUES ('B6400', 'B6', 3);
INSERT INTO Flies_on VALUES ('WN500', 'WN', 5);
INSERT INTO Flies_on VALUES ('WN500', 'WN', 6);
INSERT INTO Flies_on VALUES ('WN500', 'WN', 7);

-- Daily flights
INSERT INTO Flies_on VALUES ('AA101', 'AA', 1);
INSERT INTO Flies_on VALUES ('AA101', 'AA', 2);
INSERT INTO Flies_on VALUES ('AA101', 'AA', 3);
INSERT INTO Flies_on VALUES ('AA101', 'AA', 4);
INSERT INTO Flies_on VALUES ('AA101', 'AA', 5);
INSERT INTO Flies_on VALUES ('AA101', 'AA', 6);
INSERT INTO Flies_on VALUES ('AA101', 'AA', 7);

-- Insert Tickets
INSERT INTO Ticket VALUES ('T0001', 'user01', 'Economy', '2025-05-15', 'D1', 'B737-AA1', 'AA100', 350.00);
INSERT INTO Ticket VALUES ('T0002', 'john01', 'Business', '2025-05-20', 'C1', 'B787-DL1', 'DL200', 750.00);
INSERT INTO Ticket VALUES ('T0003', 'user02', 'First', '2025-06-10', 'A1', 'A320-UA1', 'UA300', 1200.00);
INSERT INTO Ticket VALUES ('T0004', 'user03', 'Economy', '2025-06-15', 'D1', 'A321-B61', 'B6400', 400.00);
INSERT INTO Ticket VALUES ('T0005', 'user04', 'Business', '2025-07-01', 'A1', 'B737-WN1', 'WN500', 850.00);
INSERT INTO Ticket VALUES ('T0006', 'user05', 'Economy', '2025-07-05', 'B1', 'A320-AA2', 'AA101', 320.00);
INSERT INTO Ticket VALUES ('T0007', 'user01', 'First', '2025-08-10', 'A1', 'B777-DL2', 'DL201', 1500.00);
INSERT INTO Ticket VALUES ('T0008', 'john01', 'Economy', '2025-08-15', 'B1', 'B737-UA2', 'UA301', 380.00);

-- Insert Travel Records
INSERT INTO Travel VALUES ('user01', 'AA100', 'AA', '2025-05-15', 25.00, 'D1', 'B737-AA1');
INSERT INTO Travel VALUES ('john01', 'DL200', 'DL', '2025-05-20', 30.00, 'C1', 'B787-DL1');
INSERT INTO Travel VALUES ('user02', 'UA300', 'UA', '2025-06-10', 35.00, 'A1', 'A320-UA1');
INSERT INTO Travel VALUES ('user03', 'B6400', 'B6', '2025-06-15', 25.00, 'D1', 'A321-B61');
INSERT INTO Travel VALUES ('user04', 'WN500', 'WN', '2025-07-01', 30.00, 'A1', 'B737-WN1');
INSERT INTO Travel VALUES ('user05', 'AA101', 'AA', '2025-07-05', 25.00, 'B1', 'A320-AA2');
INSERT INTO Travel VALUES ('user01', 'DL201', 'DL', '2025-08-10', 35.00, 'A1', 'B777-DL2');
INSERT INTO Travel VALUES ('john01', 'UA301', 'UA', '2025-08-15', 25.00, 'B1', 'B737-UA2');

-- Insert Sample QnA
INSERT INTO QnA (customer_id, question_text, question_date)
VALUES ('user01', 'How do I change my seat assignment for flight AA100?', '2025-05-10 14:30:00');

INSERT INTO QnA (customer_id, rep_id, question_text, answer_text, question_date, answer_date)
VALUES ('john01', 'rep01', 'Can I get a refund for my ticket?', 'Yes, you can get a refund if you cancel at least 24 hours before departure.', '2025-05-12 09:15:00', '2025-05-12 11:30:00');

INSERT INTO QnA (customer_id, question_text, question_date)
VALUES ('user02', 'What is the baggage allowance for international flights?', '2025-05-14 16:45:00');

INSERT INTO QnA (customer_id, rep_id, question_text, answer_text, question_date, answer_date)
VALUES ('user03', 'rep01', 'How early should I arrive at the airport for flight B6400?', 'We recommend arriving 2 hours before domestic flights and 3 hours before international flights.', '2025-05-18 13:20:00', '2025-05-18 14:05:00');

INSERT INTO QnA (customer_id, question_text, question_date)
VALUES ('user04', 'Is there Wi-Fi available on flight WN500?', '2025-06-25 10:10:00');