#!/bin/bash

# Function to get the duration of a video file using ffprobe
get_video_duration() {
    local file_path="$1"
    local duration

    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file_path" 2>/dev/null)
    
    # Handle potential error or empty output
    if [[ $? -ne 0 || -z "$duration" ]]; then
        echo "0"
    else
        echo "$duration"
    fi
}

# Function to format duration from seconds to hours and minutes
format_duration() {
    local total_seconds="$1"
    local hours
    local minutes

    hours=$(echo "$total_seconds / 3600" | bc)
    minutes=$(echo "($total_seconds % 3600) / 60" | bc)

    echo "${hours} hours ${minutes} minutes"
}

# Function to calculate total duration of video files in a directory
calculate_total_duration() {
    local directory="$1"
    local total_duration=0

    echo -e "\n🔍 Scanning directory: $directory\n"
    
    # Calculate duration for video files in the root directory
    echo "📂 Checking video files in the root directory..."
    for file in "$directory"/*; do
        if [[ -f "$file" && ( "$file" == *.mp4 || "$file" == *.mkv || "$file" == *.avi || "$file" == *.mov || "$file" == *.flv || "$file" == *.wmv || "$file" == *.webm ) ]]; then
            duration=$(get_video_duration "$file")
            total_duration=$(echo "$total_duration + $duration" | bc)
        fi
    done
    echo "✔️ Done!"

    # Calculate duration for video files in first-level subdirectories
    echo -e "\n📂 Scanning first-level subdirectories for video files..."
    for subdir in "$directory"/*/; do
        if [[ -d "$subdir" ]]; then
            subdir_duration=0
            while IFS= read -r -d '' file; do
                if [[ -f "$file" && ( "$file" == *.mp4 || "$file" == *.mkv || "$file" == *.avi || "$file" == *.mov || "$file" == *.flv || "$file" == *.wmv || "$file" == *.webm ) ]]; then
                    duration=$(get_video_duration "$file")
                    subdir_duration=$(echo "$subdir_duration + $duration" | bc)
                fi
            done < <(find "$subdir" -type f -print0)

            # Print duration for the first-level subdirectory, only the name
            if (( $(echo "$subdir_duration > 0" | bc -l) )); then
                echo "📁 Total duration of video files in '$(basename "$subdir")': $(format_duration "$subdir_duration")"
            fi
            
            total_duration=$(echo "$total_duration + $subdir_duration" | bc)
        fi
    done

    echo -e "\n📊 Total duration of all video files in the directory: $(format_duration "$total_duration")\n"
}

# Main script execution
clear
echo -e "***********************************"
echo -e "*      Video Duration Calculator  *"
echo -e "*      By Abhijit                 *"
echo -e "***********************************\n"

if [[ $# -ne 1 ]]; then
    echo "🚨 Usage: $0 <directory_path>"
    exit 1
fi

directory="$1"

if [[ -d "$directory" ]]; then
    calculate_total_duration "$directory"
else
    echo "❌ Error: Directory '$directory' does not exist."
    exit 1
fi
