import sys

# Dictionaries to accumulate counts and group photo filenames
counts = {"new_user": 0, "photo_count": 0}
photo_groups = {}

for line in sys.stdin:
    parts = line.strip().split("\t")
    if not parts or len(parts) < 2:
        continue

    key = parts[0]
    if key in ["new_user", "photo_count"]:
        try:
            counts[key] += int(parts[1])
        except ValueError:
            continue
    elif key == "photo_group" and len(parts) >= 3:
        username = parts[1]
        filename = parts[2]
        if username not in photo_groups:
            photo_groups[username] = []
        photo_groups[username].append(filename)

# Output the aggregated counts
print(f"new_user\t{counts['new_user']}")
print(f"photo_count\t{counts['photo_count']}")

# Output photo groups, grouped by username
for username, filenames in photo_groups.items():
    # Join filenames with commas for clarity
    files_str = ", ".join(filenames)
    print(f"photo_group\t{username}\t{files_str}")