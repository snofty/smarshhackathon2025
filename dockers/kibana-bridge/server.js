/**
 * MCP-to-HTTP Bridge Server
 * Exposes MCP stdio server over HTTP for n8n integration
 */

import express from 'express';
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';

const app = express();

// Enable CORS for n8n
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

app.use(express.json());

let mcpClient = null;

// Initialize MCP client connection
async function initializeMCP() {
  try {
    console.log('Starting GitHub MCP Server...');
    
    // Get the actual container name dynamically
    const projectName = process.env.COMPOSE_PROJECT_NAME || 'multi-mcp';
    const serviceName = process.env.MCP_CONTAINER_NAME || 'kibana-mcp';
    const serverCommand = process.env.MCP_SERVER_COMMAND || '/usr/local/bin/mcp-server-kibana';
    const containerName = `${projectName}-${serviceName}-1`;
    
    console.log(`Connecting to container: ${containerName}`);
    console.log(`Using MCP server command: ${serverCommand}`);
    
    const transport = new StdioClientTransport({
      command: 'docker',
      args: ['exec', '-i', containerName, serverCommand],
      env: process.env
    });

    mcpClient = new Client({
      name: 'mcp-http-bridge',
      version: '1.0.0'
    }, {
      capabilities: {}
    });

    await mcpClient.connect(transport);
    console.log('MCP client connected successfully');

  } catch (error) {
    console.error('Failed to initialize MCP:', error);
    throw error;
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    mcpConnected: mcpClient !== null,
    timestamp: new Date().toISOString()
  });
});

// List available tools
app.get('/tools', async (req, res) => {
  try {
    if (!mcpClient) {
      return res.status(503).json({ error: 'MCP client not connected' });
    }

    const tools = await mcpClient.listTools();
    res.json(tools);
  } catch (error) {
    console.error('Error listing tools:', error);
    res.status(500).json({ error: error.message });
  }
});

// Call a tool
app.post('/tools/:toolName', async (req, res) => {
  try {
    if (!mcpClient) {
      return res.status(503).json({ error: 'MCP client not connected' });
    }

    const { toolName } = req.params;
    const { arguments: args } = req.body;

    console.log(`Calling tool: ${toolName} with args:`, args);

    const result = await mcpClient.callTool({
      name: toolName,
      arguments: args || {}
    });

    res.json(result);
  } catch (error) {
    console.error('Error calling tool:', error);
    res.status(500).json({ error: error.message });
  }
});

// List available resources
app.get('/resources', async (req, res) => {
  try {
    if (!mcpClient) {
      return res.status(503).json({ error: 'MCP client not connected' });
    }

    const resources = await mcpClient.listResources();
    res.json(resources);
  } catch (error) {
    console.error('Error listing resources:', error);
    res.status(500).json({ error: error.message });
  }
});

