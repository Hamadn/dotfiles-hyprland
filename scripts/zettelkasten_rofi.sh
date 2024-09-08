#!/bin/bash

# Directory for Zettelkasten
ZETTELKASTEN="$HOME/second-brain"

# get_filename prompts the user for a filename, exits if nothing is entered
get_filename() {
    filename=$(rofi -dmenu -p "Enter filename (showing dirs from working dir):" -theme-str 'listview { columns: 1; }' -theme-str 'element { orientation: vertical; }')

    # Exit if no filename is entered
    if [[ -z "$filename" ]]; then
        echo "No filename entered. Exiting..."
        exit 1
    fi
}

# list_folders only displays folders, excluding the .obsidian folder
list_folders() {
    find "$ZETTELKASTEN" -type d ! -path "$ZETTELKASTEN/.obsidian*" -printf "%P\n" | sort
}

# choose_folder prompts the user to choose a folder from available folders
choose_folder() {
    folder=$(list_folders | rofi -dmenu -p "Select a folder (single-column tree view):" -theme-str 'listview { columns: 1; }')

    # Exit if no folder is selected
    if [[ -z "$folder" ]]; then
        echo "No folder selected. Exiting..."
        exit 1
    fi

    # Prepend Zettelkasten directory to the chosen folder
    folder="$ZETTELKASTEN/$folder"
}

# create_folder prompts the user to create a folder within an existing folder
create_folder() {
    # Ask the user where to create the new folder
    parent_folder=$(list_folders | rofi -dmenu -p "Select a folder to create a new folder inside:" -theme-str 'listview { columns: 1; }')

    # Exit if no folder is selected
    if [[ -z "$parent_folder" ]]; then
        echo "No folder selected. Exiting..."
        exit 1
    fi

    # Prepend Zettelkasten directory to the chosen parent folder
    parent_folder="$ZETTELKASTEN/$parent_folder"

    # Prompt for the name of the new folder to create
    new_folder=$(rofi -dmenu -p "Enter new folder name:" -theme-str 'listview { columns: 1; }')

    # Exit if no new folder name is entered
    if [[ -z "$new_folder" ]]; then
        echo "No folder name entered. Exiting..."
        exit 1
    fi

    # Combine parent folder and new folder name
    folder="$parent_folder/$new_folder"

    # Create the new folder
    mkdir -p "$folder"
}

# handle_path processes the path to create folders and files as needed
handle_path() {
    # Check if filename contains a slash indicating a folder
    if [[ "$filename" == */* ]]; then
        # Extract folder from the filename
        specified_folder="${filename%/*}"
        file_name="${filename##*/}"

        if [[ "$specified_folder" == "." ]]; then
            folder="$ZETTELKASTEN"
        else
            # If the specified folder starts with '/', remove the leading '/'
            if [[ "$specified_folder" == /* ]]; then
                specified_folder="${specified_folder:1}"
            fi

            folder="$ZETTELKASTEN/$specified_folder"

            # Check if the folder exists
            if [[ ! -d "$folder" ]]; then
                echo "Folder $folder does not exist."
                create_folder
                filename="$file_name"
            else
                # Folder exists
                folder="$folder"
                if [[ "$filename" == */ ]]; then
                    # Prompt for actual file name if input ends with '/'
                    get_filename
                else
                    filename="$file_name"
                fi
            fi
        fi
    else
        # If no folder is specified, ask the user to select a folder
        choose_folder
    fi
}

# create_and_open_file creates a file, inserts frontmatter, and opens it in Neovim
create_and_open_file() {
    date=$(date +"%Y-%m-%d")
    timestamp=$(date +"%Y%m%d%H%m")

    # Define the full file path
    fullpath="$folder/$filename.md"
    touch "$fullpath"

    # Format title by removing dashes
    title=${filename//-/ }

    # Add YAML frontmatter
    {
        echo "---"
        echo "title: $title"
        echo "date: $date"
        echo "---"
        echo -e "\n\n\n"
        echo "## Links:"
        echo -e "\n"
        echo "$timestamp"
    } >>"$fullpath"

    # Open the file in Neovim and run :NoNeckPain command
    nvim '+ normal 2GzzA' "$fullpath" -c :NoNeckPain
}

# Run the script
get_filename
handle_path
create_and_open_file
