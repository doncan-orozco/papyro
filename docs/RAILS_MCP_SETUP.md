# Rails MCP Server Setup for Papyro

## Installation

Rails MCP Server is installed and configured for the papyro project.

## Configuration

The server is configured to run in single-project mode pointing to:
```
/Users/doncan/Documents/papyro
```

## For GitHub Copilot Agent

Add this to your VS Code MCP settings or GitHub Copilot configuration:

```json
{
  "mcpServers": {
    "railsMcpServer": {
      "command": "/Users/doncan/.rbenv/shims/ruby",
      "args": [
        "/Users/doncan/.rbenv/shims/rails-mcp-server",
        "--single-project"
      ],
      "env": {
        "RAILS_MCP_PROJECT_PATH": "/Users/doncan/Documents/papyro"
      }
    }
  }
}
```

## Available Tools

The MCP server provides:
- `switch_project` - Change active Rails project (not needed in single-project mode)
- `search_tools` - Discover available tools
- `execute_tool` - Run internal analyzers
- `execute_ruby` - Execute sandboxed Ruby code

### Internal Analyzers
- `project_info` - Project structure and Rails version
- `list_files` - List files matching pattern
- `get_file` - Retrieve file content
- `get_routes` - Rails routes with filtering
- `analyze_models` - Models with associations/validations
- `get_schema` - Database schema
- `analyze_controller_views` - Controller-view relationships
- `analyze_environment_config` - Environment configs
- `load_guide` - Rails/Turbo/Stimulus/Kamal docs

## Usage Examples

```ruby
# Get routes
execute_tool(tool_name: "get_routes")

# Analyze a specific model
execute_tool(tool_name: "analyze_models", params: { model_name: "Player" })

# Get schema for a table
execute_tool(tool_name: "get_schema", params: { table_name: "players" })

# Execute Ruby code
execute_ruby(code: "puts read_file('Gemfile')")
```

## Resources

- [Rails MCP Server Documentation](https://maquina.app/documentation/ai-tools/rails-mcp-server/)
- [GitHub Repository](https://github.com/maquina-app/rails-mcp-server)
- [Copilot Agent Setup](https://github.com/maquina-app/rails-mcp-server/blob/main/docs/COPILOT_AGENT.md)
