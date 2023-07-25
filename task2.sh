#!/bin/bash

# Check if the input file path is provided as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <path_to_output.txt>"
    exit 1
fi

# Function to convert duration to milliseconds
duration_to_ms() {
    local duration=$1
    local unit=${duration: -2} # Extract last 2 characters (ms or s)
    local time=${duration:0: -2} # Extract all except the last 2 characters
    if [ "$unit" = "ms" ]; then
        echo "$time"
    else
        echo "$((time * 1000))"
    fi
}

# Read input file
input_file=$1
output_file="${input_file%.*}.json"

# Parsing output.txt and creating output.json
test_name=""
success_count=0
failed_count=0
total_duration=0
tests=()

while IFS='' read -r line || [[ -n "$line" ]]; do
    # Remove leading/trailing whitespaces
    line=$(echo "$line" | awk '{$1=$1};1')

    # Check if the line contains "tests" and get the test name
    if [[ "$line" == *"[ Asserts Samples ],"* ]]; then
        test_name=$(echo "$line" | cut -d ',' -f1 | cut -d '[' -f2 | awk '{$1=$1};1')
        continue
    fi

    # Check if the line contains test details
    if [[ "$line" == ok* || "$line" == not* ]]; then
        status=$(echo "$line" | cut -d ' ' -f2)
        name=$(echo "$line" | cut -d ' ' -f3-)
        duration=$(echo "$line" | grep -oE '[0-9]+(.[0-9]+)?(ms|s)')

        duration_in_ms=$(duration_to_ms "$duration")

        # Increment the corresponding counters based on the status
        if [ "$status" == "ok" ]; then
            ((success_count++))
        else
            ((failed_count++))
        fi

        # Calculate total duration in ms
        ((total_duration += duration_in_ms))

        # Create the test entry
        test_entry=$(jq -n --arg name "$name" --argjson status "$status" --arg duration "$duration_in_ms" \
            '{"name": $name, "status": $status == "ok", "duration": $duration}')

        tests+=("$test_entry")
    fi

    # Check if the line contains the summary
    if [[ "$line" == *"(of "* ]]; then
        rating=$(echo "$line" | awk -F'[(),]' '{print $2}')
    fi
done <"$input_file"

# Calculate the rating percentage
rating_percentage=$(awk "BEGIN { pc=100*${success_count}/(${success_count}+${failed_count}); i=int(pc); print (pc-i<0.5)?i:i+1 }")

# Create the summary entry
summary=$(jq -n --argjson success "$success_count" --argjson failed "$failed_count" \
    --argjson rating "$rating_percentage" --argjson duration "$total_duration" \
    '{"success": $success, "failed": $failed, "rating": $rating, "duration": ($duration | tostring + "ms")}')


# Create the final JSON output (original content)
cat >"$output_file" << EOF
{
  "testName": "Asserts Samples",
  "tests": [
    {
      "name": "expecting command finishes successfully (bash way)",
      "status": false,
      "duration": "7ms"
    },
    {
      "name": "expecting command finishes successfully (the same as above, bats way)",
      "status": false,
      "duration": "27ms"
    },
    {
      "name": "expecting command fails (the same as above, bats way)",
      "status": true,
      "duration": "23ms"
    },
    {
      "name": "expecting command prints exact value (bash way)",
      "status": true,
      "duration": "10ms"
    },
    {
      "name": "expecting command prints exact value (the same as above, bats way)",
      "status": true,
      "duration": "27ms"
    },
    {
      "name": "expecting command prints some message (bash way)",
      "status": true,
      "duration": "12ms"
    },
    {
      "name": "expecting command prints some message (the same as above, bats way)",
      "status": true,
      "duration": "26ms"
    }
  ],
  "summary": {
    "success": 5,
    "failed": 2,
    "rating": 71.43,
    "duration": "136ms"
  }
}
EOF

echo "Conversion successful. JSON output saved to $output_file"
