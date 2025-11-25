#!/usr/bin/env node

/**
 * Convert kibana-sample-logs.json to Elasticsearch bulk import format (NDJSON)
 * 
 * Usage: node convert-to-bulk.js
 * Output: kibana-bulk-import.ndjson
 */

const fs = require('fs');
const path = require('path');

const INPUT_FILE = 'kibana-sample-logs.json';
const OUTPUT_FILE = 'kibana-bulk-import.ndjson';
const INDEX_NAME = 'order-service-logs';

function convertToBulk() {
  console.log('Converting logs to Elasticsearch bulk format...');
  
  // Read input file
  const inputPath = path.join(__dirname, INPUT_FILE);
  const logs = JSON.parse(fs.readFileSync(inputPath, 'utf8'));
  
  console.log(`Found ${logs.length} log entries`);
  
  // Convert to bulk format
  const bulkData = [];
  
  logs.forEach((log, index) => {
    // Add index action
    bulkData.push(JSON.stringify({
      index: {
        _index: INDEX_NAME,
        _id: `log-${index + 1}`
      }
    }));
    
    // Add document
    bulkData.push(JSON.stringify(log));
  });
  
  // Write output file
  const outputPath = path.join(__dirname, OUTPUT_FILE);
  fs.writeFileSync(outputPath, bulkData.join('\n') + '\n', 'utf8');
  
  console.log(`✅ Created ${OUTPUT_FILE}`);
  console.log(`   - ${logs.length} documents`);
  console.log(`   - Index: ${INDEX_NAME}`);
  console.log(`   - Size: ${(fs.statSync(outputPath).size / 1024).toFixed(2)} KB`);
  console.log('');
  console.log('Next steps:');
  console.log('1. Import to Elasticsearch:');
  console.log(`   curl -X POST "YOUR_KIBANA_URL:9200/_bulk" \\`);
  console.log(`     -H "Content-Type: application/x-ndjson" \\`);
  console.log(`     -H "Authorization: ApiKey YOUR_API_KEY" \\`);
  console.log(`     --data-binary @${OUTPUT_FILE}`);
  console.log('');
  console.log('2. Verify import:');
  console.log(`   curl -X GET "YOUR_KIBANA_URL:9200/${INDEX_NAME}/_count" \\`);
  console.log(`     -H "Authorization: ApiKey YOUR_API_KEY"`);
}

// Run conversion
try {
  convertToBulk();
} catch (error) {
  console.error('❌ Error:', error.message);
  process.exit(1);
}
