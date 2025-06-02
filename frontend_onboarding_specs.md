# IONFLUX Project: Frontend Onboarding & Initial Workspace Interaction Specifications (E2E Demo)

This document outlines the frontend specifications for the user onboarding (signup, login) and initial workspace interaction screens necessary for the IONFLUX E2E Demo. It is based on `ui_ux_concepts.md`, `user_service_minimal_spec.md`, `workspace_service_minimal_spec.md`, and assumes a React (with Next.js) frontend stack as per `technical_stack_and_demo_strategy.md`.

## 1. Signup Screen

*   **Purpose:** Allows new users to create an IONFLUX account.
*   **Key UI Elements & Layout (referencing `ui_ux_concepts.md` for general style):**
    *   **Logo:** IONFLUX logo prominently displayed.
    *   **Title:** "Create your IONFLUX Account" or similar.
    *   **Name Input:**
        *   Label: "Full Name"
        *   Type: Text input
        *   Placeholder: "e.g., Ada Lovelace"
    *   **Email Input:**
        *   Label: "Email Address"
        *   Type: Email input
        *   Placeholder: "you@example.com"
    *   **Password Input:**
        *   Label: "Password"
        *   Type: Password input
        *   Placeholder: "Enter your password"
        *   (Consideration for future: password strength indicator, show/hide toggle)
    *   **Signup Button:**
        *   Label: "Sign Up" or "Create Account"
        *   Type: Primary button
    *   **Login Link:**
        *   Text: "Already have an account? Log In"
        *   Action: Navigates to the Login Screen.
    *   **Error Display Area:** A section to display API error messages or validation feedback.
*   **API Interaction:**
    *   **On Submit (Signup Button Click):**
        *   **Endpoint:** `POST /auth/register` (User Service)
        *   **Request Body (from `user_service_minimal_spec.md`):**
            ```json
            {
              "email": "user_entered_email",
              "name": "user_entered_name",
              "password": "user_entered_password"
            }
            ```
        *   **Success Handling (HTTP 201):**
            *   Response: `{"id": "uuid", "email": "string", "name": "string", "message": "User registered successfully"}`.
            *   Action: Display success message briefly. Redirect user to the Login Screen or directly to the Workspace Dashboard/Main View if auto-login after signup is implemented (for demo, redirect to Login is simpler).
        *   **Error Handling:**
            *   HTTP 400 (Validation Error): Display specific error messages from response (e.g., "Email is required," "Password too short").
            *   HTTP 409 (Conflict - Email Exists): Display "Email already registered. Try logging in."
            *   Other errors (500): Display a generic "Signup failed. Please try again."
*   **Client-Side State Management (e.g., using React state - `useState`, or a state management library like Zustand/Redux for larger app):**
    *   `name`: String (for name input)
    *   `email`: String (for email input)
    *   `password`: String (for password input)
    *   `isLoading`: Boolean (to show loading spinner on button during API call)
    *   `error`: String or Object (to store and display error messages from API or client-side validation)
    *   Client-side validation for email format and password length before API call.

## 2. Login Screen

*   **Purpose:** Allows existing users to log into their IONFLUX account.
*   **Key UI Elements & Layout:**
    *   **Logo:** IONFLUX logo.
    *   **Title:** "Log In to IONFLUX" or "Welcome Back!"
    *   **Email Input:**
        *   Label: "Email Address"
        *   Type: Email input
        *   Placeholder: "you@example.com"
    *   **Password Input:**
        *   Label: "Password"
        *   Type: Password input
        *   Placeholder: "Enter your password"
    *   **Login Button:**
        *   Label: "Log In"
        *   Type: Primary button
    *   **Signup Link:**
        *   Text: "Don't have an account? Sign Up"
        *   Action: Navigates to the Signup Screen.
    *   **Error Display Area.**
*   **API Interaction:**
    *   **On Submit (Login Button Click):**
        *   **Endpoint:** `POST /auth/login` (User Service)
        *   **Request Body (from `user_service_minimal_spec.md`):**
            ```json
            {
              "email": "user_entered_email",
              "password": "user_entered_password"
            }
            ```
        *   **Success Handling (HTTP 200):**
            *   Response: `{"token": "jwt_string", "user": {"id": "uuid", "email": "string", "name": "string"}}`.
            *   Action:
                1.  Store JWT securely (e.g., `localStorage` for demo simplicity; HttpOnly cookie is preferred for production).
                2.  Store basic user info (id, name, email) in global state/context.
                3.  Redirect user to the Main Application Layout (e.g., `/dashboard` or `/workspace/:workspaceId` if a default/last-used workspace is known).
        *   **Error Handling:**
            *   HTTP 401 (Unauthorized): Display "Invalid email or password."
            *   Other errors: Display generic error message.
