#!/bin/bash

# Set the database name
db_name="trending_tags.db"

# Set the number of days to keep tags
days_to_keep=7

# Set the config file name
config_file="config.json"

# Set the list of Mastodon instances to query
instances=("mastodon.social" "mastodon.xyz" "mstdn.jp")

# Check if sqlite3 is installed
command -v sqlite3 &>/dev/null || { echo "sqlite3 could not be found, please install it before running this script"; exit 1; }

# Create or connect to the database
sqlite3 "$db_name" <<EOF
CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY,
    instance TEXT,
    tag TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
EOF

# Loop over the instances and fetch their trending tags
for instance in "${instances[@]}"; do
  tags=$(curl -s "https://${instance}/api/v1/trends" | jq -r '.[].name')
  for tag in $tags; do
    # Insert the tag into the database
    sqlite3 "$db_name" "INSERT INTO tags (instance, tag) VALUES ('$instance', '$tag')"
  done
done

# Select all distinct tags from the last 7 days and generate the config file
cat > "$config_file" << EOF
{
    "FakeRelayUrl": "INSERT_RELAY_URL_HERE",
    "FakeRelayApiKey": "INSERT_API_KEY_HERE",
    "Tags": [
EOF

tags=$(sqlite3 "$db_name" "SELECT DISTINCT tag FROM tags WHERE timestamp > datetime('now', '-$days_to_keep days')")
last_tag=$(echo "$tags" | tail -1)
while read tag; do
  # Use tr to convert spaces to underscores
  tag=$(echo "$tag" | tr ' ' '_')
  
  # Add the tag to the config file
  if [ "$tag" = "$last_tag" ]; then
    echo "        \"$tag\"" >> "$config_file"
  else
    echo "        \"$tag\"," >> "$config_file"
  fi
done <<< "$tags"

cat >> "$config_file" << EOF
    ],
    "Instances": [
EOF

for ((i=0; i<${#instances[@]}; i++)); do
  # Use the original instance name
  instance="${instances[$i]}"
  
  # Check if this is the last instance in the array
  [ $i -eq $((${#instances[@]}-1)) ] && end_line=" " || end_line=","
  cat >> "$config_file" << EOF
        "$instance"$end_line
EOF
done

cat >> "$config_file" << EOF
    ]
}
EOF
