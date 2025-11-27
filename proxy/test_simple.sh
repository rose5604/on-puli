#!/bin/bash

echo "=== Simple Token Limit Test ==="
echo ""

# Test 1: Health check
echo "1. Health Check:"
curl -s http://localhost:14441/health | python3 -m json.tool
echo ""
echo ""

# Test 2: Simple request
echo "2. Generate Request (default):"
curl -s -X POST http://localhost:14441/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model":"llama3.3:70b-instruct-q4_K_M","prompt":"Hello"}' \
  | python3 -m json.tool | grep -E '"eval_count"|"response"' | head -5
echo ""
echo ""

# Test 3: Request with high max_tokens
echo "3. Generate Request (max_tokens=2000, should cap to 50):"
curl -s -X POST http://localhost:14441/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model":"llama3.3:70b-instruct-q4_K_M","prompt":"Write essay","options":{"max_tokens":2000}}' \
  | python3 -m json.tool | grep -E '"eval_count"|"response"' | head -5
echo ""
echo ""

# Test 4: Chat request
echo "4. Chat Request:"
curl -s -X POST http://localhost:14441/api/chat \
  -H "Content-Type: application/json" \
  -d '{"model":"llama3.3:70b-instruct-q4_K_M","messages":[{"role":"user","content":"Hi"}]}' \
  | python3 -m json.tool | grep -E '"eval_count"|"content"' | head -5
echo ""

echo "=== Check proxy logs for [TOKEN DEBUG] messages ==="
