#!/bin/sh
mkdir -p /app/models
ln -s "/app/default_models/llama-2-7b-chat.Q4_0.gguf" "/app/models/llama-2-7b-chat.Q4_0.gguf"
ls /app/models

echo "Soft links created successfully!"

# Print build date
BUILD_DATE=$(cat /build_date.txt)
echo "=== Image build date: $BUILD_DATE ===" 

exec "$@"
