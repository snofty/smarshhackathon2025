# MCP HTTP Bridge

Exposes the GitHub MCP Server over HTTP for integration with n8n and other HTTP-based tools.

## n8n MCP Client Configuration

For n8n's MCP client node with **HTTP Streamable** transport:

- **URL**: `http://localhost:3000/message`
- **Transport**: HTTP Streamable

The bridge will handle MCP protocol messages (initialize, tools/list, tools/call, etc.)

## Endpoints

### Health Check
```bash
GET http://localhost:3000/health
```

### List Tools
```bash
GET http://localhost:3000/tools
```

### Call a Tool
```bash
POST http://localhost:3000/tools/:toolName
Content-Type: application/json

{
  "arguments": {
    "param1": "value1",
    "param2": "value2"
  }
}
```

### List Resources
```bash
GET http://localhost:3000/resources
```

### Read a Resource
```bash
GET http://localhost:3000/resources/:uri
```

## Example: Search Code

```bash
curl -X POST http://localhost:3000/tools/search_code \
  -H "Content-Type: application/json" \
  -d '{
    "arguments": {
      "query": "function",
      "path": "src/"
    }
  }'
```

## Example: Read File

```bash
curl -X POST http://localhost:3000/tools/get_file_contents \
  -H "Content-Type: application/json" \
  -d '{
    "arguments": {
      "owner": "your-username",
      "repo": "your-repo",
      "path": "README.md"
    }
  }'
```

## n8n Integration

1. Add an **HTTP Request** node
2. Configure:
   - **Method**: POST
   - **URL**: `http://localhost:3000/tools/search_code`
   - **Body Content Type**: JSON
   - **Body**:
     ```json
     {
       "arguments": {
         "query": "{{ $json.searchTerm }}",
         "path": "src/"
       }
     }
     ```

## Available GitHub MCP Tools

Common tools include:
- `search_code` - Search for code in repositories
- `get_file_contents` - Read file contents
- `list_commits` - List commits
- `create_issue` - Create a GitHub issue
- `create_pull_request` - Create a pull request
- `list_issues` - List issues
- `get_issue` - Get issue details

Run `GET /tools` to see the complete list with descriptions and parameters.
