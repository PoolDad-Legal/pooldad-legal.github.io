# Agent Blueprint: Canvas Render Agent - v0.9.0

## 1. Overview

*   **Agent Name:** `Canvas Render Agent`
*   **Version:** `0.9.0`
*   **Status:** `development`
*   **Primary Goal:** `Renders a wide array of visual outputs for the IONFLUX Canvas (the user interface layer of the IONFLUX sNetwork). It takes structured data from IONPOD and rendering instructions (e.g., visualization type, component definition) to produce images, interactive charts, UI components, or even complex 2D/3D scenes.`
*   **Key Features:**
    *   **Versatile Rendering:** Supports various types of visual outputs:
        *   Data visualizations (charts, graphs) using libraries like Vega-Lite, D3.js, or Plotly via dedicated transforms.
        *   Static images (e.g., generated from data, or compositions).
        *   HTML/CSS/JS based UI components or fragments.
        *   Potentially 2D/3D graphics and scenes using WebGL-based libraries (e.g., Three.js, Babylon.js) via specialized transforms.
    *   **Data-Driven:** Accepts data CIDs from IONPOD as the source for visualizations and dynamic content.
    *   **Instruction-Based:** Uses rendering instruction CIDs (also from IONPOD) that specify the type of visualization, data mappings, styling, interactivity, etc.
    *   **Output to IONPOD:** Stores rendered artifacts (e.g., SVG/PNG image CIDs, HTML/JS bundle CIDs, scene graph CIDs) back into IONPOD.
    *   **Canvas Integration:** Publishes events (e.g., via NATS) that the IONFLUX Canvas frontend listens to, instructing it to fetch and display/update rendered content in specific areas of the UI.
    *   **Thematic Consistency:** Can leverage themes or style guides (potentially via TechGnosis or configuration) to ensure visual consistency across the Canvas.

## 2. FluxGraph Definition (Conceptual YAML)

