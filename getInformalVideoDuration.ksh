#!/bin/bash
# Pass in mov, mp4 or MTS exactly to get total duration of videos from current folder to MAXDEPTH of where script is puts.

# How to run manually:
# Place file in the folder where you have all videos.
# Then on terminal execute "./getNestedVideoDurationsFinal.kshs" to get total times of all three file types.
# Then on terminal execute "./getNestedVideoDurationsFinal.ksh <filetype - mov/mp4/MTS>" to get total time of a specific video file type.

# How to run via Platypus:
# Download Platypus and add this script to it's path.
# Select ksh file type, Text Window, Run as background, Update Version number
# Create application
# Move application to "1485 Dt-29-09-19" folder and double click to generate duration.csv file

# Platypus doesn't have /usr/local/bin in it's path so must add it to find ffprobe
export PATH=/usr/local/bin:$PATH

red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

filetype='MTS'
path='../../..'
maxdepth=3
LOGFILE=$path/durations.csv
MAX_COLUMNS=10

# Argument Parsing
# This will be better for the end user instead of placing this file in the location of the folder and whatnot.
if [ ! -z $1 ]; then
    if [[ $1 != */ ]]; then
        path=$1/
    else
        path=$1
    fi
    echo "Looking for files under following filepath - $path"

else
    echo "Looking for files under current (default) filepath - $(pwd)"
fi

if [ -f $LOGFILE ]; then
    rm -rf $LOGFILE
fi

echo "Application PATH: " $PATH

for outerFolder in $path/*; do
    # 1485 Dt-29-09-19
    if [ -d "$outerFolder" ]; then
        printf "1) $outerFolder\n"
        for satsangName in "$outerFolder"/*; do
        # 01 Aptavani 14 Parayan Morning Dt-29-09-19 Clips-142 Dur-
            if [ -d "$satsangName" ]; then
                printf "2) $satsangName\n"

                # Get total duration of all video files from one session's Came01/02/03/... folders
                # Ex) - All video files within 01 Aptavani 14 Parayan Morning Dt-29-09-19 Clips-142 Dur-
                # Changing -maxdept to > 1 will get totalDuration for nested video files of type ${filetype}
                for entry in "$satsangName"/*; do
                    if [[ "$entry" =~ "Clips for"* ]]; then
                        printf "Clips for Insert Detected! Setting max depth for duration to 1 folder.\n"
                        maxdepth=1
                    fi
                done
                printf "MAX DEPTH = $maxdepth\n"
                totalDurationMTS=$(find "$satsangName" -maxdepth $maxdepth -iname "*.MTS" -exec ffprobe -v quiet -of csv=p=0 -show_entries format=duration {} \; | paste -sd+ -| bc)
                totalDurationMOV=$(find "$satsangName" -maxdepth $maxdepth -iname "*.mov" -exec ffprobe -v quiet -of csv=p=0 -show_entries format=duration {} \; | paste -sd+ -| bc)
                totalDurationMP4=$(find "$satsangName" -maxdepth $maxdepth -iname "*.mp4" -exec ffprobe -v quiet -of csv=p=0 -show_entries format=duration {} \; | paste -sd+ -| bc)

                iMTS=$(printf "%.0f\n" $totalDurationMTS)
                iMOV=$(printf "%.0f\n" $totalDurationMOV)
                iMP4=$(printf "%.0f\n" $totalDurationMP4)
                total=$(( $iMTS + $iMOV + $iMP4))
                printf "TOTAL SECONDS OF ALL THREE FILE TYPES = $total\n"

                i=$(printf "%.0f\n" $total)
                ((sec=i%60, i/=60, min=i%60, hrs=i/60))
                format_timestamp=$(printf "%d:%02d:%02d" $hrs $min $sec)

                # Print colors
                # Note: Platypus does not showcase colored text.
                # printf "${red}$satsangName${end} \n --> ${grn}TOTAL DURATION OF ALL 3 FILE TYPES COMBINED - $format_timestamp${end}\n"
                printf "------------------------------------------------------------------------------------------------------------\n"
                printf "$satsangName, Total Duration: $format_timestamp\n"
                printf "------------------------------------------------------------------------------------------------------------\n"

                # Print without colors
                # Need to print to csv with comma separate so it can be imported to MS Excel or Numbers for easy copy into Master DV Excel file.
                # printf "$satsangName,$format_timestamp\n" >> $LOGFILE
                printf "$satsangName" >> $LOGFILE

                # Format file
                # Sometimes, the satsangName or folder name can have multiple commas in their name,
                # So irrespective of how many commas are in the satsangName, we want to shift the timestamp column
                # to the same column for easy readability.
                # Append empty columns up to MAX_COLUMNS. Then print format_timestamp.
                CURR_COMMAS=$(echo $satsangName | tr -cd , | wc -c)
                while [[ $CURR_COMMAS -le $MAX_COLUMNS ]]
                do
                    printf "," >> $LOGFILE
                    CURR_COMMAS=$(( $CURR_COMMAS + 1 ))
                done
                printf "$format_timestamp\n" >> $LOGFILE
            fi
        done
    fi
done