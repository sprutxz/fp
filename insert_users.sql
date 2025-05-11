USE userdb;

INSERT INTO User (user_id, first_name, last_name, password) VALUES 
('admin01', 'Admin', 'User', 'admin123'),
('user01', 'Regular', 'User', 'password123'),
('john01', 'John', 'Doe', 'john123');

-- Assign roles to users
INSERT INTO Admin (user_id) VALUES ('admin01');
INSERT INTO Customer (user_id, account_no) VALUES ('user01', 'ACC123456');
INSERT INTO Customer (user_id, account_no) VALUES ('john01', 'ACC789012');