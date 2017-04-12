' simple networked multi player video sync script 
' Modified by Zach Poff (zachpoff.com) from scripts provided by Brightsign

' master

' set up project

' Define the name of the video file.
videoFile = "myVideo.mp4"

' Define the output resolution
VideoMode$ = "1920x1080x50p"

' Define the volume percent...
audioVolume = 15

' set mode
mode=CreateObject("roVideoMode")
mode.SetMode(VideoMode$)

' Set Manual IP address
ClientIP$ = "192.168.1.11"
nc = CreateObject("roNetworkConfiguration", 0)
nc.SetIP4Address(ClientIP$)
nc.SetIP4Netmask("255.255.255.0")
nc.SetIP4Broadcast("192.168.1.255")
nc.SetIP4Gateway("192.168.1.1")
nc.Apply()

' define receive port as 11167
receiver = CreateObject("roDatagramReceiver", 11167)

' create media player, se volume and port
v = CreateObject("roVideoPlayer")
v.SetVolume(audioVolume)
sleep(200)

v.PreloadFile(videoFile)
p = CreateObject("roMessagePort")

receiver.SetPort(p)

' listen loop 

listen:
	msg = wait(2000,p)

	if type(msg) = "roDatagramEvent" then 

        command = left(msg, 3)

		if command = "pre" then
				v.PreloadFile(videoFile)
		elseif command = "ply" then
				v.Play()
		else
			print msg
		endif

	endif

	goto listen
