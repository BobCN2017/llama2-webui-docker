#!/bin/sh

src_dir="default_models"
dest_dir="models"

# Ensure the destination directory exists
mkdir -p "$dest_dir"

# Use rsync to create the directory structure without copying files
rsync -a --include '*/' --exclude '*' "$src_dir/" "$dest_dir/"

# Use find to list all items in the source directory
find "$src_dir" -type f -o -type d | while read -r item; do
    # Create the relative path
    rel_path="${item#$src_dir/}"
    # Create the symlink in the destination directory
    ln -s "$PWD/$item" "$dest_dir/$rel_path"
done


dir_to_check="models/default_models"

if [ -d "$dir_to_check" ]; then
    rm -rf "$dir_to_check"
    echo "Directory $dir_to_check has been removed."
else
    echo "Directory $dir_to_check does not exist."
fi

echo "Soft links created successfully!"

# Print build date
BUILD_DATE=$(cat /build_date.txt)
echo "=== Image build date: $BUILD_DATE ===" 

exec "$@"
