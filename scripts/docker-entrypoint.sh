#!/bin/sh

src_dir="default_models"
dest_dir="models"

src_gptq="default_models/Llama-2-7B-Chat-GPTQ"
temp_gptq="default_models/temp_Llama-2-7B-Chat-GPTQ"
dest_gptq="default_models/Llama-2-7b-Chat-GPTQ"

# Rename the directory
if [ -d "$src_gptq" ]; then
    mv "$src_gptq" "$temp_gptq"
    mv "$temp_gptq" "$dest_gptq"
else
    echo "Directory $src_gptq does not exist!"
fi

# Ensure the destination directory exists
mkdir -p "$dest_dir"

# Recursively create symlinks for files and directories from default_models to models
find "$src_dir" -mindepth 1 -type f -o -type d | while read -r item; do
    # Create the relative path
    rel_path="${item#$src_dir/}"
    dest_path="$dest_dir/$rel_path"
    
    # Ensure the parent directory of the destination path exists
    mkdir -p "$(dirname "$dest_path")"
    
    # Create the symlink in the destination directory
    ln -s "$PWD/$item" "$dest_path"
done




echo "Soft links created successfully!"

# Print build date
BUILD_DATE=$(cat /build_date.txt)
echo "=== Image build date: $BUILD_DATE ===" 

exec "$@"
