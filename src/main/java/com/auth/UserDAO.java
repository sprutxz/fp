package com.auth;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class UserDAO {
    
    public User validate(String userId, String password) throws ClassNotFoundException, SQLException {
        Connection connection = null;
        PreparedStatement statement = null;
        ResultSet resultSet = null;
        User user = null;
        
        try {
            connection = DatabaseConnection.getConnection();
            String sql = "SELECT * FROM User WHERE user_id = ? AND password = ?";
            statement = connection.prepareStatement(sql);
            statement.setString(1, userId);
            statement.setString(2, password);
            resultSet = statement.executeQuery();
            
            if (resultSet.next()) {
                user = new User();
                user.setUserId(resultSet.getString("user_id"));
                user.setFirstName(resultSet.getString("first_name"));
                user.setLastName(resultSet.getString("last_name"));
                user.setPassword(resultSet.getString("password"));
            }
        } finally {
            if (resultSet != null) resultSet.close();
            if (statement != null) statement.close();
            if (connection != null) connection.close();
        }
        
        return user;
    }
}