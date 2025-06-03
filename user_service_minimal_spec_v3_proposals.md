```markdown
# IONFLUX Project: Minimal Viable User Service Specification (v3 Proposals)

This document proposes updates for the User Service specification, aligning it with the V3 data models in `initial_schema_demo_v3.sql` and the overall technical strategy in `technical_stack_and_demo_strategy_v3.md`.

**Version Note:** This is v3 of the User Service minimal specification.

**Chosen Technology:** Node.js with Express.js (reconfirmed as per `technical_stack_and_demo_strategy_v3.md`).

## 1. API Endpoints (RESTful)

The following RESTful API endpoints will be provided by the User Service:

### 1.1. `POST /auth/register`

*   **Purpose:** Allows a new user to register with the IONFLUX platform.
*   **Request Body:** (No changes to field names, already snake_case)
    ```json
    {
      "email": "string",
      "name": "string",
      "password": "string"
    }
    ```
*   **Response (Success 201 - Created):** (No changes to structure for minimal demo; `profile_info_json` etc. will be defaulted in DB and can be fetched via `/users/me`)
    ```json
    {
      "id": "uuid",
      "email": "string",
      "name": "string",
      "message": "User registered successfully"
    }
    ```
*   **Response (Error 400 - Bad Request):** (No changes)
*   **Response (Error 409 - Conflict):** (No changes)
*   **Brief Logic:**
    1.  Validate request body.
    2.  Check if a user with the given email already exists.
    3.  If not, hash the password using `bcrypt`.
    4.  Create a new record in the `users` table. `profile_info_json` and `payment_provider_details_json` can be defaulted to `null` or empty JSON objects by the database or application logic.
    5.  Return the new user's basic details.

### 1.2. `POST /auth/login`

*   **Purpose:** Allows an existing user to log in and obtain a session token (JWT).
*   **Request Body:** (No changes)
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
        "profile_info_json": { // Example, could be null or basic default
            "avatar_url": null,
            "bio": null,
            "user_preferences_json": {}
        },
        "created_at": "timestamp",
        "updated_at": "timestamp"
      }
    }
    ```
*   **Response (Error 401 - Unauthorized):** (No changes)
*   **Brief Logic:**
    1.  Validate request body.
    2.  Fetch user record from `users` table.
    3.  Compare password with stored `password_hash`.
    4.  If valid, generate JWT.
    5.  Return JWT and user information, including `profile_info_json` (or a default/null state of it), `created_at`, and `updated_at` from the database.

### 1.3. `GET /users/me` (Protected Endpoint)

*   **Purpose:** Allows an authenticated user to retrieve their own profile information.
*   **Authentication:** Requires a valid JWT.
*   **Response (Success 200 - OK):** (Fully reflects `users` table structure from `initial_schema_demo_v3.sql`, excluding sensitive fields)
    ```json
    {
      "id": "uuid",
      "email": "string",
      "name": "string",
      "profile_info_json": { // Actual values from DB
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
*   **Response (Error 401 - Unauthorized):** (No changes)
*   **Brief Logic:**
    1.  Middleware validates JWT.
    2.  Extracts user ID.
    3.  Fetches user from `users` table.
    4.  Returns user details, including all relevant fields like `profile_info_json`, `stripe_customer_id`, `payment_provider_details_json`, `created_at`, `updated_at`.

### 1.4. (Optional) `GET /users/:id/details` (Protected Inter-Service Endpoint)

*   **Purpose:** (No change) Allows other backend services to fetch minimal, non-sensitive details of a specific user.
*   **Authentication:** (No change) Inter-service auth (e.g., shared API key for demo).
*   **Response (Success 200 - OK):** (Align field names if necessary, though current ones are fine)
    ```json
    {
      "id": "uuid",
      "name": "string",
      "email": "string"
      // Potentially add profile_info_json.avatar_url if needed by other services for display
    }
    ```
*   (Error responses remain the same)
*   **Brief Logic:** (No change)

## 2. Core Logic (Simplified for Demo)

*   **Password Hashing:** (No change - bcrypt)
*   **JWT Generation/Validation:** (No change - jsonwebtoken, demo secret)
*   **Database Interaction:**
    *   **Driver:** `pg` (Node.js PostgreSQL client).
    *   **Queries:** Basic SQL `INSERT`, `SELECT`. Parameterized queries.
    *   The service will interact with the `users` table as defined in `initial_schema_demo_v3.sql`, correctly handling reads and writes for `TEXT` and `JSONB` fields like `profile_info_json`. When inserting a new user, `profile_info_json` can be `NULL` or a default empty JSON object (`'{}'::jsonb`).

## 3. Framework & Libraries

*   **Framework:** Express.js (No change)
*   **Key Libraries:** (No change - `express`, `pg`, `bcrypt`, `jsonwebtoken`, `uuid`, validation library)

This v3 specification ensures the User Service aligns with the updated database schema (`initial_schema_demo_v3.sql`), particularly regarding the structure of the `users` table and the use of `JSONB` for profile information. Field name conventions (snake_case) are maintained.
```
