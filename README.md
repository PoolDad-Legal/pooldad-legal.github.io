## Local Agent Development and Handshake

This repository includes a minimal A2A agent example to help you understand local development and the basic A2A handshake process.

### Running the Minimal Agent Example

The example agent is located at `ionverse/libs/a2a_example.py`.

**1. Install Dependencies:** Ensure you have the necessary Python packages installed. If you haven't already, create and activate a virtual environment:

```bash
python -m venv .venv
source .venv/bin/activate  # On Windows use: .venv\Scripts\activate
pip install -r requirements.txt
```

**2. Run the Agent:** Execute the example script:

```bash
python ionverse/libs/a2a_example.py
```

The agent will start and listen on `http://localhost:8000/`. You should see output similar to:

```
INFO:     Started server process [xxxxx]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://localhost:8000 (Press CTRL+C to quit)
```

### Understanding the Handshake

The A2A interaction model, even locally, follows these key steps:

**1. Agent Discovery (Agent Card):**
A client discovers an agent's capabilities by fetching its Agent Card. The minimal example agent exposes its card at: `http://localhost:8000/.well-known/agent.json`

You can try opening this URL in your browser or using `curl`:
```bash
curl http://localhost:8000/.well-known/agent.json
```
This JSON response describes the agent (name, description, URL, skills, capabilities, etc.). The Minimal A2A Agent has a skill with `id: 'minimal_echo'`.

**2. Initiating a Task (Message Send):**
Once a client knows about an agent and its skills, it can send messages to initiate tasks. A2A uses JSON-RPC 2.0 over HTTP. For the `minimal_echo` skill, a client would send a request to the agent's URL (`http://localhost:8000/`) to invoke this skill.

For example, to send a simple text message, the client would construct a JSON-RPC request like this (conceptual example):

```json
{
    "jsonrpc": "2.0",
    "method": "message/send",
    "params": {
        "message": {
            "messageId": "client-message-123",
            "role": "user",
            "parts": [
                {
                    "type": "TextPart",
                    "text": "Hello Agent!"
                }
            ]
        }
        // Optionally, specify skillId if the agent has multiple skills
        // and the default isn't desired, or to be explicit.
        // "skillId": "minimal_echo"
    },
    "id": "rpc-request-1"
}
```
The agent would then process this and respond, in the case of our minimal agent, with "Hello from Minimal A2A Agent!".

**Note:** Interacting via `curl` for anything beyond fetching the Agent Card can be complex due to JSON-RPC formatting. Typically, you'd use an A2A client library or tool.

This example provides a basic illustration of how an A2A agent advertises its capabilities and how a client might begin an interaction. Refer to the full A2A Protocol Specification for detailed information on all methods, task lifecycles, and data types.