// MCP HTTP Streamable endpoint for n8n
// This endpoint handles MCP protocol messages over HTTP with streaming support
app.post('/message', async (req, res) => {
  try {
    console.log('=== Incoming MCP Request ===');
    console.log('Headers:', JSON.stringify(req.headers, null, 2));
    console.log('Body:', JSON.stringify(req.body, null, 2));
    
    if (!mcpClient) {
      console.error('MCP client not connected!');
      return res.status(503).json({ 
        jsonrpc: '2.0',
        error: { code: -32000, message: 'MCP client not connected' },
        id: req.body.id 
      });
    }

    const { jsonrpc, method, params, id } = req.body;

    console.log(`MCP Request: ${method}`, params);

    let result;
    switch (method) {
      case 'initialize':
        result = {
          protocolVersion: '2024-11-05',
          capabilities: {
            tools: {},
            resources: {}
          },
          serverInfo: {
            name: 'github-mcp-bridge',
            version: '1.0.0'
          }
        };
        break;
      
      case 'tools/list':
        result = await mcpClient.listTools();
        
        // Fix schema issues for n8n compatibility
        if (result && result.tools) {
          result.tools = result.tools.map(tool => {
            const fixedTool = JSON.parse(JSON.stringify(tool)); // Deep clone
            
            // Fix empty body schema in execute_kb_api
            if (tool.name === 'execute_kb_api' && tool.inputSchema?.properties?.body) {
              if (!tool.inputSchema.properties.body.type) {
                fixedTool.inputSchema.properties.body = {
                  type: 'object',
                  description: 'Request body (JSON object)',
                  additionalProperties: true
                };
              }
            }
            
            // Fix params schema with array type in execute_kb_api
            if (tool.name === 'execute_kb_api' && tool.inputSchema?.properties?.params) {
              const paramsSchema = tool.inputSchema.properties.params;
              if (paramsSchema.additionalProperties && Array.isArray(paramsSchema.additionalProperties.type)) {
                fixedTool.inputSchema.properties.params = {
                  type: 'object',
                  description: 'Query parameters',
                  additionalProperties: true
                };
              }
            }
            
            // Fix any other properties with empty or problematic schemas
            if (fixedTool.inputSchema?.properties) {
              Object.keys(fixedTool.inputSchema.properties).forEach(propName => {
                const prop = fixedTool.inputSchema.properties[propName];
                
                // Fix empty objects
                if (prop && typeof prop === 'object' && Object.keys(prop).length === 0) {
                  fixedTool.inputSchema.properties[propName] = {
                    type: 'string',
                    description: `${propName} parameter`
                  };
                }
                
                // Fix anyOf schemas (n8n doesn't support anyOf well)
                if (prop?.anyOf) {
                  // Check if it's string or array
                  const hasString = prop.anyOf.some(t => t.type === 'string');
                  const hasArray = prop.anyOf.some(t => t.type === 'array');
                  
                  if (hasString && hasArray) {
                    // Accept both string and array - use string for simplicity
                    fixedTool.inputSchema.properties[propName] = {
                      type: 'string',
                      description: prop.description || `${propName} parameter (accepts string or array)`
                    };
                  } else if (hasArray) {
                    const arraySchema = prop.anyOf.find(t => t.type === 'array');
                    fixedTool.inputSchema.properties[propName] = {
                      type: 'array',
                      items: arraySchema.items || { type: 'string' },
                      description: prop.description || `${propName} parameter`
                    };
                  } else {
                    // Default to string
                    fixedTool.inputSchema.properties[propName] = {
                      type: 'string',
                      description: prop.description || `${propName} parameter`
                    };
                  }
                }
                
                // Fix array types in additionalProperties
                if (prop?.additionalProperties?.type && Array.isArray(prop.additionalProperties.type)) {
                  fixedTool.inputSchema.properties[propName] = {
                    type: 'object',
                    description: prop.description || `${propName} parameter`,
                    additionalProperties: true
                  };
                }
                
                // Fix empty additionalProperties: {}
                if (prop?.additionalProperties && typeof prop.additionalProperties === 'object' && 
                    Object.keys(prop.additionalProperties).length === 0) {
                  fixedTool.inputSchema.properties[propName] = {
                    ...prop,
                    additionalProperties: true
                  };
                }
                
                // Fix properties without type but with description only
                if (prop && !prop.type && !prop.anyOf && !prop.enum && prop.description) {
                  fixedTool.inputSchema.properties[propName] = {
                    type: 'object',
                    description: prop.description,
                    additionalProperties: true
                  };
                }
              });
            }
            
            return fixedTool;
          });
        }
        break;
      
      case 'tools/call':
        result = await mcpClient.callTool(params);
        break;
      
      case 'resources/list':
        result = await mcpClient.listResources();
        break;
      
      case 'resources/read':
        result = await mcpClient.readResource(params);
        break;
      
      case 'ping':
        result = {};
        break;
      
      default:
        console.warn(`Unknown method: ${method}`);
        return res.json({
          jsonrpc: '2.0',
          error: { code: -32601, message: `Method not found: ${method}` },
          id
        });
    }

    res.json({
      jsonrpc: '2.0',
      result,
      id
    });
  } catch (error) {
    console.error('MCP protocol error:', error);
    res.json({
      jsonrpc: '2.0',
      error: { code: -32000, message: error.message, data: error.stack },
      id: req.body.id
    });
  }
});

// SSE endpoint for streaming (if needed)
app.get('/sse', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('Access-Control-Allow-Origin', '*');
  
  // Send initial connection event
  res.write('event: connected\n');
  res.write('data: {"status":"connected"}\n\n');
  
  // Keep connection alive
  const keepAlive = setInterval(() => {
    res.write(':keepalive\n\n');
  }, 30000);
  
  req.on('close', () => {
    clearInterval(keepAlive);
  });
});

// Read a resource
app.get('/resources/:uri', async (req, res) => {
  try {
    if (!mcpClient) {
      return res.status(503).json({ error: 'MCP client not connected' });
    }

    const { uri } = req.params;
    const resource = await mcpClient.readResource({ uri });
    res.json(resource);
  } catch (error) {
    console.error('Error reading resource:', error);
    res.status(500).json({ error: error.message });
  }
});

// Catch-all for debugging
app.all('*', (req, res, next) => {
  if (req.path === '/health' || req.path === '/tools' || req.path === '/message' || 
      req.path === '/sse' || req.path.startsWith('/resources') || req.path.startsWith('/tools/')) {
    return next();
  }
  console.log('=== Unknown endpoint accessed ===');
  console.log('Method:', req.method);
  console.log('Path:', req.path);
  console.log('Headers:', JSON.stringify(req.headers, null, 2));
  console.log('Body:', JSON.stringify(req.body, null, 2));
  res.status(404).json({ error: 'Endpoint not found', path: req.path });
});

// Start server
const PORT = process.env.PORT || 3000;

async function start() {
  try {
    await initializeMCP();
    
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`MCP HTTP Bridge listening on http://0.0.0.0:${PORT}`);
      console.log(`Available endpoints:`);
      console.log(`  GET  /health           - Health check`);
      console.log(`  GET  /tools            - List available tools`);
      console.log(`  POST /tools/:toolName  - Call a tool`);
      console.log(`  GET  /resources        - List available resources`);
      console.log(`  GET  /resources/:uri   - Read a resource`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Handle shutdown
process.on('SIGTERM', () => {
  console.log('Shutting down...');
  if (mcpClient) {
    mcpClient.close();
  }
  process.exit(0);
});

start();
