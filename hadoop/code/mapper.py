import sys
import json
import time

# Calculate the timestamp 24 hours ago
now = time.time()
twenty_four_hours_ago = now - 86400

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        record = json.loads(line)
    except json.JSONDecodeError:
        # Skip records that are not valid JSON
        continue

    # Filter records older than 24 hours
    created = record.get("created", 0)
    if created < twenty_four_hours_ago:
        continue

    record_type = record.get("record_type", "")
    if record_type == "user":
        # Emit key for new user count
        print("new_user\t1")
    elif record_type == "photo":
        # Emit key for photo count
        print("photo_count\t1")
        # Emit key for grouping photos by username
        username = record.get("username", "unknown")
        filename = record.get("filename", "unknown")
        print(f"photo_group\t{username}\t{filename}")