```yaml
# /specs/agents/canvas_render_agent_fluxgraph.yaml (Conceptual representation)
version: "0.1.0"
name: "canvas_render_agent_fluxgraph"
description: "Renders visual outputs (charts, UI components, scenes) for the IONFLUX Canvas."

triggers:
  - type: "manual"
  - type: "event_driven"
    config: { event_source: "NATS", topic: "ionflux.canvas.render_request" } # From other agents or UI interactions
  - type: "webhook"
    config: { path: "/webhooks/invoke/canvas_render", method: "POST", authentication_method: "ionwall_jwt" }

input_schema:
  type: "object"
  properties:
    data_cid: { type: "string", nullable: true, description: "CID of the data object in IONPOD to be visualized/rendered. Nullable if instructions are self-contained (e.g. static SVG)." }
    render_instructions_cid: { type: "string", description: "CID of the rendering instructions object in IONPOD (e.g., a Vega-Lite spec, a component definition, a scene graph)." }
    renderer_type_override: { type: "string", nullable: true, enum: ["vegalite", "html_component", "threejs_scene", "mermaid_diagram"], description: "Explicitly specify renderer; otherwise inferred from instructions."}
    target_canvas_area_id: { type: "string", description: "Identifier for the area/panel on the IONFLUX Canvas where the output should be displayed." }
    output_format_preferences: {
      type: "object",
      properties: {
        image_format: {type: "string", enum: ["svg", "png", "jpeg"], default: "svg"},
        interactive: {type: "boolean", default: true}
      },
      nullable: true
    }
  required: [ "render_instructions_cid", "target_canvas_area_id" ]

output_schema:
  type: "object"
  properties:
    rendered_artifact_cid: { type: "string", description: "IPFS CID of the primary rendered output (e.g., image, HTML bundle)." }
    auxiliary_artifact_cids: { type: "object", additionalProperties: {type: "string"}, nullable: true, description: "CIDs of any supporting files, like data files for an interactive HTML component."}
    render_type_used: { type: "string", description: "Actual renderer type used." }
    status: { type: "string", enum: ["success", "failure", "partial_success"] }
    error_message: { type: "string", nullable: true }
    # This agent's output is primarily the NATS event to the Canvas Frontend, not direct data return to requester.
    # The NATS event would contain rendered_artifact_cid and target_canvas_area_id.
  required: [ "status" ]

graph:
  - id: "fetch_render_instructions"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "read_pod_data:canvas_render_instructions"
    inputs:
      cid: "{{trigger.input_data.render_instructions_cid}}"
    outputs: [render_instructions_obj]

  - id: "fetch_visualization_data_conditional"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    if: "{{trigger.input_data.data_cid != null}}"
    ionwall_approval_scope: "read_pod_data:canvas_visualization_data"
    inputs:
      cid: "{{trigger.input_data.data_cid}}"
    outputs: [visualization_data_obj]

  # Router to select the appropriate rendering transform based on instructions or override
  - id: "determine_renderer_type"
    transform: "DetermineRenderType_Transform" # Hypothetical: inspects instructions_obj or uses override
    inputs:
      instructions: "{{nodes.fetch_render_instructions.outputs.render_instructions_obj}}"
      override: "{{trigger.input_data.renderer_type_override}}"
    outputs: [renderer_type_enum] # e.g., "vegalite", "html_component"

  - id: "route_to_renderer"
    transform: "SwitchCaseRouter_Transform"
    inputs:
      switch_value: "{{nodes.determine_renderer_type.outputs.renderer_type_enum}}"
    outputs: [use_vegalite, use_html_component, use_threejs, use_mermaid] # Boolean flags

  # Vega-Lite Rendering Path
  - id: "render_vegalite_chart"
    transform: "VegaLite_Render_Transform" # Assumes this transform can output SVG or PNG
    if: "{{nodes.route_to_renderer.outputs.use_vegalite == true}}"
    ionwall_approval_scope: "execute_rendering_engine:vegalite"
    inputs:
      vega_lite_spec: "{{nodes.fetch_render_instructions.outputs.render_instructions_obj}}" # The instructions are the Vega-Lite spec
      data: "{{nodes.fetch_visualization_data_conditional.outputs.visualization_data_obj}}" # Optional data for Vega-Lite
      output_format: "{{trigger.input_data.output_format_preferences.image_format || 'svg'}}"
    outputs: [rendered_image_blob, actual_format] # Blob of SVG/PNG

  # HTML Component Rendering Path (more complex, might involve bundling)
  - id: "render_html_component"
    transform: "HTML_Component_Render_Transform" # Could take HTML template, CSS, JS CIDs from instructions
    if: "{{nodes.route_to_renderer.outputs.use_html_component == true}}"
    ionwall_approval_scope: "execute_rendering_engine:html_component"
    inputs:
      component_definition_obj: "{{nodes.fetch_render_instructions.outputs.render_instructions_obj}}" # Contains template CIDs, data binding info
      dynamic_data: "{{nodes.fetch_visualization_data_conditional.outputs.visualization_data_obj}}"
    outputs: [rendered_html_bundle_blob_or_cid, component_metadata_obj] # Might be a zip or a primary HTML CID

  # Mermaid Diagram Rendering Path
  - id: "render_mermaid_diagram"
    transform: "MermaidRender_Transform"
    if: "{{nodes.route_to_renderer.outputs.use_mermaid == true}}"
    ionwall_approval_scope: "execute_rendering_engine:mermaid"
    inputs:
      mermaid_markdown_string: "{{nodes.fetch_render_instructions.outputs.render_instructions_obj.mermaid_code if nodes.fetch_render_instructions.outputs.render_instructions_obj.mermaid_code else nodes.fetch_visualization_data_conditional.outputs.visualization_data_obj}}" # Instructions could be the mermaid code or data to build it
      output_format: "{{trigger.input_data.output_format_preferences.image_format || 'svg'}}"
    outputs: [rendered_image_blob, actual_format]

  # ... other paths for Three.js, etc. ...

  - id: "store_rendered_artifact"
    transform: "StoreToIONPOD_Transform_IONWALL"
    # This node might need to be duplicated or made conditional if output types differ significantly (e.g. blob vs CID from transform)
    ionwall_approval_scope: "write_pod_data:canvas_rendered_output"
    inputs:
      # Logic to pick the correct blob from Vega-Lite or HTML component path
      data_to_store: "{{nodes.render_vegalite_chart.outputs.rendered_image_blob || nodes.render_html_component.outputs.rendered_html_bundle_blob_or_cid || nodes.render_mermaid_diagram.outputs.rendered_image_blob}}"
      filename_suggestion: "render_{{trigger.input_data.target_canvas_area_id}}_{{system.timestamp_utc_iso}}.{{nodes.render_vegalite_chart.outputs.actual_format || 'html'}}"
      # Mime type needs to be set correctly based on output.
    outputs: [stored_artifact_cid]

  - id: "publish_canvas_update_event" # Notify IONFLUX Canvas Frontend
    transform: "IPC_NATS_Publish_Transform"
    inputs:
      topic: "ionflux.canvas.update_area" # Specific topic for Canvas frontend to listen to
      message:
        target_canvas_area_id: "{{trigger.input_data.target_canvas_area_id}}"
        rendered_artifact_cid: "{{nodes.store_rendered_artifact.outputs.stored_artifact_cid}}"
        renderer_type_used: "{{nodes.determine_renderer_type.outputs.renderer_type_enum}}"
        # Potentially other metadata like dimensions, interactivity hints
        # source_data_cid: "{{trigger.input_data.data_cid}}",
        # source_instructions_cid: "{{trigger.input_data.render_instructions_cid}}"
      # nats_connection_config_cid: from agent PRM for Canvas NATS instance
    dependencies: [store_rendered_artifact]

  - id: "log_render_operation" # Internal logging for Canvas Render Agent
    transform: "StoreToIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "write_pod_data:canvas_render_agent_log" # Separate log scope
    inputs:
      data_to_store: {
        timestamp: "{{system.timestamp_utc}}", agent_name: "Canvas Render Agent", version: "0.9.0",
        request: { data_cid: "{{trigger.input_data.data_cid}}", instructions_cid: "{{trigger.input_data.render_instructions_cid}}", target_area: "{{trigger.input_data.target_canvas_area_id}}"},
        renderer_used: "{{nodes.determine_renderer_type.outputs.renderer_type_enum}}",
        output_cid: "{{nodes.store_rendered_artifact.outputs.stored_artifact_cid}}",
        status: "success" # Basic status, could be more detailed
      }
    outputs: [render_log_cid]
```

