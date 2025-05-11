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
    
    /**
     * Get the role of a user
     * @param userId the user's ID
     * @return "admin", "customer_rep", or "customer" as a string, or null if not found
     * @throws ClassNotFoundException
     * @throws SQLException
     */
    public String getUserRole(String userId) throws ClassNotFoundException, SQLException {
        Connection connection = null;
        PreparedStatement statement = null;
        ResultSet resultSet = null;
        String role = null;
        
        try {
            connection = DatabaseConnection.getConnection();
            
            // Check if admin
            String sql = "SELECT 1 FROM Admin WHERE user_id = ?";
            statement = connection.prepareStatement(sql);
            statement.setString(1, userId);
            resultSet = statement.executeQuery();
            
            if (resultSet.next()) {
                return "admin";
            }
            
            // Close the previous result set and statement
            resultSet.close();
            statement.close();
            
            // Check if customer rep
            sql = "SELECT 1 FROM Customer_Rep WHERE user_id = ?";
            statement = connection.prepareStatement(sql);
            statement.setString(1, userId);
            resultSet = statement.executeQuery();
            
            if (resultSet.next()) {
                return "customer_rep";
            }
            
            // Close the previous result set and statement
            resultSet.close();
            statement.close();
            
            // Check if customer
            sql = "SELECT 1 FROM Customer WHERE user_id = ?";
            statement = connection.prepareStatement(sql);
            statement.setString(1, userId);
            resultSet = statement.executeQuery();
            
            if (resultSet.next()) {
                return "customer";
            }
        } finally {
            if (resultSet != null) resultSet.close();
            if (statement != null) statement.close();
            if (connection != null) connection.close();
        }
        
        return role;
    }
}