' simple networked multi player video sync script 
' Modified by Zach Poff (zachpoff.com) from scripts provided by Brightsign

' master

' set up project

' Define the name of the video file.
videoFile = "myFile.mp4"

' Define the output resolution
VideoMode$ = "1920x1080x50p"

' Define the volume percent...
audioVolume = 15

' Set Manual IP address
nc = CreateObject("roNetworkConfiguration", 0)
nc.SetIP4Address("192.168.1.10")
nc.SetIP4Netmask("255.255.255.0")
nc.SetIP4Broadcast("192.168.1.255")
nc.SetIP4Gateway("192.168.1.1")
nc.Apply()

' define broadcast port as 11167
sender = CreateObject("roDatagramSender")
sender.SetDestination("255.255.255.255", 11167)

' create media player, se volume and port
v = CreateObject("roVideoPlayer")
p = CreateObject("roMessagePort")
v.SetPort(p)
v.SetVolume(audioVolume)

' set mode
mode=CreateObject("roVideoMode")
mode.SetMode(VideoMode$)

' pause to allow slaves to boot up
sleep(10000)

' end of set up 
' define video looping part of script  

start:
	print "start"
	
' pre-cache the video 
	sender.Send("pre")
	v.PreloadFile(videoFile)	
' pause to allow brightsigns time to preload the vid
	sleep(500)
	
' send the start command	
	sender.Send("ply")
	v.Play()

' listen loop 
listen:
	msg = wait(2000,p)
	
	if type(msg) = "roVideoEvent" and msg.GetInt() = 8 then
	    sleep(1000)
		goto start
	endif

	goto listen