---
## 3. Database Schema Fields (`agent_definitions` table)

### 3.1. `agent_name`
`"Canvas Render Agent"`

### 3.2. `version`
`"0.9.0"`

### 3.3. `description`
`"Renders visual outputs for the IONFLUX Canvas based on data from IONPOD, instructions from other agents, or user interactions. This could range from simple data visualizations to complex 2D/3D scenes or UI components."`

### 3.4. `status`
`"development"`

### 3.5. `flux_graph_dsl_yaml`
*(The YAML content from Section 2 is inserted here as a multi-line string)*
```yaml
version: "0.1.0"
name: "canvas_render_agent_fluxgraph"
description: "Renders visual outputs (charts, UI components, scenes) for the IONFLUX Canvas."

triggers:
  - type: "manual"
  - type: "event_driven"
    config: { event_source: "NATS", topic: "ionflux.canvas.render_request" }
  - type: "webhook"
    config: { path: "/webhooks/invoke/canvas_render", method: "POST", authentication_method: "ionwall_jwt" }

input_schema:
  type: "object"
  properties:
    data_cid: { type: "string", nullable: true, description: "CID of the data object in IONPOD to be visualized/rendered." }
    render_instructions_cid: { type: "string", description: "CID of the rendering instructions object in IONPOD." }
    renderer_type_override: { type: "string", nullable: true, enum: ["vegalite", "html_component", "threejs_scene", "mermaid_diagram"], description: "Explicitly specify renderer."}
    target_canvas_area_id: { type: "string", description: "Identifier for the area/panel on the IONFLUX Canvas." }
    output_format_preferences: {
      type: "object",
      properties: {
        image_format: {type: "string", enum: ["svg", "png", "jpeg"], default: "svg"},
        interactive: {type: "boolean", default: true}
      },
      nullable: true
    }
  required: [ "render_instructions_cid", "target_canvas_area_id" ]

output_schema:
  type: "object"
  properties:
    rendered_artifact_cid: { type: "string", description: "IPFS CID of the primary rendered output." }
    auxiliary_artifact_cids: { type: "object", additionalProperties: {type: "string"}, nullable: true, description: "CIDs of any supporting files."}
    render_type_used: { type: "string", description: "Actual renderer type used." }
    status: { type: "string", enum: ["success", "failure", "partial_success"] }
    error_message: { type: "string", nullable: true }
  required: [ "status" ]

graph:
  - id: "fetch_render_instructions"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "read_pod_data:canvas_render_instructions"
    inputs:
      cid: "{{trigger.input_data.render_instructions_cid}}"
    outputs: [render_instructions_obj]

  - id: "fetch_visualization_data_conditional"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    if: "{{trigger.input_data.data_cid != null}}"
    ionwall_approval_scope: "read_pod_data:canvas_visualization_data"
    inputs:
      cid: "{{trigger.input_data.data_cid}}"
    outputs: [visualization_data_obj]

  - id: "determine_renderer_type"
    transform: "DetermineRenderType_Transform"
    inputs:
      instructions: "{{nodes.fetch_render_instructions.outputs.render_instructions_obj}}"
      override: "{{trigger.input_data.renderer_type_override}}"
    outputs: [renderer_type_enum]

  - id: "route_to_renderer"
    transform: "SwitchCaseRouter_Transform"
    inputs:
      switch_value: "{{nodes.determine_renderer_type.outputs.renderer_type_enum}}"
    outputs: [use_vegalite, use_html_component, use_threejs, use_mermaid]

  - id: "render_vegalite_chart"
    transform: "VegaLite_Render_Transform"
    if: "{{nodes.route_to_renderer.outputs.use_vegalite == true}}"
    ionwall_approval_scope: "execute_rendering_engine:vegalite"
    inputs:
      vega_lite_spec: "{{nodes.fetch_render_instructions.outputs.render_instructions_obj}}"
      data: "{{nodes.fetch_visualization_data_conditional.outputs.visualization_data_obj}}"
      output_format: "{{trigger.input_data.output_format_preferences.image_format || 'svg'}}"
    outputs: [rendered_image_blob, actual_format]

  - id: "render_html_component"
    transform: "HTML_Component_Render_Transform"
    if: "{{nodes.route_to_renderer.outputs.use_html_component == true}}"
    ionwall_approval_scope: "execute_rendering_engine:html_component"
    inputs:
      component_definition_obj: "{{nodes.fetch_render_instructions.outputs.render_instructions_obj}}"
      dynamic_data: "{{nodes.fetch_visualization_data_conditional.outputs.visualization_data_obj}}"
    outputs: [rendered_html_bundle_blob_or_cid, component_metadata_obj]

  - id: "render_mermaid_diagram"
    transform: "MermaidRender_Transform"
    if: "{{nodes.route_to_renderer.outputs.use_mermaid == true}}"
    ionwall_approval_scope: "execute_rendering_engine:mermaid"
    inputs:
      mermaid_markdown_string: "{{nodes.fetch_render_instructions.outputs.render_instructions_obj.mermaid_code if nodes.fetch_render_instructions.outputs.render_instructions_obj.mermaid_code else nodes.fetch_visualization_data_conditional.outputs.visualization_data_obj}}"
      output_format: "{{trigger.input_data.output_format_preferences.image_format || 'svg'}}"
    outputs: [rendered_image_blob, actual_format]

  - id: "store_rendered_artifact"
    transform: "StoreToIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "write_pod_data:canvas_rendered_output"
    inputs:
      data_to_store: "{{nodes.render_vegalite_chart.outputs.rendered_image_blob || nodes.render_html_component.outputs.rendered_html_bundle_blob_or_cid || nodes.render_mermaid_diagram.outputs.rendered_image_blob}}"
      filename_suggestion: "render_{{trigger.input_data.target_canvas_area_id}}_{{system.timestamp_utc_iso}}.{{nodes.render_vegalite_chart.outputs.actual_format || 'html'}}"
    outputs: [stored_artifact_cid]

  - id: "publish_canvas_update_event"
    transform: "IPC_NATS_Publish_Transform"
    inputs:
      topic: "ionflux.canvas.update_area"
      message:
        target_canvas_area_id: "{{trigger.input_data.target_canvas_area_id}}"
        rendered_artifact_cid: "{{nodes.store_rendered_artifact.outputs.stored_artifact_cid}}"
        renderer_type_used: "{{nodes.determine_renderer_type.outputs.renderer_type_enum}}"
    dependencies: [store_rendered_artifact]

  - id: "log_render_operation"
    transform: "StoreToIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "write_pod_data:canvas_render_agent_log"
    inputs:
      data_to_store: {
        timestamp: "{{system.timestamp_utc}}", agent_name: "Canvas Render Agent", version: "0.9.0",
        request: { data_cid: "{{trigger.input_data.data_cid}}", instructions_cid: "{{trigger.input_data.render_instructions_cid}}", target_area: "{{trigger.input_data.target_canvas_area_id}}"},
        renderer_used: "{{nodes.determine_renderer_type.outputs.renderer_type_enum}}",
        output_cid: "{{nodes.store_rendered_artifact.outputs.stored_artifact_cid}}",
        status: "success"
      }
    outputs: [render_log_cid]
```

