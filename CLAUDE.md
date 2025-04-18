# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands
- Database setup: `mysql -u root -p < database_setup.sql`
- Build: Create WAR file for deployment to Tomcat
- Run: Deploy WAR to Tomcat webapps directory or use IDE integration
- Access application: http://localhost:8080/your-app-name

## Code Style Guidelines
- Java standard naming conventions: camelCase for methods/variables, PascalCase for classes
- 4-space indentation in all Java files
- Use full import statements (avoid wildcard imports)
- Follow JavaBeans pattern with proper getters/setters
- DAO pattern for database operations
- Resource cleanup in finally blocks (Connections, PreparedStatements, ResultSets)
- Handle SQLExceptions appropriately
- Security: Note that passwords should be hashed in production code

## Project Structure
- Standard Maven-like directory structure
- Package by feature/functionality (com.auth)
- MVC-like separation: models (User), data access (UserDAO), views (JSP)

## Database Schema
- User table with user_id, first_name, last_name, password
- Role-based tables (Admin, Customer, Customer_Rep)
- Airline reservation system schema with various related tables
- Sample users: admin01/admin123, user01/password123, john01/john123