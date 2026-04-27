set tempPath to "/tmp/human_typing_input.txt"
display dialog "Click Start to open the large scrollable text box.
Paste your text into TextEdit, press Command-S, then come back and click Continue. 

You may need to configure Accessibility settings during your first run.

Made by Yuecheng (Thomas) Ma" buttons {"Cancel", "Start"} default button "Start" cancel button "Cancel" with title "Human Typing Tool"

do shell script "rm -f " & quoted form of tempPath & "; touch " & quoted form of tempPath
do shell script "open -e " & quoted form of tempPath

repeat 20 times
	if application "TextEdit" is running then exit repeat
	delay 0.25
end repeat
tell application "TextEdit"
	activate
end tell

display dialog "Paste your text into TextEdit now.
When finished:
1. Press Command-S in TextEdit.
2. Click Continue here, DO NOT CLOSE THE TextEdit WINDOW!!!
3. During the countdown, click where you want the typing to happen." buttons {"Cancel", "Continue"} default button "Continue" cancel button "Cancel" with title "Human Typing Tool"

try
	tell application "TextEdit"
		if it is running then
			try
				save front document
				close front document saving yes
			end try
		end if
	end tell
end try

set typedText to do shell script "cat " & quoted form of tempPath
if typedText is "" then return

-- Terminal countdown with reliable completion detection
set flagFile to "/tmp/countdown_done.flag"
do shell script "rm -f " & flagFile

tell application "Terminal"
	activate
	set countdownTab to do script "clear; for i in 1 2 3 4 5 6 7 8 9 10; do filled=$(printf '%*s' $i '' | tr ' ' '#'); empty=$(printf '%*s' $((10-i)) '' | tr ' ' '-'); clear; echo 'Typing starts in ' $((10-i)) ' seconds...'; echo ''; echo '[' $filled$empty ']'; sleep 1; done; clear; echo 'Starting now...'; sleep 0.5; touch /tmp/countdown_done.flag"
end tell

-- Wait for the flag file to appear
repeat
	delay 0.3
	set flagExists to do shell script "test -f /tmp/countdown_done.flag && echo yes || echo no"
	if flagExists is "yes" then exit repeat
end repeat

do shell script "killall Terminal; rm -f /tmp/countdown_done.flag"

-- Helper: nearby keys on QWERTY for realistic fat-finger typos
on nearbyKey(c)
	set rows to {"qwertyuiop", "asdfghjkl", "zxcvbnm"}
	repeat with row in rows
		set rowStr to row as string
		set rowLen to length of rowStr
		repeat with k from 1 to rowLen
			if character k of rowStr is c then
				set candidates to {}
				if k > 1 then set end of candidates to character (k - 1) of rowStr
				if k < rowLen then set end of candidates to character (k + 1) of rowStr
				if (count of candidates) > 0 then
					return item (random number from 1 to (count of candidates)) of candidates
				end if
			end if
		end repeat
	end repeat
	return c
end nearbyKey

-- Helper: type a single character
on typeChar(c)
	tell application "System Events"
		if c is return or c is linefeed then
			key code 36
		else if c is tab then
			key code 48
		else
			keystroke c
		end if
	end tell
end typeChar

-- Helper: delete N characters
on deleteChars(n)
	tell application "System Events"
		repeat n times
			key code 51
			delay (random number from 0.04 to 0.09)
		end repeat
	end tell
end deleteChars

-- Helper: pause like a human realising a mistake
on mistakePause()
	delay (random number from 0.15 to 0.45)
end mistakePause

-- Main typing loop
set textLen to length of typedText
set i to 1

repeat while i ≤ textLen
	set currentChar to character i of typedText
	
	-- === SCENARIO 1: Full false start ===
	if i > 1 and currentChar is not space and currentChar is not return then
		if (random number from 1 to 180) = 1 then
			set falseCount to random number from 2 to 5
			repeat falseCount times
				my typeChar(my nearbyKey(currentChar))
				delay (random number from 0.07 to 0.18)
			end repeat
			my mistakePause()
			my deleteChars(falseCount)
			delay (random number from 0.1 to 0.3)
		end if
	end if
	
	-- === SCENARIO 2: Single fat-finger typo ===
	if currentChar is not space and currentChar is not return then
		if (random number from 1 to 35) = 1 then
			my typeChar(my nearbyKey(currentChar))
			delay (random number from 0.08 to 0.25)
			my mistakePause()
			my deleteChars(1)
			delay (random number from 0.05 to 0.15)
		end if
	end if
	
	-- === SCENARIO 3: Fingers running ahead ===
	if currentChar is not return then
		if (random number from 1 to 60) = 1 then
			my typeChar(currentChar)
			delay (random number from 0.05 to 0.12)
			set extraCount to random number from 1 to 3
			repeat extraCount times
				my typeChar(my nearbyKey(currentChar))
				delay (random number from 0.05 to 0.1)
			end repeat
			my mistakePause()
			my deleteChars(extraCount)
			delay (random number from 0.05 to 0.15)
			set i to i + 1
		else
			my typeChar(currentChar)
			set i to i + 1
		end if
	else
		my typeChar(currentChar)
		set i to i + 1
	end if
	
	-- === Natural inter-key delay ===
	if currentChar is space then
		delay (random number from 0.06 to 0.18)
	else
		delay (random number from 0.07 to 0.28)
	end if
	
	-- === Post-punctuation pause ===
	if currentChar is "." or currentChar is "!" or currentChar is "?" then
		delay (random number from 1.2 to 4.0)
	else if currentChar is "," or currentChar is ";" or currentChar is ":" then
		delay (random number from 0.3 to 0.9)
	end if
	
	-- === Post-newline pause ===
	if currentChar is return or currentChar is linefeed then
		delay (random number from 2.5 to 7.0)
	end if
	
	-- === Random micro-pause ===
	if (random number from 1 to 40) = 1 then
		delay (random number from 0.4 to 1.8)
	end if
	
end repeat