### 3.6. `execution_requirements_json`
```json
{
  "transforms_required": [
    "FetchFromIONPOD_Transform_IONWALL",
    "DetermineRenderType_Transform", // Hypothetical
    "SwitchCaseRouter_Transform",
    "VegaLite_Render_Transform",
    "HTML_Component_Render_Transform", // Could be complex, involving sub-transforms for templating, CSS processing, JS bundling
    "MermaidRender_Transform",
    // "ThreeJS_Scene_Render_Transform", // Example if 3D is supported
    "StoreToIONPOD_Transform_IONWALL",
    "IPC_NATS_Publish_Transform"
  ],
  "min_ram_mb": 512, // Rendering can be memory intensive, especially for complex scenes or large datasets
  "gpu_required": false, // Could be true if using WebGL/GPU-accelerated rendering transforms (e.g., for Three.js)
  "gpu_type_preference": null, // "ANY_AVAILABLE_HARDWARE_ACCELERATED_CANVAS_SUPPORT"
  "estimated_execution_duration_seconds": 5, // Highly variable based on complexity
  "max_concurrent_instances": 5,
  "wasm_modules_cids": {
    "FetchFromIONPOD_Transform_IONWALL": "bafyreibvlobj2rl34gsgxrjltirqesqkfbhtharb3uaxnri3ebpmpah6ce",
    "DetermineRenderType_Transform": "bafyreid7s5k5xqmvxji6q7x5j6z3fpzudqrxqmmt4fxiyp2yjznpq3jsyi", // Placeholder
    "SwitchCaseRouter_Transform": "bafyreig4fxqscqg57f2jhfgfdylncxuc32syjxgyf7yt7noypz7xvo7xoi",
    "VegaLite_Render_Transform": "bafyreifpsyjazchqzk3jlkjh3jqmjpizkpqkpztslfssz7zbyi73nfxwuq", // Placeholder
    "HTML_Component_Render_Transform": "bafyreigxqsz7ga5t7t6j2kalfourkzkfjlhjdjqd24clizq2krflvpb3sq", // Placeholder
    "MermaidRender_Transform": "bafyreibk73rycfjd7qvccpacsxtxkvpvpsvocyj7jpwoz7rmhb7z3e26nu", // Placeholder
    "StoreToIONPOD_Transform_IONWALL": "bafyreif7yqivqtkjhhwb5xkxqj3j7gyjlrvfkhhvjvbfffj4u7m5kfefbi",
    "IPC_NATS_Publish_Transform": "bafyreihyrz7wgld5qrjmejbdjcbcm3jqrjshxphu6jnlxhnlfbk7d745xy"
  }
}
```

