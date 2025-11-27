#!/bin/bash

# Script Testing Token Limit untuk VPS Ubuntu
# Pastikan proxy sudah running di localhost:14441

echo "🧪 Testing Token Limit Effectiveness"
echo "===================================="
echo ""

# Warna output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test 1: Cek health endpoint
echo -e "${CYAN}📊 Test 1: Health Check${NC}"
echo "Command: curl -s http://localhost:14441/health"
echo ""

HEALTH=$(curl -s http://localhost:14441/health)
MAX_TOKENS=$(echo "$HEALTH" | grep -o '"max_tokens_per_request":[0-9]*' | cut -d':' -f2)

if [ -z "$MAX_TOKENS" ]; then
    echo -e "${RED}✗ Error: Tidak dapat membaca max_tokens_per_request${NC}"
    echo -e "${YELLOW}  Pastikan proxy sudah running!${NC}"
    exit 1
fi

echo -e "Response:"
echo "$HEALTH" | python3 -m json.tool 2>/dev/null || echo "$HEALTH"
echo ""
echo -e "${GREEN}✓ Max tokens per request: ${MAX_TOKENS}${NC}"
echo ""

# Test 2: Request normal (default)
echo -e "${CYAN}📊 Test 2: Request dengan default settings${NC}"
echo "Command: curl -X POST http://localhost:14441/api/generate -d '{...}'"
echo ""

RESPONSE1=$(curl -s -X POST http://localhost:14441/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model":"llama3.3:70b-instruct-q4_K_M","prompt":"Explain machine learning in simple terms"}')

TOKENS1=$(echo "$RESPONSE1" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('eval_count', 0))" 2>/dev/null || echo "0")
RESPONSE_LENGTH1=$(echo "$RESPONSE1" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data.get('response', '')))" 2>/dev/null || echo "0")

echo -e "Result:"
echo -e "  Tokens generated: ${GREEN}${TOKENS1}${NC}"
echo -e "  Response length: ${RESPONSE_LENGTH1} chars"

if [ "$TOKENS1" -le "$MAX_TOKENS" ]; then
    echo -e "  ${GREEN}✓ Within limit (${TOKENS1} <= ${MAX_TOKENS})${NC}"
else
    echo -e "  ${RED}✗ Exceeded limit (${TOKENS1} > ${MAX_TOKENS})${NC}"
fi
echo ""

# Test 3: Request dengan max_tokens tinggi (should be capped)
echo -e "${CYAN}📊 Test 3: Request dengan max_tokens=2000 (should be capped to ${MAX_TOKENS})${NC}"
echo "Command: curl -X POST http://localhost:14441/api/generate -d '{...\"max_tokens\":2000}'"
echo ""

RESPONSE2=$(curl -s -X POST http://localhost:14441/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model":"llama3.3:70b-instruct-q4_K_M","prompt":"Write a comprehensive guide about artificial intelligence","options":{"max_tokens":2000}}')

TOKENS2=$(echo "$RESPONSE2" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('eval_count', 0))" 2>/dev/null || echo "0")
RESPONSE_LENGTH2=$(echo "$RESPONSE2" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data.get('response', '')))" 2>/dev/null || echo "0")

echo -e "Result:"
echo -e "  Request: max_tokens=2000"
echo -e "  Tokens generated: ${GREEN}${TOKENS2}${NC}"
echo -e "  Response length: ${RESPONSE_LENGTH2} chars"

if [ "$TOKENS2" -le "$MAX_TOKENS" ]; then
    echo -e "  ${GREEN}✓ Correctly capped (${TOKENS2} <= ${MAX_TOKENS})${NC}"
else
    echo -e "  ${RED}✗ NOT capped (${TOKENS2} > ${MAX_TOKENS})${NC}"
fi
echo ""

# Test 4: Chat endpoint
echo -e "${CYAN}📊 Test 4: Chat endpoint test${NC}"
echo "Command: curl -X POST http://localhost:14441/api/chat -d '{...}'"
echo ""

RESPONSE3=$(curl -s -X POST http://localhost:14441/api/chat \
  -H "Content-Type: application/json" \
  -d '{"model":"llama3.3:70b-instruct-q4_K_M","messages":[{"role":"user","content":"What is deep learning?"}]}')

TOKENS3=$(echo "$RESPONSE3" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('eval_count', 0))" 2>/dev/null || echo "0")

echo -e "Result:"
echo -e "  Tokens generated: ${GREEN}${TOKENS3}${NC}"

if [ "$TOKENS3" -le "$MAX_TOKENS" ]; then
    echo -e "  ${GREEN}✓ Within limit (${TOKENS3} <= ${MAX_TOKENS})${NC}"
else
    echo -e "  ${RED}✗ Exceeded limit (${TOKENS3} > ${MAX_TOKENS})${NC}"
fi
echo ""

# Final Validation
echo -e "${CYAN}═══════════════════════════════════${NC}"
echo -e "${CYAN}📋 FINAL VALIDATION${NC}"
echo -e "${CYAN}═══════════════════════════════════${NC}"
echo ""

PASS_COUNT=0
TOTAL_TESTS=3

# Validasi dengan handling string kosong
if [ -n "$TOKENS1" ] && [ "$TOKENS1" != "0" ] && [ "$TOKENS1" -le "$MAX_TOKENS" ] 2>/dev/null; then
    PASS_COUNT=$((PASS_COUNT + 1))
fi

if [ -n "$TOKENS2" ] && [ "$TOKENS2" != "0" ] && [ "$TOKENS2" -le "$MAX_TOKENS" ] 2>/dev/null; then
    PASS_COUNT=$((PASS_COUNT + 1))
fi

if [ -n "$TOKENS3" ] && [ "$TOKENS3" != "0" ] && [ "$TOKENS3" -le "$MAX_TOKENS" ] 2>/dev/null; then
    PASS_COUNT=$((PASS_COUNT + 1))
fi

echo -e "Tests passed: ${PASS_COUNT}/${TOTAL_TESTS}"
echo -e "Max tokens limit: ${MAX_TOKENS}"
echo ""

if [ "$PASS_COUNT" -eq "$TOTAL_TESTS" ]; then
    echo -e "${GREEN}✓✓✓ Token limit AKTIF dan EFEKTIF!${NC}"
    echo -e "${GREEN}✓✓✓ Semua response dibatasi <= ${MAX_TOKENS} tokens${NC}"
    echo -e "${GREEN}✓✓✓ Budget saving mechanism berjalan dengan baik!${NC}"
    echo ""
    echo -e "${YELLOW}💰 Estimasi penghematan: 40-60% dari budget${NC}"
else
    echo -e "${RED}✗✗✗ Token limit TIDAK bekerja dengan baik${NC}"
    echo -e "${RED}✗✗✗ Ada response yang melebihi limit${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Troubleshooting:${NC}"
    echo -e "   1. Pastikan MAX_TOKENS_PER_REQUEST diset di .env"
    echo -e "   2. Restart proxy setelah mengubah .env"
    echo -e "   3. Cek logs proxy untuk error"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════${NC}"
