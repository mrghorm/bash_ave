#!/bin/bash

# Bash Auto Video Encoder -- Adobe Premiere CC 2018 Compliant
#

# TODO:  Turn this into a run flag later
# Set this command to 1 to run in verbose mode.  NOTE:  Verbose mode is still a work in progress!
verbose=1;

current_dir=$(pwd);

test $verbose -eq 1 && echo "Current working directory set to $current_dir"

#Note:  Override the above command with your own directory for safety
#current_dir=/home/yourusername/bash_ave/

#cd /home/mrghorm/bash_ave_r710

# Establishes working directories
	file_in_dir="RAW_FOOTAGE"
	file_out_dir="TO_REVIEW"
	file_encode_dir="ENCODED_FOOTAGE"
	file_failed_dir="FAILED"

# Test the directories to make sure they exist...  if not, then exit.
test $verbose -eq 1 && echo "Testing for $file_in_dir..."
(test -d "$file_in_dir/" && echo "Directory successfully found...") || echo "Directory not found!" &&  exit 1;
test $verbose -eq 1 && echo "Testing for $file_out_dir..."
(test -d "$file_out_dir/" && echo "Directory successfully found...") || echo "Directory not found!" && exit 1;
test $verbose -eq 1 && echo "Testing for $file_encode_dir..."
(test -d "$file_encode_dir/" && echo "Directory successfully found...") || echo "Directory not found!" &&  exit 1;
test $verbose -eq 1 && echo "Testing for $file_failed_dir..."
(test -d "$file_failed_dir/" && echo "Directory successfully found...") || echo "Directory not found!" &&  exit 1;

echo "Oh no it didn't exit..."
exit


# Echos arg1 out to console with colors enabled
#	while copying output to designated output file with timestamp attached
function time_echo {

	thetime=$( date +"%F_%T" )
	echo -e "[$thetime] $1" | tee -a auto_video_encoder_output.txt

}

# Gets size of a file, uses most reasonable unit of size
### Function takes a file location as an argument
function get_filesize {

	filesize_real=$(stat --printf="%s" $1)
	echo $filesize_real

}

# Function takes a filesize (integer) and returns filesize in human readable form
### Function takes an integer for arg1
function interpret_filesize {

	filesize_real=$1
	filesize_real_tmp=$(($filesize_real * 1))

	#filesize_k=$(($filesize_real / 1000))
	#filesize_m=$(($filesize_real / 1000000))
	#filesize_g=$(($filesize_real / 1000000000))

	filesize_k=$(echo "scale=2; $filesize_real_tmp / 1000" | bc)
	filesize_m=$(echo "scale=2; $filesize_real_tmp / 1000000" | bc)
	filesize_g=$(echo "scale=2; $filesize_real_tmp / 1000000000" | bc)

	#If statments look odd because "bc" statment resolves to 0
	#	To resolve this, I added the "! -eq 0" in order to give the if statment
	#	concrete resolution that wasn't just an integer
	if [ ! $(echo "$filesize_g > 1" | bc) -eq 0 ]; then
		echo "$filesize_g GB"

	elif [ ! $(echo "$filesize_m > 1" | bc) -eq 0 ]; then
		echo "$filesize_m MB"

	elif [ ! $(echo "$filesize_k > 1" | bc) -eq 0 ]; then
		echo "$filesize_k KB"

	elif [ ! $(echo "$filesize_real > 1" | bc) -eq 0 ]; then
		echo "$filesize_real B"
	else
		echo "Error"
	fi

}

# Estimates encoding time based on length of video file and
# ASSUMES FILE RUNS AT 60 FPS
### Function takes a file location as argument $1
function estimate_encode_time {

	#Gets total number of frames in video file
	number_of_frames=$(ffprobe -v error -count_frames -select_streams v:0 -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1 $1)

	#Estimated all encodes run at an avg of 2.25 FPS
	est_time_seconds=$(echo "scale=2; $number_of_frames / 2.25" | bc)
	est_time_hours=$(echo "scale=2; $est_time_seconds / 3600" | bc)

	echo $est_time_hours h

}