### 3.7. `ecosystem_integration_points_json`
```json
{
  "ionwall_permissions_needed": [
    "read_pod_data:canvas_render_instructions",
    "read_pod_data:canvas_visualization_data",
    "execute_rendering_engine:vegalite",
    "execute_rendering_engine:html_component",
    "execute_rendering_engine:mermaid",
    // "execute_rendering_engine:threejs_scene",
    "write_pod_data:canvas_rendered_output",
    "write_pod_data:canvas_render_agent_log",
    "publish_nats_topic:ionflux_canvas_update_area" // To communicate with Canvas Frontend
  ],
  "ionpod_data_access": {
    "inputs": [
      { "cid_param": "render_instructions_cid", "access_type": "read", "purpose": "To load definitions for rendering (e.g., Vega-Lite spec, component structure)." },
      { "cid_param": "data_cid", "access_type": "read", "purpose": "To load data to be visualized or rendered dynamically." }
    ],
    "outputs": [
      { "cid_name": "rendered_artifact_cid", "access_type": "write", "purpose": "To store the generated visual output (image, HTML bundle, etc.)." },
      { "cid_name": "render_log_cid", "access_type": "write", "purpose": "To store logs of rendering operations." }
    ]
  },
  "tokenomic_triggers": [
    { "event": "canvas_render_successful_interactive_component", "action": "debit_user_compute_credits", "token_id": "C-ION", "amount_formula": "0.005 + (complexity_score_of_instructions * 0.001)" },
    { "event": "canvas_render_successful_static_image", "action": "debit_user_compute_credits", "token_id": "C-ION", "amount_formula": "0.001 + (output_size_kb * 0.0001)"}
  ],
  "techgnosis_integration": {
    "knowledge_graph_queries": [
      "get_visualization_best_practices_for_data_type:{{nodes.fetch_visualization_data_conditional.outputs.visualization_data_obj.schema_type}}", // Suggest chart types
      "get_ui_theme_palette_for_user:{{user_profile_cid}}" // To apply consistent styling
    ],
    "semantic_understanding_of_render_instructions": true, // TechGnosis could parse natural language requests for visualizations (e.g., "show me sales over time as a line chart").
    "accessibility_guideline_check_for_rendered_output": true // e.g. color contrast checks for charts
  },
  "hybrid_layer_escalation_points": [
    { "condition": "rendering_error_persistent_for_valid_spec_and_data", "action": "escalate_to_hybrid_layer_technical_support_for_render_transform_debugging" },
    { "condition": "user_flags_visualization_as_misleading_or_inaccurate", "action": "escalate_to_hybrid_layer_data_analyst_for_review" },
    { "condition": "request_for_highly_complex_realtime_3d_rendering_exceeds_standard_resource_limits", "action": "request_hybrid_layer_approval_for_additional_resources_or_alternative_rendering_strategy"}
  ],
  "carbon_loop_contribution": {
    "type": "efficient_rendering_and_caching",
    "value_formula": "number_of_cached_renders_served + performance_improvement_factor_of_chosen_render_engine * typical_render_complexity_score",
    "description": "Encourages use of efficient rendering transforms. Caching rendered outputs (if data and instructions haven't changed) can also save significant compute. Suggesting simpler, less resource-intensive chart types for basic data representation."
  }
}
```

