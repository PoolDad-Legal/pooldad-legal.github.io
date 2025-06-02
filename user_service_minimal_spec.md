# IONFLUX Project: Minimal Viable User Service Specification (E2E Demo)

This document defines the specifications for a minimal viable User Service shell required for the IONFLUX E2E Demo. Its primary purpose is to handle basic user registration, login, and provide a mechanism for other services to validate user identity (via JWT) and fetch minimal user details.

**Chosen Technology:** Node.js with Express.js (as per `technical_stack_and_demo_strategy.md` for simplicity in a minimal shell).

## 1. API Endpoints (RESTful)

The following RESTful API endpoints will be provided by the User Service:

### 1.1. `POST /auth/register`

*   **Purpose:** Allows a new user to register with the IONFLUX platform.
*   **Request Body:**
    ```json
    {
      "email": "string",
      "name": "string",
      "password": "string"
    }
    ```
*   **Response (Success 201 - Created):**
    ```json
    {
      "id": "uuid",         // User's unique ID from the database
      "email": "string",
      "name": "string",
      "message": "User registered successfully"
    }
    ```
*   **Response (Error 400 - Bad Request):**
    *   If request body validation fails (e.g., missing fields, invalid email format).
    ```json
    {
      "error": "Validation error",
      "details": ["Email is required", "Password must be at least 8 characters"] // Example details
    }
    ```
*   **Response (Error 409 - Conflict):**
    *   If the email already exists in the database.
    ```json
    {
      "error": "Email already registered"
    }
    ```
*   **Brief Logic:**
    1.  Validate request body (email format, password complexity for demo can be minimal but noted for production).
    2.  Check if a user with the given email already exists in the `Users` table.
    3.  If not, hash the provided password using `bcrypt`.
    4.  Create a new record in the `Users` table with `id` (auto-generated UUID), `email`, `name`, and `password_hash`.
    5.  Return the new user's details (excluding password hash).

### 1.2. `POST /auth/login`

*   **Purpose:** Allows an existing user to log in and obtain a session token (JWT).
*   **Request Body:**
    ```json
    {
      "email": "string",
      "password": "string"
    }
    ```
*   **Response (Success 200 - OK):**
    ```json
    {
      "token": "jwt_string",  // JSON Web Token
      "user": {
        "id": "uuid",
        "email": "string",
        "name": "string"
      }
    }
    ```
*   **Response (Error 401 - Unauthorized):**
    *   If email is not found or password does not match.
    ```json
    {
      "error": "Invalid email or password"
    }
    ```
*   **Brief Logic:**
    1.  Validate request body.
    2.  Fetch user record from the `Users` table by email.
    3.  If user exists, compare the provided password with the stored `password_hash` using `bcrypt.compare()`.
    4.  If credentials are valid, generate a JWT containing user's `id` and `email`. For the demo, this JWT can have a short expiration (e.g., 1-8 hours).
    5.  Return the JWT and basic user information.

### 1.3. `GET /users/me` (Protected Endpoint)

*   **Purpose:** Allows an authenticated user to retrieve their own profile information.
*   **Authentication:** Requires a valid JWT in the `Authorization` header (e.g., `Authorization: Bearer <jwt_string>`).
*   **Response (Success 200 - OK):**
    ```json
    {
      "id": "uuid",
      "email": "string",
      "name": "string"
      // Other non-sensitive fields from Users table can be added if needed
    }
    ```
*   **Response (Error 401 - Unauthorized):**
    *   If no token is provided or the token is invalid/expired.
    ```json
    {
      "error": "Unauthorized: Access token is missing or invalid"
    }
    ```
*   **Response (Error 403 - Forbidden):**
    *   (Less likely for `/users/me` if token is valid for self, but good to note for other protected routes).
*   **Brief Logic:**
    1.  Middleware validates the JWT from the `Authorization` header.
    2.  If valid, extracts user ID from the token payload.
    3.  Fetches the user record from the `Users` table using the ID.
    4.  Returns user details (excluding sensitive information like `password_hash`).

### 1.4. (Optional) `GET /users/:id/details` (Protected Inter-Service Endpoint)

*   **Purpose:** Allows other backend services to fetch minimal, non-sensitive details of a specific user. This is crucial for scenarios where a service receives a `user_id` and needs to know, for example, the user's name for a notification, or email for an integration task, without exposing the full User object or requiring the end-user's JWT.
*   **Authentication:** For inter-service communication, this endpoint should be protected. Methods for demo:
    *   Simple shared API key/secret in the header.
    *   Network policies (if running in a managed environment like Kubernetes, allowing calls only from specific internal services).
    *   *Note: For a production environment, more robust service-to-service authentication like mTLS or OAuth client credentials would be used.*
*   **Path Parameter:** `id` (UUID of the user).
*   **Response (Success 200 - OK):**
    ```json
    {
      "id": "uuid",
      "name": "string",
      "email": "string"
    }
    ```
*   **Response (Error 401/403 - Unauthorized/Forbidden):**
    *   If inter-service auth fails.
*   **Response (Error 404 - Not Found):**
    *   If no user exists with the given `:id`.
*   **Brief Logic:**
    1.  Middleware validates inter-service authentication mechanism.
    2.  Fetches user record from `Users` table by the provided `:id`.
    3.  Returns minimal, non-sensitive user details.

## 2. Core Logic (Simplified for Demo)

*   **Password Hashing:**
    *   **Library:** `bcrypt` (standard Node.js library for password hashing).
    *   **Process:** Generate a salt and hash the password during registration. Compare the provided password with the stored hash during login.
*   **JWT Generation/Validation:**
    *   **Library:** `jsonwebtoken` (popular Node.js library).
    *   **Secret:** For the demo, a simple, hardcoded string can be used as the JWT secret (e.g., `IONFLUX_DEMO_SECRET_KEY_REPLACE_IN_PROD`). **This MUST be replaced with a strong, environment-managed secret in any non-demo environment.**
    *   **Payload:** Include `userId`, `email`, and an expiration time (`exp`).
    *   **Validation:** Middleware will verify the token's signature and expiration on protected routes.
*   **Database Interaction:**
    *   **Driver:** `pg` (Node.js PostgreSQL client).
    *   **Queries:** Basic SQL `INSERT` for registration, `SELECT` for login and fetching user details. Parameterized queries should be used to prevent SQL injection, even in a demo.
    *   The service will interact with the `Users` table as defined in `initial_schema_demo.sql`.

## 3. Framework & Libraries

*   **Framework:** Express.js
    *   Chosen for its simplicity and wide adoption, making it suitable for a minimal viable service shell.
*   **Key Libraries:**
    *   `express`: Web framework.
    *   `pg`: PostgreSQL client.
    *   `bcrypt`: Password hashing.
    *   `jsonwebtoken`: JWT handling.
    *   `uuid`: For generating UUIDs if not handled by the database default.
    *   Basic input validation library (e.g., `express-validator` or manual checks for demo).

This specification provides the blueprint for a User Service that is minimal yet functional enough to support the user authentication and identification needs of the IONFLUX E2E Demo.
```