time_echo "Starting bash auto video encoder"

# Check if directories exist and if user has permissions
time_echo "Checking $file_in_dir..."
ls "$file_in_dir/"
file_in_exitcode=$?
time_echo "Checking $file_out_dir..."
ls "$file_out_dir/"
file_out_exitcode=$?
time_echo "Checking $file_encode_dir..."
ls "$file_encode_dir/"
file_encode_exitcode=$?
time_echo "Checking $file_failed_dir..."
ls "$file_failed_dir/"
file_failed_exitcode=$?

if [ ! $file_in_exitcode -eq 0 ]; then
	time_echo "FILES_IN directory does not exist!"
	exit 1
elif [ ! $file_out_exitcode -eq 0 ]; then
	time_echo "FILES_OUT directory does not exist!"
	exit 1
elif [ ! $file_encode_exitcode -eq 0 ]; then
	time_echo "FILES_ENCODE directory does not exist!"
	exit 1
elif [ ! $file_failed_exitcode -eq 0 ]; then
	time_echo "FILES_FAILED directory does not exist!"
	exit 1
fi

# While forever
while : ; do


	# Reset variables to standard
	filename=""
	start_time=0
	end_time=0
	delta_time=0
	filesize_real_raw=0
	filesize_real_encoded=0
	hb_exit_code=0
	file_mv_exit_code=0


	# Gets filenames from RAW_FOOTAGE/
    files="$( ls RAW_FOOTAGE/ )"

	# Checks if any files exist in $files var
	# NOTE: Essentially checks if any files exist in RAW_FOOTAGE/
	if [[ -z "${files// }" ]]; then
		time_echo "No more files to encode"
		break
	fi

	# Ensure that no other instance of HandBrakeCLI is running before beginning the program
	if ps -ef | grep -v grep | grep HandBrakeCLI ; then
		echo ""
		time_echo "\e[31mWarning!  An instance of HandBrakeCLI is already running!\e[39m  Please exit HandBrakeCLI before starting bash_ave.sh"
		exit 2

	fi

	# Set IFS to newline, save old value
	# NOTE: This is for the for loop. For loop typically uses spaces to separate
	#		commands, this sets it to use newlines.
	OLDIFS=$IFS
	IFS=$'\n'

	### For loop acts on any currently known files ###
    for entry in $files; do

	time_echo "\n"
	time_echo "-------------------------------------"
	time_echo "Attempting to encode \e[33m$entry\e[39m"


	# Establishes working directories
	#---Files established at top of file---
		#file_in_dir="RAW_FOOTAGE"
		#file_out_dir="TO_REVIEW"
		#file_encode_dir="ENCODED_FOOTAGE"
		#file_failed_dir="FAILED"


 # Gets location of file to encode
		fileloc="$file_in_dir/$entry"

	# Strips file entry down to just filename
		filename="${entry##*/}"

	# Get size of file
		filesize_real_raw=$(get_filesize "$file_in_dir/$entry")
		filesize_interpret_raw=$(interpret_filesize filesize_real_raw)

	# Get est encode time (hours)
		#est_encode_time=$(estimate_encode_time $fileloc)


	# Checks whether or not file already exists in the output directory as a duplicate
	if [[ -f "$file_encode_dir/$filename" ]]; then

		time_echo "\e[31mInput file already exists in output directory!\e[39m"
		# time_echo "\e[31mMoving file from output directory into failed directory...\e[39m"
		time_echo "\e[31mTesting output file with ffprobe...\e[39m"

		# Runs ffprobe and captures output
		ffprobe_output=$(ffprobe -loglevel error $file_encode_dir/$filename)
		ffprobe_exit_code=$?

		if [[ $ffprobe_exit_code != 0 ]]; then

			# time_echo "\e[31mWarning!  ffprobe was not able to run successfully.  Ensure permissions are set up correctly, and check the file for errors.\e[39m"
			# time_echo "Filename:  $file_encode_dir/$filename"
			# time_echo "\e[31mExiting bash_ave...\e[39m"
			# IFS=$OLDIFS
			# exit 1

			time_echo "\e[31mffprobe has detected errors with the output file, moving output file to failed directory...\e[39m"

			# Combines $filename variable with extra text at the end.  The brackets help deliniate the var from the extra text.
			dup_failed_filename="${filename}_dup_failed" 

			# Move file to failed dir with extra text at the end
			mv "$file_encode_dir/$filename" "$file_failed_dir/$dup_failed_filename"

			file_mv_exit_code_2=$?

			# Send warning if "mv" command failed
			if [ ! $file_mv_exit_code_2 -eq 0 ]; then
				time_echo "\e[31mError moving file!  Exiting bash_ave.sh...\e[39m"
				IFS=$OLDIFS
				exit 1
			fi

			break

		# This will run if ffprobe produced an output (With "-loglevel error", this means that ffprobe will only output if it finds something wrong)
		elif [[ $ffprobe_output ]]; then

			time_echo "\e[31mffprobe has detected errors with the output file, moving output file to failed directory...\e[39m"

			# Combines $filename variable with extra text at the end.  The brackets help deliniate the var from the extra text.
			dup_failed_filename="${filename}_dup_failed" 

			# Move file to failed dir with extra text at the end
			mv "$file_encode_dir/$filename" "$file_failed_dir/$dup_failed_filename"

			file_mv_exit_code_2=$?

			# Send warning if "mv" command failed
			if [ ! $file_mv_exit_code_2 -eq 0 ]; then
				time_echo "\e[31mError moving file!  Exiting bash_ave.sh...\e[39m"
				IFS=$OLDIFS
				exit 1
			fi

			break

		# This will run if ffprobe returned no output
		else
			time_echo "\e[33mffprobe did not detect any errors with output file.  Moving input file to failed directory as duplicate...\e[39m"

			dup_filename="${filename}_duplicate"

			mv "$file_in_dir/$filename" "$file_failed_dir/$dup_filename"

			file_mv_exit_code_2=$?

			if [ ! $file_mv_exit_code_2 -eq 0 ]; then
				time_echo "\e[31mError moving file!  Exiting bash_ave.sh...\e[39m"
				IFS=$OLDIFS
				exit 1
			fi

			break

		fi

		# ffprobe



	fi



	# Output information and encode
		time_echo "Filesize is \e[33m$filesize_interpret_raw\e[39m"
		# time_echo "Estimated TTE: \e[33m$est_encode_time\e[39m"

		start_time=$(date +%s)

		(HandBrakeCLI -i "$fileloc" -o "$file_encode_dir/$filename" --optimize -e x264 --x264-preset veryslow -q 21 -r 60 -w 1920 -l 1080 -a "1,2,3,4,5,6,7" -E copy:ca_aac -B 512) 2>> handbrake_output.txt

		hb_exit_code=$?

		if [ $hb_exit_code -eq 1 ]; then
			time_echo "ctrl-C pressed: killing program"
			time_echo "\e[31mRemoving incomplete file from output directory...\e[39m"
			rm "$file_encode_dir/$filename"
			IFS=$OLDIFS
			exit 0
		fi

	# If handbrake fails, move file to FAILED/
	    if [ ! $hb_exit_code -eq 0 ]; then
		    time_echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		    time_echo "\e[31mHANDBRAKE FAILURE\e[39m! Exit code: $hb_exit_code"
		    time_echo "Moved \e[31m$filename\e[39m to FAILED_DIR"

		    mv "$fileloc" "$file_failed_dir/"
			file_mv_exit_code=$?

			# Checks that file moved successfully
			if [ $file_mv_exit_code -eq 0 ]; then
				time_echo "\e[32m$filename\e[39m was successfully encoded and moved"
			else
				time_echo "Move of \e[31m$fileloc\e[39m failed!"
				time_echo "Exiting program..."

				# Would exit program immediately, this bypasses database insert
				# exit 1
			fi


			# Would exit program immediately, this bypasses database insert
			# exit 1
	    fi




	# Checks if encoder finished successfully (ie exit code 0)
		if [ $hb_exit_code -eq 0 ]; then

		# Moves raw file to TO_REVIEW/
		# Decided to use copy mechanism for security
			# mv "$fileloc" "$file_out_dir/"
			rm "$fileloc"
			file_mv_exit_code=$?

		# Checks that file moved successfully
			if [ $file_mv_exit_code -eq 0 ]; then
				time_echo "\e[32m$filename\e[39m was successfully encoded and moved"
			else
				time_echo "Move of \e[31m$fileloc\e[39m failed!"
				time_echo "Exiting program..."

				# Would exit program immediately, this bypasses database insert
				# exit 1
			fi


		# Get filesize of encoded file and report percentage shrunk
			filesize_real_encoded=$(get_filesize "$file_encode_dir/$entry")
			filesize_interpret_encoded=$(interpret_filesize filesize_real_encoded)

			filesize_result_percentage=$(echo "scale=2; $filesize_real_encoded / $filesize_real_raw" | bc)

			filesize_result_percentage_final=$(echo "$filesize_result_percentage * 100" | bc)
			time_echo "File is \e[32m$filesize_result_percentage_final%%\e[39m of original file at \e[32m$filesize_interpret_encoded\e[39m"

	# If handbrake fails, move file to FAILED/
		#elif [ ! $? -eq 0 ]; then
		#	time_echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		#	time_echo "\e[31mHANDBRAKE FAILURE\e[39m! Exit code: $?"
		#	#time_echo "Moved \e[31m$filename\e[39m to FAILED/"
		#	#mv "$fileloc" FAILED/
		#	#exit 1
		fi



		echo $'\n\n\n\n\n\n\n\n\n\n' >> handbrake_output.txt

		end_time=$(date +%s)
		delta_time=$(echo "$end_time - $start_time" | bc)
		time_echo "Seconds to encode: $delta_time"
		#echo $filename
		#echo $start_time
		#echo $end_time
		#echo $delta_time
		#echo $filesize_real_raw
		#echo $filesize_real_encoded
		#echo $hb_exit_code
		#echo $file_mv_exit_code
		#sqlite3 bash_ave_r710_temps.db "INSERT INTO AVE_Log1 (FileName, StartTime, EndTime, EncodeSeconds, StartSize, EndSize, HandBrakeExitCode, MvExitCode) 
			#VALUES('$filename',$start_time,$end_time,$delta_time,$filesize_real_raw,$filesize_real_encoded,$hb_exit_code,$file_mv_exit_code);"

		# The below command essentially tries to find every ' character in the string, and replace it with '' for the SQL insert below
		#     See this link for more details:  https://stackoverflow.com/questions/43311959/how-to-replace-single-quotes-with-two-single-quotes-in-bash-in-bash
		filename_sql_compatible="${filename//\'/''}"

		time_echo "'$filename_sql_compatible',$start_time,$end_time,$delta_time,$filesize_real_raw,$filesize_real_encoded,$hb_exit_code,$file_mv_exit_code"

		sqlite3 bash_ave_r710_temps.db "INSERT INTO AVE_Log1 (FileName, StartTime, EndTime, EncodeSeconds, StartSize, EndSize, HandBrakeExitCode, MvExitCode)
			VALUES('$filename_sql_compatible',$start_time,$end_time,$delta_time,$filesize_real_raw,$filesize_real_encoded,$hb_exit_code,$file_mv_exit_code);"
		sql_exit_code=$?
		#time_echo $sql_output


		time_echo "\n"

	# Make sure to exit in the event of a failure of some kind
		#if [ ! $hb_exit_code -eq 0 ]; then
		#	#exit 1
		if [ ! $file_mv_exit_code -eq 0 ]; then
			time_echo "mv exit code was not 0!  Exit code was: $file_mv_exit_code"
			IFS=$OLDIFS
			exit 1
		elif [ ! $sql_exit_code -eq 0 ]; then
			time_echo "SQL exit code was not 0!  Exit code was: $sql_exit_code"
			#time_echo "$sql_output"
			IFS=$OLDIFS
			exit 1
		fi


	# Reset IFS
    done
	IFS=$OLDIFS

done