### 3.8. `prm_details_json`
```json
{
  "default_image_output_format": "svg", // "png"
  "default_interactive_component_framework": "html_custom_elements", // "react_webcomponents"
  "max_input_data_size_mb_for_client_side_rendering": 5, // For interactive charts that load all data
  "preferred_vegalite_version": "5.x",
  "allow_custom_js_in_html_components": false, // Security: if true, needs sandboxing and strict review
  "theme_config_cid_default": "bafk... (CID of a default theme object in IONPOD)",
  "user_customizable_params": [
    "data_cid", "render_instructions_cid", "renderer_type_override",
    "target_canvas_area_id", "output_format_preferences"
  ]
}
```

### 3.9. `input_schema_json`
*(The JSON content of `input_schema` from Section 2 is inserted here)*
```json
{
  "type": "object",
  "properties": {
    "data_cid": { "type": "string", "nullable": true, "description": "CID of the data object in IONPOD to be visualized/rendered. Nullable if instructions are self-contained (e.g. static SVG)." },
    "render_instructions_cid": { "type": "string", "description": "CID of the rendering instructions object in IONPOD (e.g., a Vega-Lite spec, a component definition, a scene graph)." },
    "renderer_type_override": { "type": "string", "nullable": true, "enum": ["vegalite", "html_component", "threejs_scene", "mermaid_diagram"], "description": "Explicitly specify renderer; otherwise inferred from instructions." },
    "target_canvas_area_id": { "type": "string", "description": "Identifier for the area/panel on the IONFLUX Canvas where the output should be displayed." },
    "output_format_preferences": {
      "type": "object",
      "properties": {
        "image_format": { "type": "string", "enum": ["svg", "png", "jpeg"], "default": "svg" },
        "interactive": { "type": "boolean", "default": true }
      },
      "nullable": true
    }
  },
  "required": [ "render_instructions_cid", "target_canvas_area_id" ]
}
```

### 3.10. `output_schema_json`
*(The JSON content of `output_schema` from Section 2 is inserted here)*
```json
{
  "type": "object",
  "properties": {
    "rendered_artifact_cid": { "type": "string", "description": "IPFS CID of the primary rendered output (e.g., image, HTML bundle)." },
    "auxiliary_artifact_cids": { "type": "object", "additionalProperties": { "type": "string" }, "nullable": true, "description": "CIDs of any supporting files, like data files for an interactive HTML component." },
    "render_type_used": { "type": "string", "description": "Actual renderer type used." },
    "status": { "type": "string", "enum": ["success", "failure", "partial_success"] },
    "error_message": { "type": "string", "nullable": true }
  },
  "required": [ "status" ]
}
```

### 3.11. `trigger_config_json`
```json
{
  "manual_trigger_enabled": true,
  "event_driven_triggers": [
    {
      "event_source": "NATS",
      "topic": "ionflux.canvas.render_request",
      "description": "Triggered by other agents or UI bridge components to render content for the Canvas. Payload must match input_schema.",
      "input_mapping_jmespath": "payload"
    }
  ],
  "webhook_triggers": [
     {
      "endpoint_path": "/webhooks/invoke/canvas_render",
      "http_method": "POST",
      "authentication_method": "ionwall_jwt_scoped_for_canvas_render",
      "description": "HTTP endpoint to request rendering. Expects JSON body matching input_schema."
    }
  ]
}
```

### 3.12. `deployment_info_json`
```json
{
  "runtime_environment": "IONFLUX_EdgeNode_Wasm_With_CanvasKit", // May need specific graphics libraries like Skia/CanvasKit if not pure JS renderers
  "current_instances_managed_by_ionflux_controller": true,
  "default_replicas": 2,
  "auto_scaling_policy": {
    "min_replicas": 1,
    "max_replicas": 5,
    "cpu_threshold_percentage": 70,
    "pending_render_queue_length": 10
  }
}
```

### 3.13. `logging_json`
```json
{
  "log_level": "info",
  "log_targets": ["ionpod_event_log_canvas_render", "local_stdout_dev_mode_only"],
  "log_retention_policy_days": 30,
  "sensitive_fields_to_mask_in_log": ["visualization_data_obj_if_contains_pii"]
}
```

