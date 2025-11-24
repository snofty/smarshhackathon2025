# Adding Code Context to n8n Workflow

## Why Add Code Context?

With code context, the AI can:
- ✅ Identify exact code locations causing issues
- ✅ Reference specific methods and classes
- ✅ Suggest precise code fixes
- ✅ Detect problematic code patterns
- ✅ Review configuration issues

## Implementation

### Add "Load Code Context" Node

Insert between "Parse Alert Details" and "Route by Severity":

```javascript
const fs = require('fs');
const path = require('path');

const errorType = $input.item.json.errorType;
const basePath = '/Users/sunil.kunda/ApplicationCode/POC/hackathon-2025/sample-app';

let files = [];

// Map error types to relevant files
if (errorType.includes('Database')) {
  files = [
    'src/main/java/com/example/orderservice/service/OrderService.java',
    'src/main/java/com/example/orderservice/repository/OrderRepository.java',
    'src/main/resources/application.yml'
  ];
} else if (errorType.includes('Payment')) {
  files = [
    'src/main/java/com/example/orderservice/service/PaymentService.java',
    'src/main/java/com/example/orderservice/controller/PaymentController.java'
  ];
}

let codeContext = '**Relevant Code:**\n\n';

for (const file of files) {
  try {
    const filePath = path.join(basePath, file);
    if (fs.existsSync(filePath)) {
      const content = fs.readFileSync(filePath, 'utf8');
      const lines = content.split('\n').slice(0, 80); // First 80 lines
      codeContext += `### ${path.basename(file)}\n\`\`\`java\n${lines.join('\n')}\n\`\`\`\n\n`;
    }
  } catch (error) {
    console.log(`Error reading ${file}`);
  }
}

return {
  json: {
    ...($input.item.json),
    codeContext: codeContext
  }
};
```

### Update AI Prompt

Add code context to the prompt:

```
{{ $json.originalText }}

**Context:**
- Service: {{ $json.service }}
- Severity: {{ $json.severity }}

{{ $json.codeContext }}

Based on the alert AND the code above, provide:
1. Root cause with specific code references
2. Exact code fixes needed
3. Configuration changes required
```

## Example Output

### Without Code:
```
Root Cause: Database timeout
Fix: Increase connection pool size
```

### With Code:
```
Root Cause: OrderService.java line 89 - simulateProductionFailures() 
sleeps for 35s, exceeding 30s timeout

Fix: Remove simulation code:
// DELETE lines 89-95 in OrderService.java

Config: Increase pool size in application.yml:
maximum-pool-size: 20  # was 10
```

## Token Cost

- Without code: ~500 tokens ($0.0005)
- With code: ~3000 tokens ($0.003)

Worth it for precise analysis!

## Files to Include by Error Type

| Error | Files |
|-------|-------|
| Database | OrderService.java, OrderRepository.java, application.yml |
| Payment | PaymentService.java, PaymentController.java |
| Inventory | InventoryService.java, OrderService.java |
| Memory | MetricsService.java, application.yml |
