# IONFLUX Project: Frontend Onboarding & Initial Workspace Interaction Specifications (v3 - E2E Demo)

**Version Note:** This is v3 of the Frontend Onboarding specification, aligned with V3 backend services and data models (`user_service_minimal_spec_v3.md`, `workspace_service_minimal_spec_v3.md`, `conceptual_definition_v3.md`, `initial_schema_demo_v3.sql`).

This document outlines the frontend specifications for user onboarding (signup, login) and initial workspace interaction screens for the IONFLUX E2E Demo. It assumes a React (with Next.js) frontend stack.

## 1. Signup Screen

*   **Purpose:** Allows new users to create an IONFLUX account.
*   **Key UI Elements & Layout:** (Largely unchanged from previous spec: Logo, Title, Name Input, Email Input, Password Input, Signup Button, Login Link, Error Display Area)
*   **API Interaction:**
    *   **Endpoint:** `POST /auth/register` (User Service)
    *   **Request Body (as per `user_service_minimal_spec_v3.md`):**
        ```json
        {
          "email": "user_entered_email",
          "name": "user_entered_name",
          "password": "user_entered_password"
        }
        ```
    *   **Success Handling (HTTP 201):**
        *   Response: `{"id": "uuid", "email": "string", "name": "string", "message": "User registered successfully"}`.
        *   Action: Redirect to Login Screen.
    *   (Error Handling as previously defined)
*   **Client-Side State Management:** (Largely unchanged: `name`, `email`, `password`, `isLoading`, `error`)

## 2. Login Screen

*   **Purpose:** Allows existing users to log into their IONFLUX account.
*   **Key UI Elements & Layout:** (Largely unchanged: Logo, Title, Email Input, Password Input, Login Button, Signup Link, Error Display Area)
*   **API Interaction:**
    *   **Endpoint:** `POST /auth/login` (User Service)
    *   **Request Body (as per `user_service_minimal_spec_v3.md`):**
        ```json
        {
          "email": "user_entered_email",
          "password": "user_entered_password"
        }
        ```
    *   **Success Handling (HTTP 200):**
        *   **Response (as per `user_service_minimal_spec_v3.md`):**
            ```json
            {
              "token": "jwt_string",
              "user": {
                "id": "uuid",
                "email": "string",
                "name": "string",
                "profile_info_json": {
                    "avatar_url": null, // Or actual URL
                    "bio": null,        // Or actual bio
                    "user_preferences_json": {} // Or actual preferences
                },
                "created_at": "timestamp",
                "updated_at": "timestamp"
              }
            }
            ```
        *   **Action:**
            1.  Store JWT securely.
            2.  Store the full `user` object (including `profile_info_json`, `created_at`, `updated_at`) in global state/context as `currentUser`.
            3.  Redirect to Main Application Layout.
    *   (Error Handling as previously defined)
*   **Client-Side State Management:**
    *   (Unchanged: `email`, `password`, `isLoading`, `error`, `jwtToken`)
    *   `currentUser`: Object (now stores the richer V3 user object, including `profile_info_json`).

## 3. Main Application Layout (Initial Shell)

*   **Purpose:** Provides the persistent application structure.
*   **Key UI Elements & Layout:** (Largely unchanged: Sidebar with Workspace Switcher, Navigation Sections, Global Items; Main Content Area)
    *   User Avatar / Profile Menu: Should display `currentUser.name` and potentially `currentUser.profile_info_json.avatar_url`.
*   **API Interaction:**
    *   **On Initial Load:**
        *   Call `GET /users/me` (User Service) to fetch full current user details (including full `profile_info_json`, `stripe_customer_id`, `payment_provider_details_json`) and update `currentUser` state.
        *   Call `GET /workspaces` (Workspace Service) to fetch user's workspaces.
            *   **Response items (as per `workspace_service_minimal_spec_v3.md`):**
                ```json
                {
                  "id": "uuid",
                  "name": "string",
                  "owner_user_id": "uuid",
                  "member_user_ids_array": ["uuid"],
                  "settings_json": { /* ... full V3 settings object ... */ },
                  "status": "string",
                  "created_at": "timestamp",
                  "updated_at": "timestamp"
                }
                ```
    *   (Other interactions as previously defined)
*   **Client-Side State Management (Global Context / Store):**
    *   (Unchanged: `jwtToken`, `isSidebarCollapsed`, `isLoadingWorkspaces`, `workspaceError`)
    *   `currentUser`: Stores the full V3 User object.
    *   `userWorkspaces`: Array of V3 Workspace objects (including `settings_json`, `member_user_ids_array`, `status`).
    *   `currentWorkspace`: Stores a full V3 Workspace object.

## 4. Create Workspace Modal/View

*   **Purpose:** Allows users to create a new workspace.
*   **Key UI Elements & Layout:** (Largely unchanged: Title, Workspace Name Input, Create Button, Cancel Button, Error Display Area)
    *   **For E2E Demo:** UI will likely only ask for `name`. Advanced settings (`settings_json`, `member_user_ids_array`) can be defaulted by the backend. The spec should note the API's capability to accept these.
*   **API Interaction:**
    *   **Endpoint:** `POST /workspaces` (Workspace Service).
    *   **Request Body (as per `workspace_service_minimal_spec_v3.md`):**
        ```json
        {
          "name": "entered_workspace_name",
          // For E2E Demo, settings_json and member_user_ids_array might be omitted from UI,
          // relying on backend defaults. But API can accept them:
          "settings_json": { /* ... optional initial settings ... */ },
          "member_user_ids_array": [ /* ... optional initial members ... */ ]
        }
        ```
    *   **Success Handling (HTTP 201):**
        *   **Response (as per `workspace_service_minimal_spec_v3.md`):** Full V3 Workspace object.
        *   Action: Add to `userWorkspaces` list, set as `currentWorkspace`, close modal.
    *   (Error Handling as previously defined)
*   **Client-Side State Management:** (Unchanged: `workspaceName`, `isLoading`, `error`)

---
**Note on V3 Alignment:**
This specification is updated to reflect the richer User and Workspace objects (including `profile_info_json`, `settings_json`, `member_user_ids_array`, `status` fields) returned by the V3 User and Workspace services. While the frontend state will store this richer data, the E2E demo UI for onboarding and initial layout may only utilize a subset of these fields for display, focusing on core information like names and email. The capability to handle and potentially send more detailed configuration (e.g., initial workspace settings) is noted.
---
