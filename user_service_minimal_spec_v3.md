# IONFLUX Project: Minimal Viable User Service Specification (v3)

This document provides the V3 specifications for a minimal viable User Service shell required for the IONFLUX E2E Demo. Its primary purpose is to handle basic user registration, login, and provide a mechanism for other services to validate user identity (via JWT) and fetch user details, aligning with `initial_schema_demo_v3.sql` and `technical_stack_and_demo_strategy_v3.md`.

**Version Note:** This is v3 of the User Service minimal specification.

**Chosen Technology:** Node.js with Express.js (reconfirmed as per `technical_stack_and_demo_strategy_v3.md`).

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
*   **Response (Success 201 - Created):** (For minimal demo; `profile_info_json` etc. will be defaulted in DB and can be fetched via `/users/me`)
    ```json
    {
      "id": "uuid",
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
      "details": ["Email is required", "Password must be at least 8 characters"]
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
    1.  Validate request body (email format, password complexity for demo can be minimal).
    2.  Check if a user with the given email already exists in the `users` table.
    3.  If not, hash the provided password using `bcrypt`.
    4.  Create a new record in the `users` table. `profile_info_json` and `payment_provider_details_json` can be defaulted to `null` or empty JSON objects (`'{}'::jsonb`) by the database or application logic during user creation.
    5.  Return the new user's basic details.

### 1.2. `POST /auth/login`

*   **Purpose:** Allows an existing user to log in and obtain a session token (JWT).
*   **Request Body:**
    ```json
    {
      "email": "string",
      "password": "string"
    }
    ```
*   **Response (Success 200 - OK):** (User object updated to reflect v3 schema)
    ```json
    {
      "token": "jwt_string",
      "user": {
        "id": "uuid",
        "email": "string",
        "name": "string",
        "profile_info_json": {
            "avatar_url": null,
            "bio": null,
            "user_preferences_json": {}
        }, // Or null if not yet populated / defaulted in DB
        "created_at": "timestamp",
        "updated_at": "timestamp"
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
    2.  Fetch user record from `users` table by email.
    3.  If user exists, compare the provided password with the stored `password_hash` using `bcrypt.compare()`.
    4.  If credentials are valid, generate a JWT containing user's `id` and `email`.
    5.  Return the JWT and user information, including `profile_info_json` (or its default/null state from the DB), `created_at`, and `updated_at`.

### 1.3. `GET /users/me` (Protected Endpoint)

*   **Purpose:** Allows an authenticated user to retrieve their own profile information.
*   **Authentication:** Requires a valid JWT in the `Authorization` header (e.g., `Authorization: Bearer <jwt_string>`).
*   **Response (Success 200 - OK):** (Fully reflects `users` table structure from `initial_schema_demo_v3.sql`, excluding sensitive fields)
    ```json
    {
      "id": "uuid",
      "email": "string",
      "name": "string",
      "profile_info_json": {
        "avatar_url": "string (url, nullable)",
        "bio": "text (nullable)",
        "user_preferences_json": "json_object (nullable)"
      },
      "stripe_customer_id": "string (nullable)",
      "payment_provider_details_json": "json_object (nullable)",
      "created_at": "timestamp",
      "updated_at": "timestamp"
    }
    ```
*   **Response (Error 401 - Unauthorized):**
    *   If no token is provided or the token is invalid/expired.
    ```json
    {
      "error": "Unauthorized: Access token is missing or invalid"
    }
    ```
*   **Brief Logic:**
    1.  Middleware validates the JWT from the `Authorization` header.
    2.  If valid, extracts user ID from the token payload.
    3.  Fetches the user record from the `users` table using the ID.
    4.  Returns user details, including all relevant fields like `profile_info_json`, `stripe_customer_id`, `payment_provider_details_json`, `created_at`, `updated_at`.

### 1.4. (Optional) `GET /users/:id/details` (Protected Inter-Service Endpoint)

*   **Purpose:** Allows other backend services to fetch minimal, non-sensitive details of a specific user.
*   **Authentication:** Inter-service auth (e.g., shared API key for demo).
*   **Response (Success 200 - OK):**
    ```json
    {
      "id": "uuid",
      "name": "string",
      "email": "string"
      // Potentially add profile_info_json.avatar_url if needed by other services for display
    }
    ```
*   (Error responses remain the same: 401/403 for auth failure, 404 if user not found)
*   **Brief Logic:** (As previously defined)

## 2. Core Logic (Simplified for Demo)

*   **Password Hashing:**
    *   **Library:** `bcrypt`.
*   **JWT Generation/Validation:**
    *   **Library:** `jsonwebtoken`.
    *   **Secret:** Demo secret (e.g., `IONFLUX_DEMO_SECRET_KEY_REPLACE_IN_PROD`), to be replaced for production.
*   **Database Interaction:**
    *   **Driver:** `pg` (Node.js PostgreSQL client).
    *   **Queries:** Basic SQL `INSERT` for registration, `SELECT` for login and fetching user details. Parameterized queries must be used.
    *   The service will interact with the `users` table as defined in `initial_schema_demo_v3.sql`, correctly handling reads from and writes to `TEXT` and `JSONB` fields like `profile_info_json`. When inserting a new user, `profile_info_json` can be `NULL` or a default empty JSON object (`'{}'::jsonb`).

## 3. Framework & Libraries

*   **Framework:** Express.js
*   **Key Libraries:**
    *   `express`: Web framework.
    *   `pg`: PostgreSQL client.
    *   `bcrypt`: Password hashing.
    *   `jsonwebtoken`: JWT handling.
    *   `uuid`: For generating UUIDs if not handled by the database default.
    *   Basic input validation library (e.g., `express-validator` or manual checks for demo).

This v3 specification ensures the User Service aligns with the updated database schema (`initial_schema_demo_v3.sql`), particularly regarding the structure of the `users` table and the use of `JSONB` for profile information. Field name conventions (snake_case) are maintained.
```