### 3.14. `monitoring_json`
```json
{
  "metrics_to_collect": [
    "render_requests_count_by_type", "render_success_rate", "render_failure_rate",
    "avg_render_time_ms_by_type", "output_artifact_size_kb_avg_by_type",
    "nats_event_publication_time_ms_for_canvas_update"
  ],
  "metrics_endpoint_ionwall_protected": "/metrics/canvas_render_agent",
  "health_check_protocol": "check_availability_of_core_rendering_transforms_and_libraries",
  "alerting_rules": [
    {"metric": "render_failure_rate_vegalite", "condition": "value > 0.15 for 10m", "severity": "warning", "notification_channel": "hybrid_layer_ops_team_chat_canvas_channel"},
    {"metric": "avg_render_time_ms_html_component", "condition": "value > 5000 for 5m", "severity": "warning", "notification_channel": "hybrid_layer_ops_team_chat_performance"}
  ]
}
```

### 3.15. `security_json`
```json
{
  "data_encryption_at_rest_ionpod": true,
  "data_encryption_in_transit_ipfs_ionwall": true,
  "html_component_sandboxing_policy": "iframe_with_csp_if_custom_js_allowed_otherwise_ sanitized_html_only", // Critical if allowing custom JS in components
  "svg_sanitization_enabled_for_vegalite_mermaid": true, // Prevent XSS in SVG outputs
  "max_input_data_size_for_rendering_mb": 20,
  "max_render_instruction_size_kb": 512,
  "required_ionwall_consent_scopes_for_canvas_render_itself": [
    "read_pod_data:canvas_render_instructions", "read_pod_data:canvas_visualization_data",
    "execute_rendering_engine:*", // Or list each e.g. execute_rendering_engine:vegalite
    "write_pod_data:canvas_rendered_output", "write_pod_data:canvas_render_agent_log",
    "publish_nats_topic:ionflux_canvas_update_area"
  ],
  "sensitive_data_handling_in_visualizations_policy_id": "SDP-CANVAS-001" // e.g. rules about not rendering raw PII unless explicitly approved for that context
}
```

---
## 4. User Experience Flow (Conceptual)

1.  **Initiation:** An `Analytics Agent` processes some data and determines a bar chart is needed to display results for the user on their main IONFLUX Canvas dashboard.
    *   It prepares the data (e.g., aggregated results) and stores it in IONPOD, getting `data_cid_analytics_results`.
    *   It prepares a Vega-Lite specification for a bar chart, tailored to this data, and stores it, getting `render_instructions_cid_barchart_spec`.
    *   It then triggers `Canvas Render Agent` via NATS: `{ data_cid: "data_cid_analytics_results", render_instructions_cid: "render_instructions_cid_barchart_spec", target_canvas_area_id: "user_dashboard_panel_3" }`.
2.  **IONWALL Checkpoint (Data Access & Rendering):**
    *   IONWALL prompts User: *"Canvas Render Agent, on behalf of Analytics Agent, wants to:
        *   Read 'Analytics Results Data' from your IONPOD.
        *   Read 'Bar Chart Rendering Spec' from your IONPOD.
        *   Render a Vega-Lite visualization.
        *   Store the rendered chart image to your IONPOD.
        Allow?"*
3.  **Execution:**
    *   `Canvas Render Agent` fetches the data and Vega-Lite spec.
    *   It determines `VegaLite_Render_Transform` is appropriate.
    *   `VegaLite_Render_Transform` processes the spec and data, generating an SVG image blob.
    *   `StoreToIONPOD_Transform_IONWALL` saves the SVG, getting `rendered_artifact_cid_barchart_svg`.
4.  **Canvas Update:**
    *   `Canvas Render Agent` publishes a NATS event to `ionflux.canvas.update_area`: `{ target_canvas_area_id: "user_dashboard_panel_3", rendered_artifact_cid: "rendered_artifact_cid_barchart_svg", renderer_type_used: "vegalite" }`.
5.  **Display:** The IONFLUX Canvas Frontend (listening on that NATS topic) receives the event. It fetches the SVG from `rendered_artifact_cid_barchart_svg` via IPFS/IONPOD and displays it in the specified panel on the user's dashboard.
6.  **Logging:** `Canvas Render Agent` logs its operation details to IONPOD.

---
## 5. TechGnosis & Hybrid Layer Integration Notes

*   **TechGnosis:**
    *   **Visualization Recommendation:** Based on the schema or characteristics of `data_cid`, TechGnosis could suggest appropriate chart types or rendering instructions if not fully specified by the requesting agent. E.g., "This data looks like a time series, a line chart might be effective."
    *   **Aesthetic Principles & Theming:** TechGnosis can provide access to user's (or sNetwork's) preferred themes, color palettes, and typographic styles. `Canvas Render Agent` (or its transforms) can query these to ensure visual consistency.
    *   **Accessibility Analysis:** TechGnosis could analyze rendering instructions (e.g., Vega-Lite specs) or even rendered outputs (e.g., SVGs) to check for compliance with accessibility standards (e.g., color contrast, ARIA tagging for HTML components).
