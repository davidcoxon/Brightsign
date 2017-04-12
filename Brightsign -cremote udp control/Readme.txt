Serial & UDP Control Script
'v2.9

6-13-10
'added attract loop support, specified in settings section at top of the script.

Attract - added support for looping attract video. Name of attract video part of settings. 
	     If you want a video to play once before the attract file, change the avc.PlayAttract
	     call to avc.PlayAttract("once.mpg"). You can use any video file name, but that video
	     will play only once, and then the video named in settings.Attract$ will loop afterwards.


'added settings at top of script - incl video mode, serial port, udp port, etc.
'added reboot command

7-13-10
'added settings for network configuration
'To use manual IP settings, Settings.ManualIP=TRUE must be set.
'To use DHCP, Settings.ManualIP=FALSE must be set


7-26-10 
'added settings.ID so that you can use the same UDP receive and send port. All outgoing status messages include ID in text

	"BS1 <Status Message>"

'the unit ignores udp messages with the brightsign's ID in the name.
'Set settings.ID=0 to remove ID from responses. IF that's used, UDP send and receive ports must be different values


'8-23-10
'Added LOOPS command- loops a video (without audio) seamlessly


'1-31-11
'download, downloadSD, downloadUSB - downloads list of files from downloads.txt
'setwebfolder - set url to download from 
'download url+txtfile, for example, http://www.myserver.com/downloads.txt

'5-23-11
'Properly initialized serialon and networkon variables so hd210s wouldn't crash

'9-13-11
'Added status command - returns current playback status
'added Delete command - deletes specified file name
'Fixed playfile function so it doesn't try to play files from USB if the unit is an HD210



This control script allows you to send a series of commands including play, 
stop, search, pause, and resume to control video playback. No playlist is 
required. Simply add this script and your content to the flash card
and you can send the list of commands below to control playback. 


Latest Updates
-----------------
1. Settings - added ID so that the brightsign can attach BS<ID#> to its responses. 
2. LOOPS - new command to loop a video seamlessly. Only works with videos that have no audio.



Default Serial Port Settings:
******************************
115200, 8, N, 1
*Serial commands must be terminated with a carriage return. That's how
the script is currently written.



UDP Settings:
***************
UDP Send port 21075
UDP receive port 21076


*You can send udp commands to the IP address of the unit if it
acquires an IP address from the network.

*You can send UDP commands to the broadcast address if the unit
is using an autoip address of the form 169.254.x.y. The broadcast address
is 169.254.255.255, or you can use 255.255.255.255 to broadcast to any 
range.


Note: These settings can be changed at the top of the script. 


Commands Currently Supported:
*****************************
This control script supports the following commands. The commands are
not case sensitive.

Command Syntax: <command> or <command><space><argument>

e.g.	Play video.mpg
	Loop video.mpg
	Volume 85
	Stop
		

READY

When the unit starst up, it outputs the string READY over the serial port.
Output over UDP is disabled by default. READY is also sent at the completion
of any command once the unit is read to accept more commands.


1. Play or Play <file>
Play video.mpg - plays video.mpg once and stops on the last frame
Play	       - plays the most recent file found by the Search command
Sends "PLAY" as a response when the command is received.
Sends "ENDP" when the video has finished playing.
Sends "NoFl" if there's no file to play.
Sends "INVL" if the file failed to open or the name was incorrect.

2. PLAYCL <file>
PlayClear video.mpg - plays video.mpg once, and clears the screen when finished.
Sends "PLYC" as a response when the command is received.
Sends "ENDP" when the video has finished playing.

3. Stop
Stop - stops the currently playing video and leaves the last frame
Sends "STOP" as a response when the command is received.

4. StopCL
StopClear - stops the currently playing video and clears the screen.
Sends "STPC" as a response when the command is received.

5a. Loop <file>
Loop video.mpg - plays video.mpg in a loop until another command to play different file is received.
Sends "LOOP" as a response when the command is received. 
Sends "ENDL" when the video has finished one loop.


5b. LOOPS <file>
LOOPS video.mpg - loops a video seamlessly until another command is received. Requires videos without
audio. 


6. Search <file>
Search video.mpg - checks if video.mpg is present on the flash card.
Sends "SRCH" as a response when the command is received. 
Sends string found if the search is successfull.


7. Volume <setting>
Volume 75 - changes volume to 75% of normal. Changes on the fly.
Sends "VOLM" as a response when the command is received. 


8. Pause
Pauses video. requires firmware 3.2.67 or later.


9. Resume
Resumes a paused video. Requires firmware 3.2.67 or later.

10. List
Outputs a list of all image, audio, and video content on the flash card.


11. Reboot
Restarts the unit


12. Setwebfolder
sets URL for unit to download files from via http

13. Download, DownloadSD, DownloadUSB
Without an argument, downloads "downloads.txt" file from the web folder, and starts downloading
all files contained in that list. If the setwebfolder command isn't called, it downloads files from the settings.folderurl$ variable at the top of the script. 


13. Play,Search -updated
Play and search command now check if there's also an attached USB thumbdrive or hard drive, and return list of files from USB media. 

14. Delete
Deletes file from flash media.

15. Status
Returns current playback status of player.





