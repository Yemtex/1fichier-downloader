#!/bin/bash

#  Copyright 2021-2023 eismann@5H+yXYkQHMnwtQDzJB8thVYAAIs
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

# Some lines were taken from the script 1fichier.sh by SoupeAuLait@Rindexxx

#region Functions

checkTor() {
	local torPort=
	for port in 9050 9150; do
		echo "" 2>/dev/null >/dev/tcp/127.0.0.1/${port}
		if [ "$?" = "0" ]; then
			torPort=${port}
		fi
	done
	echo ${torPort}
}

tcurl() {
	curl --proxy "socks5h://${torUser}:${torPassword}@127.0.0.1:${torPort}" --connect-timeout 15 --user-agent "Mozilla/5.0 (Windows NT 10.0; rv:109.0) Gecko/20100101 Firefox/115.0" --header "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" --header "Accept-Language: en-US,en;q=0.5" --header "Accept-Encoding: gzip, deflate, br" --compressed "$@"
}

failedDownload() {
	local baseDir=${1}
	local url=${2}
	echo "${url}" >>"${baseDir}/failed.txt"
}

removeTempDir() {
	local tempDir=${1}
	rm --recursive "${tempDir}"
}

removeCookies() {
	local cookieFile=${1}
	rm --force "${cookieFile}"
}

cancelDownload() {
	echo "Download cancelled."
	removeTempDir "${lastTempDir}"
	exit 1
}

createDirectory() {
	local directoryPath=${1}

	# Checks if the directory doesn't exist
	if [ ! -d "$directoryPath" ]; then
		# Attempts to create the directory
		# The condition checks the result of the mkdir command
		if ! mkdir -p "$directoryPath"; then
			# If mkdir fails, it prints an error message and exits the script with an error code
			echo "Failed to create directory path '$directoryPath'"
			exit 1
		fi
	fi
}

downloadFile() {
	trap cancelDownload SIGINT SIGTERM

	local url=${1}
	echo "Processing \"${url}\""...
	echo -n "Search for a circuit without wait time..."

	# Check for second argument
	if [ -z "${2}" ]; then
		# Set current path if second argument
		local baseDir=$(pwd)
	else
		# Create directory if not existend
		createDirectory "${2}"
		# Sets passed arguemnt as directory
		local baseDir=${2}
	fi
	
	local tempDir=$(mktemp --directory "${baseDir}/tmp.XXX")
	lastTempDir=${tempDir}

	local filenameRegEx='>Filename :<.*<td class="normal">(.*)</td>.*>Date :<'
	local maxCount=500
	local count=1
	local slotFound="false"
	local alreadyDownloaded="false"

	while [ ${count} -le ${maxCount} ]; do
		count=$((${count} + 1))
		echo -n "."

		local cookies=$(mktemp --tmpdir="${tempDir}" "cookies.XXX")
		torUser="user-${RANDOM}"
		torPassword="password-${RANDOM}"

		local downloadPage=$(tcurl --cookie-jar "${cookies}" --silent --show-error "${url}")
		if [[ "${downloadPage}" =~ ${filenameRegEx} ]]; then
			local filename=${BASH_REMATCH[1]}
			if [ -e "${baseDir}/${filename}" ]; then
				alreadyDownloaded="true"
				break
			fi
		fi

		grep --extended-regexp --quiet '<span style="color:red">Warning !</span>|<span style="color:red">Attention !</span>' <<<"${downloadPage}"
		if [ ! "$?" = "0" ]; then
			local checkSlot=$(grep --only-matching --perl-regexp 'name="adz" value="\K[^"]+' <<<"${downloadPage}")
			if [ ${checkSlot} ]; then
				echo "Found. Start downloading..."
				slotFound="true"
				break
			else
				removeCookies "${cookies}"
			fi
		else
			removeCookies "${cookies}"
		fi
	done

	if [ "${alreadyDownloaded}" = "true" ] || [ "${slotFound}" = "false" ]; then
		if [ "${alreadyDownloaded}" = "true" ]; then
			echo "Already downloaded. Skipping."
		elif [ "${slotFound}" = "false" ]; then
			echo "Unable to get a circuit without wait time after ${maxCount} tries."
			failedDownload "${baseDir}" "${url}"
		fi
		removeTempDir "${tempDir}"
		return
	fi

	local downloadLinkPage=$(tcurl --location --cookie "${cookies}" --cookie-jar "${cookies}" --silent --show-error --form "submit=Download" --form "adz=${get_me}" "${url}")
	local downloadLink=$(echo "${downloadLinkPage}" | grep --after-context=2 '<div style="width:600px;height:80px;margin:auto;text-align:center;vertical-align:middle">' | grep --only-matching --perl-regexp '<a href="\K[^"]+')
	if [ "${downloadLink}" ]; then
		tcurl --insecure --cookie "${cookies}" --referer "${url}" --output "${tempDir}/${filename}" "${downloadLink}" --remote-header-name --remote-name
		if [ "$?" = "0" ]; then
			removeCookies "${cookies}"
			if [ -e "${tempDir}/${filename}" ]; then
				mv "${tempDir}/${filename}" "${baseDir}/"
			else
				echo "Download failed."
				failedDownload "${baseDir}" "${url}"
			fi
		else
			failedDownload "${baseDir}" "${url}"
		fi
	else
		echo "Unable to extract download-link."
		failedDownload "${baseDir}" "${url}"
	fi
	removeTempDir "${tempDir}"

	trap - SIGINT SIGTERM
}

helpText() {
	echo "Usage:"
	echo "${0} File-With-URLs [Output-Path]"
	echo "or"
	echo "${0} URL [Output-Path]"
}

#endregion


#region Main

# Check for more than two arguments
if [ "$#" -gt 2 ]; then
	echo "ERROR: Too many arguments passed"
	helpText
	exit 1
# Check for first mandatory argument "File-With-URLs" or "URL"
elif [ -z "$1" ]; then
	echo "ERROR: Mandatory argument is missing"
	helpText
	exit 1
else
	# Set mandatory argument "File-With-URLs" or "URL"
	downloadSource=${1}
fi

# Check for second optional argument "Output-Path"
if [ ! -z "$2" ]; then
	# Set optional argument "Output-Path"
	outputPath=${2}
fi

# Check for TOR
torPort=$(checkTor)
if [ "${torPort}" = "" ]; then
	echo "Tor is not running!"
	exit 1
fi
echo "Tor is listening on port ${torPort}"

lastTempDir=
if [[ "${downloadSource}" =~ "1fichier.com" ]]; then
	downloadFile "${downloadSource}" "${outputPath}"
else
	if [ ! -f "${downloadSource}" ]; then
		echo "Unable to read file \"${downloadSource}\"!"
		exit 1
	fi
	while IFS= read -r line; do
		downloadFile "${line}" "${outputPath}"
	done <"${downloadSource}"
fi

#endregion
