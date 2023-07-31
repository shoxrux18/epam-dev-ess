#!/bin/bash

# Check if the input file is provided
if [ $# -eq 0 ]; then
    echo "Error: Please provide the path to the accounts.csv file as an argument."
    exit 1
fi

# Read the input file
input_file="$1"
output_file="./accounts_new.csv" # Specify the full path for the output file

# Remove the existing accounts_new.csv if it already exists
[ -f "$output_file" ] && rm "$output_file"

# Process the file line by line
while IFS= read -r line
do
    # Check if the line is empty or does not have the expected number of fields
    if [ -z "$line" ] || [ "$(echo "$line" | tr -cd ',' | wc -c)" -lt 5 ]; then
        continue
    fi

    # Check if it's the header line
    if [ "$line" = "id,location_id,name,title,email,department" ]; then
        # Create the new file with the column names
        echo "$line" > "$output_file"
    else
        # Extract the fields from the line
        id=$(echo "$line" | cut -d ',' -f1)
        loc_id=$(echo "$line" | cut -d ',' -f2)
        name=$(echo "$line" | cut -d ',' -f3)
        title=$(echo "$line" | cut -d ',' -f4)
        email=$(echo "$line" | cut -d ',' -f5)
        dep=$(echo "$line" | cut -d ',' -f6)

        # Handle commas inside double quotes in the title field
        if [ $(echo "$line" | grep -o "\".*\"" | wc -l) -eq 1 ]; then
            # Title field has commas inside double quotes
            title=$(echo "$line" | sed -E 's/^.*,"([^"]+),\s+([^"]+)".*$/"\1, \2"/')
        fi

        # Check if title contains the words "Director" and "Second" together
        if [[ $title == *"Director"* && $title == *"Second"* ]]; then
            # Add comma between "Director" and "Second"
            title=$(echo "$title" | sed -E 's/Director\s+Second/Director, Second/')
        fi

        # Check if title contains the words "Manager" and "Senior" together
        if [[ $title == *"Manager"* && $title == *"Senior"* ]]; then
            # Add comma between "Manager" and "Senior"
            title=$(echo "$title" | sed -E 's/Manager\s+Senior/Manager, Senior/')
        fi

        # Clear the temp variable
        unset name_new
        # Separate name and surname
        for n in $name; do
            # Check if the temp variable is empty
            if [ -z "$name_new" ]
            then
                # Make the first name letter capital
                name_new="${n^}"
                # Make the first part of the template for email doubles search
                template="$( echo ${n} | grep -o "^." )"
                # Add to email the first name letter (lowercase)
                email_new="$( echo ${n,,} | grep -o "^." )"
            else
                # The variable's not empty, so work with the surname
                # Add space and make the first letter capital
                name_new+=" ${n^}"
                # The second part of the template for email doubles search
                template+=".*\s${n}"
                # Add the surname to email (lowercase)
                email_new+="${n,,}"
                # Find doubles in names by the template
                dubl=$( grep -ci "$template" "$input_file" )
                if (( $dubl > 1 ))
                then
                    # Add location id to duplicated emails
                    email_new+="$loc_id"
                fi
                # Add the domain to email
                email_new+="@abc.com"
            fi
        done

        # Add the new string to the new file
        echo "$id,$loc_id,$name_new,$title,$email_new,$dep" >> "$output_file"
    fi

done < "$input_file"

# Remove the last comma from the new file (only if there is a second line in the file)
if [ $(wc -l < "$output_file") -gt 1 ]; then
    sed -i '$s/,$//' "$output_file"
fi

echo "New accounts file '$output_file' has been created."