*   **Hybrid Layer:**
    *   **Review of Complex/Misleading Visualizations:** If a user or another agent flags a generated visualization as potentially misleading, inaccurate, or overly complex for its purpose, it can be escalated to a data analyst or UI/UX expert via the Hybrid Layer for review.
    *   **Resource Intensive Renders:** Requests for extremely complex renderings (e.g., high-poly 3D scenes with real-time ray tracing) that might exceed normal resource allocations could require Hybrid Layer approval for scheduling and resource assignment.
    *   **Content Policy for Rendered Output:** If rendering instructions or data could lead to outputs that violate content policies (e.g., generating inappropriate images from text prompts if an "ImageGen_Render_Transform" were used), these could be flagged for Hybrid Layer review before display.

---
## 6. Carbon Loop Integration Notes

*   **Efficient Rendering Choices:**
    *   If multiple rendering transforms can achieve a similar visual output, `Canvas Render Agent` (perhaps guided by TechGnosis) could prefer the one known to be more computationally efficient or that produces smaller output artifacts.
    *   For static charts, preferring SVG (vector, often smaller) over PNG (raster) unless PNG is specifically requested or necessary for complexity.
*   **Caching Rendered Artifacts:** If the input `data_cid` and `render_instructions_cid` have not changed, a previously rendered artifact can be reused instead of re-rendering, saving compute. This requires a caching mechanism (perhaps at the IONPOD storage layer or managed by Canvas Render Agent).
*   **Level of Detail (LOD) for Complex Scenes:** For 3D scenes or highly detailed interactive visualizations, implementing LOD techniques where simpler representations are used when the canvas area is small or not in focus, reducing continuous rendering load.

---
## 7. Dependencies & Interactions

*   **Required Transforms:**
    *   `FetchFromIONPOD_Transform_IONWALL`
    *   `DetermineRenderType_Transform` (hypothetical, for routing)
    *   `SwitchCaseRouter_Transform`
    *   Specific rendering transforms: `VegaLite_Render_Transform`, `HTML_Component_Render_Transform`, `MermaidRender_Transform`. Potentially others like `D3_Render_Transform`, `ThreeJS_Scene_Render_Transform`, `SVG_Optimize_Transform`.
    *   `StoreToIONPOD_Transform_IONWALL`
    *   `IPC_NATS_Publish_Transform` (for communicating with the Canvas Frontend)
*   **Interacting Agents (Conceptual):**
    *   Triggered by any agent that needs to present visual information to the user (e.g., `Analytics Agent`, `DataQueryAgent`, `Muse Prompt Chain Agent` showing generated content, `Scribe Code Gen Agent` showing code structure with Mermaid).
    *   Its output events are consumed by the `IONFLUX Canvas Frontend` (which is not an agent, but a user-facing application component).
    *   Might interact with `TechGnosis Agent` for visualization recommendations or theme information.
*   **External Systems (Indirectly via Rendering Libraries):**
    *   The rendering transforms might internally use JavaScript libraries like Vega-Lite, D3.js, Three.js, Mermaid.js, etc., executed within a Wasm-sandboxed browser context or a server-side JS environment.

---
## 8. Open Questions & Future Considerations

*   **Range of Rendering Libraries/Engines:** Which specific rendering libraries should be supported out-of-the-box? How are new ones added (new transforms)?
*   **Interactive Visualizations:** For interactive charts/components (e.g., D3, React components), how are user interactions within the rendered component handled? Do they emit events back into IONFLUX that can trigger other agents? This implies a two-way communication with the Canvas.
*   **Real-time Data Streaming to Canvas:** Support for visualizations that update in real-time as underlying data changes (e.g., live dashboards). This would require a different trigger/data flow model.
*   **Accessibility (a11y):** Ensuring that generated visualizations meet accessibility standards (WCAG). This might involve specific configurations for rendering transforms or post-processing checks.
*   **Collaborative Canvas Editing:** Scenarios where multiple users might be interacting with or contributing to the same canvas area.
*   **Security of HTML/JS Components:** If rendering arbitrary HTML/JS components, ensuring robust sandboxing (e.g., CSP, iframes) to prevent XSS or other attacks on the Canvas.
*   **Performance of Complex Renders:** Optimizing rendering of large datasets or complex 3D scenes. Offloading rendering to client-side GPU where possible vs. server-side rendering.
*   **Standard for Rendering Instructions:** Defining a flexible yet standardized schema for `render_instructions_cid` objects that can accommodate various renderer types.