*   **Client-Side State Management:**
    *   `email`: String
    *   `password`: String
    *   `isLoading`: Boolean
    *   `error`: String or Object
    *   `jwtToken`: String (stored in localStorage/cookie and potentially in global state for API headers)
    *   `currentUser`: Object (storing `id`, `name`, `email` of the authenticated user in global state/context)

## 3. Main Application Layout (Initial Shell)

*   **Purpose:** Provides the persistent structure of the application after login, primarily the sidebar and main content area.
*   **Key UI Elements & Layout (referencing `ui_ux_concepts.md` Section 1):**
    *   **Persistent Sidebar (Left):**
        *   Collapsible (icon button to toggle).
        *   **Workspace Switcher (Top-most element):**
            *   Displays `currentWorkspace.name` (if a workspace is selected/loaded).
            *   Dropdown icon.
            *   **Dropdown Menu:**
                *   Lists available workspaces (`userWorkspaces`). Each item shows workspace name and is clickable to switch.
                *   "Create New Workspace" button/option: Opens the Create Workspace Modal.
                *   (Future: "Workspace Settings" option).
        *   **Navigation Sections (Placeholders for Demo):**
            *   "Canvas / Pages" (Link to a placeholder page or root canvas view)
            *   "Personas / Assets" (Link)
            *   "Libraries" (Link)
            *   "Agents" (Link to Agent Hub/Marketplace placeholder)
        *   **Global Items (Bottom):**
            *   Search Icon (placeholder, could trigger Command Palette in future).
            *   Notifications Icon (placeholder).
            *   User Avatar / Profile Menu (placeholder, could show `currentUser.name` and a logout option).
    *   **Main Content Area (Right):**
        *   A flexible container that will render different views based on navigation (e.g., a welcome dashboard, a Canvas page view, settings pages). For initial onboarding, this might be empty or show a "Select or Create a Workspace" prompt if no workspace is active.
*   **API Interaction:**
    *   **On Initial Load (after login or if JWT exists):**
        *   Call `GET /workspaces` (Workspace Service) using the stored JWT to fetch the list of workspaces for the current user.
        *   If workspaces exist, potentially set the first one as `currentWorkspace` or the last accessed one (if stored).
    *   **On Workspace Switch:**
        *   Update `currentWorkspace` in state.
        *   Trigger re-fetch of data relevant to the new workspace (e.g., canvas pages for that workspace - to be implemented in later specs).
    *   **On "Create New Workspace" click:** Open the Create Workspace Modal.
*   **Client-Side State Management (Global Context / Zustand / Redux):**
    *   `jwtToken`: String (retrieved from storage to include in API headers).
    *   `currentUser`: Object (user details).
    *   `userWorkspaces`: Array of workspace objects `[{"id": "uuid", "name": "string", ...}]`.
    *   `currentWorkspace`: Object (the currently active workspace, e.g., `{"id": "uuid", "name": "string"}`).
    *   `isSidebarCollapsed`: Boolean.
    *   `isLoadingWorkspaces`: Boolean.
    *   `workspaceError`: String or Object.

## 4. Create Workspace Modal/View

*   **Purpose:** Allows users to create a new workspace.
*   **Key UI Elements & Layout:**
    *   **Modal Dialog or Dedicated View:**
        *   Title: "Create New Workspace"
        *   **Workspace Name Input:**
            *   Label: "Workspace Name"
            *   Type: Text input
            *   Placeholder: "e.g., My Marketing Agency, Q4 Campaign"
        *   **Create Button:**
            *   Label: "Create Workspace"
            *   Type: Primary button
        *   **Cancel Button:** Closes the modal/view.
        *   **Error Display Area.**
*   **API Interaction:**
    *   **On Submit (Create Button Click):**
        *   **Endpoint:** `POST /workspaces` (Workspace Service)
        *   **Headers:** Include JWT for authentication.
        *   **Request Body (from `workspace_service_minimal_spec.md`):**
            ```json
            {
              "name": "entered_workspace_name"
            }
            ```
        *   **Success Handling (HTTP 201):**
            *   Response: `{"id": "uuid", "name": "string", "owner_user_id": "uuid", ...}`.
            *   Action:
                1.  Add the new workspace to the `userWorkspaces` list in the global state.
                2.  Optionally, set this new workspace as the `currentWorkspace`.
                3.  Close the modal/view.
                4.  Potentially redirect/navigate to this new workspace's default view.
        *   **Error Handling:**
            *   HTTP 400 (Validation Error): Display error.
            *   HTTP 401 (Unauthorized): Handle (e.g., redirect to login).
            *   Other errors: Display generic error message.
*   **Client-Side State Management (Local component state or part of a form management library):**
    *   `workspaceName`: String (for the input field).
    *   `isLoading`: Boolean (for create button).
    *   `error`: String or Object.

This specification provides a foundational guide for developing the initial onboarding and workspace interaction frontend components, focusing on the E2E demo requirements.
```
