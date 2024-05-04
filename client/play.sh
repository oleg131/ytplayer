#!/bin/bash
HOST="${HOST:-http://192.168.0.35:8080}"

query=$(whiptail --inputbox "Enter search query" 8 40 3>&1 1>&2 2>&3)

# Check if dialog was cancelled
exit_status=$?
if [ $exit_status -eq 0 ]; then
    # Fetch JSON data using curl with the encoded query
    encoded_query=$(jq -nr --arg data "$query" '$data|@uri')
    json_data=$(curl -s "$HOST/search?query=$encoded_query")

    # Parse JSON data and prepare arguments for dialog command
    # We use jq to extract the first 10 elements' index and title, ensuring each is a separate entry
    menu_items=()
    index=1
    while IFS= read -r title; do
        menu_items+=("$index" "$title")  # Add index and title as separate elements
        index=$((index + 1))
    done < <(echo "$json_data" | jq -r '. | .[].title')

    # Check if we have menu items
    if [ ${#menu_items[@]} -eq 0 ]; then
        echo "No items to display."
        exit 1
    fi

    # Use dialog to create a menu with items
    idx=$(whiptail --title "Select an Item" --menu "Choose one:" 10 50 5 "${menu_items[@]}" 3>&1 1>&2 2>&3)

    exit_status=$?
    if [ $exit_status -eq 0 ]; then
        id=$(echo "$json_data" | jq --arg idx "$idx" -r '. | .[$idx|tonumber - 1].id')

        url=$(curl -s "$HOST/get?id=$id")

        mpv --cache=no --msg-level=ao/alsa=fatal $url
    else
        echo "Dialog cancelled."
    fi

else
    echo "Dialog cancelled."
fi

exit 0
