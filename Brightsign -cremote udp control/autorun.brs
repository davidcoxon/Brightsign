
'Serial or UDP control Script

Sub Main()
	version$="v2.8v4"
	settings = createobject ("roAssociativeArray")
	settings.debug = false
	
	REM 
	REM The two UDP ports cannot be the same
	settings.udpPortSend=21075		'for sending udp commands
	settings.udpPortReceive=21076	'for receiving UDP commands
	settings.udpDestinationAddress$ = "255.255.255.255"
	settings.serialPortSpeed=115200
	settings.serialPortMode$="8N1"
	settings.videoMode$ = "1920x1080x60p"   'set to "empty" to use automode
	settings.Attract$ = "attract.ts"      'video loops when nothing else plays
	settings.ID=0 'can be used as a unique identifier for Brightsign. Set to zero to ignore the ID.
	
	settings.ManualIp=false	'set to false to use dhcp
	settings.IPAddress$="192.168.137.101"
	settings.Subnet$="255.255.255.0"
	settings.Gateway$="192.168.137.1"
	settings.Broadcast$="192.168.137.255"
	settings.DNS1$="192.168.137.1"
	settings.DNS2$="192.168.1.1"
	settings.DNS3$=""
	settings.AudioOutput=3 '3 - hdmi
	
	'sync
	settings.master=false
	
	'downloading files
	dim dlist[100]
	settings.folderurl$="http://192.168.137.1:100/1/"
	settings.storage$="SD:"
	settings.download_list$="downloads.txt"	'file with list of files to be downloaded
	settings.fullurl$=" "
	settings.dlist=dlist

	'Initialize
	avc = NewControl(settings)
	avc.SendResponse("Start"+chr(13))
	avc.SendResponse("Control Script Version: "+version$)
	
	'Play Attract
	'Comment out this function if you want the unit to startup to a blank screen
	
	avc.PlayAttract(settings.Attract$)
	
	'Listen for commands 
	avc.listen()

End Sub



Sub Listen()
While True

msg=wait(m.timeout,m.msgport)

if type(msg) = "roVideoEvent" then
	if m.debug m.sendResponse("Video Event Detected: "+ str(msg.GetInt()))

	if msg.GetInt() = m.MEDEN and not m.loop_seamless then
	
	
		if m.loop_attract and m.loop_video = false then
			m.SendResponse("ATTR") 
			m.status = "Looping: " + m.file_name 
			m.PlayFile(UCASE(m.attract$))

			
		else if m.loop_video then
			m.SendResponse("ENDL") 
			m.status = "Looping: " + m.file_name 
			m.PlayFile(m.file_name)

		else
			if m.lframe = false then 
				m.video.StopClear()
			else 
				m.video.Stop()
			endif
			m.SendResponse("ENDP")
			m.ResetVar()
			m.SendResponse("READY")
		endif
	endif

else if type(msg) = "roAudioEvent" then
	if m.debug m.sendResponse("Audio Event Detected: "+str(msg.GetInt()))

	if msg.GetInt() = m.MEDEN then
		if m.loop_audio then
			m.SendResponse("ENDL") 
			m.status = "Looping: " + m.file_name
			m.PlayFile(m.file_name)
 
		else
			m.audio.Stop()
			m.SendResponse("ENDP")
			m.ResetVar()
			m.SendResponse("READY")
		endif
	endif

else if type(msg) = "roStreamLineEvent" then
	if m.debug m.sendResponse("Serial Event Detected: "+ msg)
	if len(msg) > 3 then m.ProcessCommand(msg.GetString())

else if type(msg) = "roDatagramEvent" then
	if m.debug m.sendResponse("UDP Datagram Detected: "+ msg)
	
	rem Ignore messages sent with the same ID as the brightsign
	if instr(1, msg, "BS"+mid(str(m.ID),2)) = 0 and len(msg) > 3 then m.ProcessCommand(msg.GetString())

else if type(msg) = "roUrlEvent" then
	if m.debug m.sendresponse("roUrlEvent")
	if msg.GetSourceIdentity() = m.txfer.GetIdentity() then m.HandleTxferEvent(msg)
	if msg.GetSourceIdentity() = m.fxfer.GetIdentity() then m.HandleFxferEvent(msg) 
	
else if type(msg) = "roTimerEvent" and m.download_cmd_received then	
	m.download_cmd_received=false
	if m.debug m.sendresponse("roTimerEvent")
	if msg.GetSourceIdentity() = m.dtimer.GetIdentity() and m.networkOn then 
		m.GetText(0)
	endif

		
else
     if m.debug m.sendResponse("Unsupported Event.")
     
endif

End While

End Sub


Sub PlayFile(file As String)
   if m.debug m.sendResponse("Playfile: "+ file)
   m.GetFileType(file)
   if m.downloadActive and file = m.current_download$ then
		m.SendResponse("DWNLDG")
		return
   endif
   
   if file <> "No File" then
		if m.FileType = "VIDEO" then
			if m.loop_seamless or m.loop_attract then m.video.SetLoopMode(true)
			ok = m.video.PlayFile(file)
			m.image.StopDisplay()
			if ok and m.debug m.sendResponse("Playing video: "+ file)
			if ok = 0 then
				if ucase(m.modelObject.GetModel()) = "HD210W" or m.modelObject.GetModel() = "HD210" or m.modelObject.GetModel() = "HD410" then
					m.SendResponse("INVL")
				else
						ok = m.video.PlayFile("USB1:"+file)
						if ok=0 and m.debug m.sendResponse("Playing video: "+ file)
						if ok=0 m.SendResponse("INVL")			
				endif
				

			endif
			
		else if m.FileType = "AUDIO" then
			ok = m.audio.PlayFile(file)
			if ok and m.debug m.sendResponse("Playing Audio: "+ file)
			if ok = 0 then m.SendResponse("INVL")
		else if m.FileType = "IMAGE" then
			ok = m.image.DisplayFile(file)
			if ok and m.debug m.sendResponse("Playing Image: "+ file)
			if ok = 0 then m.SendResponse("INVL")
		endif
   else
	m.SendResponse("NoFl")
   endif
End Sub


Sub PlayAttract(Attract$ As String)
   if m.debug m.sendResponse("Start Attractloop")
   'm.loop_video=true
   m.loop_attract=true
   m.file_name=UCASE(Attract$)
   m.PlayFile(UCASE(Attract$))
   
End Sub


REM Accepts <Command> <space> <file name or setting>
Sub ProcessCommand(serialString As String)

command=UCASE(m.StripSpaces(serialString))

if m.debug m.sendResponse("Processing Command String: "+ command)
if command = "STOP" then 
	m.video.Stop()
	m.audio.Stop()
	m.image.StopDisplay()
	m.SendResponse("STOP")
	m.SendResponse("READY")
	m.status ="Stopped"

else if command = "REBOOT" then 
	m.SendResponse("REBT")
	RebootSystem()

else if command = "DOWNLOAD" then 'not implemented
	m.download_cmd_received=true
	m.SendResponse("DWNL")
	if m.debug m.SendResponse("Download")
	m.SetDTimer()

	
else if command = "DOWNLOADSD" then
	m.download_cmd_received=true
  	m.SendResponse("DWSD")
	m.settings.storage$="SD:"
	m.SendResponse("READY")
	m.SetDTimer()

else if command = "DOWNLOADUSB" then 
	m.download_cmd_received=true
  	m.SendResponse("DWUSB")
	m.settings.storage$="USB1:"
	m.SendResponse("READY")
	m.SetDTimer()
	
	
else if command = "DOWNSTOP" then 'not implemented
	m.SendResponse("DWNS")
	if m.debug m.SendResponse("Stop Download")
	'm.cancelDownloads()
	
else if command = "DOWNSCRP" then 'not implemented
	m.SendResponse("DWAR")
	if m.debug m.SendResponse("Download Autorun")
	'm.cancelDownloads()
		
	
	
else if command = "STOPCL" then 
	m.video.StopClear()
	m.image.StopDisplay()
	m.SendResponse("STPC")
	m.SendResponse("READY")
	m.status ="Stopped"


else if command = "PLAY" then 
	m.SendResponse("PLAY")
	m.loop_video=false
	m.loop_audio=false
	m.loop_attract=false
	m.loop_seamless=false
	m.PlayFile(m.search_value)
	m.SendResponse("READY")
	m.status ="Playing: "+m.search_value

else if command = "VERSION" then 
	m.SendResponse("VERS")
	m.SendResponse(m.modelobject.GetModel()+" : "+m.modelobject.GetVersion())
	m.SendResponse("READY")


else if command = "PAUSE" then 
	if m.FileType = "AUDIO" or m.FileType = "VIDEO" then 
		m.SendResponse("PAUS")
		m.video.Pause()
		m.audio.Pause()
		m.SendResponse("READY")
		m.status ="Paused"
	else
		m.SendResponse("NoFl")	
	endif

else if command = "RESUME" then 
	if m.FileType = "AUDIO" or m.FileType = "VIDEO" then 
		m.SendResponse("RESU")
		m.video.Resume()
		m.audio.Resume()
		m.SendResponse("READY")
		m.status ="Playing: "+m.file_name
	else
		m.SendResponse("NoFl")	
	endif

else if m.command = "STATUS" then 
        m.SendResponse(m.status)
  
  
else if command = "LIST" then 	
	sdlist = ListDir("SD:")
	usblist = ListDir("USB1:")
	
	if sdlist.Count() > 0 then
		tmplist=sdlist
		if usblist.Count() > 0 then
			for each fl in usblist:tmplist.Addtail(fl):next
		endif
	else 
		tmplist=usblist
	endif
	
	if tmplist.Count() < 1 then
		m.SendResponse("No Files Found")
	else
		for each file in tmplist
			m.SendResponse(file)
		next
	endif
	
	m.SendResponse("READY")
	

	
'else if command = "LISTAV" then 	
'	tmplist = ListDir("/")
'	for each file in tmplist
	
'		if UCASE(right(file,3))="WMV" or UCASE(right(file,3))="MP4" or UCASE(right(file,3))="MOV" or UCASE(right(file,3))="VOB" or UCASE(right(file,3))="MPG" or UCASE(right(file,2))="TS" then
'			m.SendResponse(file)	
'		else if UCASE(right(file,3))="PNG" or UCASE(right(file,3))="JPG" or UCASE(right(file,3))="BMP" then
'			m.SendResponse(file)
'		else if UCASE(right(file,3))="MP3" or UCASE(right(file,3))="WAV" then
'			m.SendResponse(file)
'		endif
'	
'	next
'	m.SendResponse("READY")
		
else 
  
  m.ParseCommand(command)
  if m.command = "PLAY" then 
  	m.SendResponse("PLAY")
	m.loop_video=false
	m.loop_audio=false
		m.loop_attract=false
	m.loop_seamless=false
	m.lframe = true
	m.file_name=m.command_value
  	m.PlayFile(m.file_name)
	m.status ="Playing: "+m.file_name
	
  else if m.command = "PLAYCL" then
	m.loop_video=false
	m.loop_audio=false 
	m.loop_attract=false
	m.loop_seamless=false	
  	m.lframe=false
  	m.SendResponse("PLYC")
	m.file_name=m.command_value
	if m.file_name="" then m.file_name=m.search_value
  	m.PlayFile(m.file_name)
	m.status ="Playing: "+m.file_name
  
  else if m.command = "LOOP" then 
  	m.SendResponse("LOOP")
	m.loop_attract=false
	m.loop_seamless=false
	m.file_name=m.command_value
	m.GetFileType(m.file_name)
	if m.FileType = "VIDEO" then m.loop_video=true
	if m.FileType = "AUDIO" then m.loop_audio=true
  	m.PlayFile(m.file_name)
	m.status ="Looping: "+m.file_name
 
   else if m.command = "LOOPS" then 
  	m.SendResponse("LOOPS")
	m.file_name=m.command_value
	m.GetFileType(m.file_name)
	if m.FileType = "VIDEO" then m.loop_seamless=true
	m.loop_seamless=true
  	m.PlayFile(m.file_name)
	m.status ="Seamless Looping: "+m.file_name
  
  
  else if m.command = "SEARCH" then 
  	m.SendResponse("SRCH")
	m.search_value=m.command_value
  	m.SendResponse(m.FindFile(m.search_value))
	m.SendResponse("READY")
	
  else if m.command = "DELETE" then 
  	m.SendResponse("DELT")
	m.search_value=m.command_value
	
	if ucase(m.command_value) = "AUTORUN.BRS" then
		m.SendResponse("Autorun Delete Failed")
	else
		del_ok = DeleteFile(m.command_value)
	
		if del_ok then
				m.SendResponse("Deleted "+m.command_value)
		else
				m.SendResponse("Delete Failed")	
		endif
	endif
	
	m.SendResponse("READY")

else if m.command = "DELETEAUTORUN" then 
  	m.SendResponse("DELT")
	m.search_value=m.command_value
	
		del_ok = DeleteFile(m.command_value)
		if del_ok then
				m.SendResponse("Deleted "+m.command_value)
		else
				m.SendResponse("Delete Failed")	
		endif
	m.SendResponse("READY")
	

  else if m.command = "DOWNLOAD" then 
  	m.download_cmd_received=true
  	m.SendResponse("DWNL")
	m.settings.fullurl$=m.command_value
  	m.SendResponse("Downloading from "+m.settings.fullurl$)
	m.SendResponse("READY")
	m.SetDTimer()

else if m.command = "DOWNLOADSD" then 
	m.download_cmd_received=true
  	m.SendResponse("DWSD")
	m.settings.fullurl$=m.command_value
	m.settings.storage$="SD:"
  	m.SendResponse("Downloading from "+m.settings.fullurl$)
	m.SendResponse("READY")
	m.SetDTimer()

else if m.command = "DOWNLOADUSB" then 
	m.download_cmd_received=true
  	m.SendResponse("DWUSB")
	m.settings.fullurl$=m.command_value
	m.settings.storage$="USB1:"
  	m.SendResponse("Downloading from "+m.settings.fullurl$)
	m.SendResponse("READY")
	m.SetDTimer()
	
  else if m.command = "SETWEBFOLDER" then 
  	m.SendResponse("WEBF")
	m.settings.folderurl$=m.command_value
	m.settings.fullurl$=" "
  	if m.debug then m.SendResponse("Download Location changed to: "+m.settings.folderurl$)
	m.SendResponse("READY")
	
  else if m.command = "VOLUME" then 
  	m.SendResponse("VOLM")
  	m.audio.SetVolume(val(m.command_value))
  	m.video.SetVolume(val(m.command_value))
	m.current_volume=val(m.command_value)
	m.SendResponse("READY")
  
  else if m.command = "VVOLUME" then 
  	m.SendResponse("VVOL")
  	m.video.SetVolume(val(m.command_value))
	m.SendResponse("READY")
  
  else if m.command = "AVOLUME" then 
  	m.SendResponse("AVOL")
  	m.audio.SetVolume(val(m.command_value))
	m.SendResponse("READY")
  
  else if m.command = "VIEWMODE" then 
  	m.SendResponse("VMDE")
  	m.video.SetViewMode(val(m.command_value))
	m.SendResponse("READY")

  else if m.command = "VIDEOMODE" then 
  	m.SendResponse("Videomode Disabled")
  	'm.audio.Stop()
  	'm.video.Stop()
  	'm.mode.SetMode(m.command_value)
  else
  	m.SendResponse("INVL")
  endif
endif

End Sub


Function NewControl(settings As Object) As Object
control = CreateObject("roAssociativeArray")
control.mode=CreateObject("roVideoMode")
control.msgport=CreateObject("roMessagePort")

control.video=CreateObject("roVideoPlayer")
control.audio=CreateObject("roAudioPlayer")
control.image=CreateObJect("roImagePlayer")
control.modelObject = CreateObject("roDeviceInfo")
control.serialon=false
control.networkon=false


if control.modelObject.GetModel() = "HD410" or  control.modelObject.GetModel() = "HD810" or control.modelObject.GetModel() = "HD1010" or ucase(control.modelObject.GetModel()) = "HD1010W" then 
	control.serial=CreateObject("roSerialPort", 0, settings.serialPortSpeed)
	control.serial.SetMode(settings.serialPortMode$)
	control.serialOn=true
	control.serial.SetLineEventPort(control.msgport)
endif

if ucase(control.modelObject.GetModel()) = "HD1010W" or ucase(control.modelObject.GetModel()) = "HD210W" or control.modelObject.GetModel() = "HD210" or control.modelObject.GetModel() = "HD1010" then 
	control.udp=CreateObject("roDatagramReceiver", settings.udpPortReceive)
	control.udpSender = CreateObject("roDatagramSender")
	control.udpSender.SetDestination(settings.udpDestinationAddress$, settings.udpPortSend)
	control.networkOn=true
	control.udp.SetPort(control.msgport)
	if settings.ManualIp then
		nc = CreateObject("roNetworkConfiguration", 0)
		nc.SetIP4Address(settings.IPAddress$)
		nc.SetIP4Netmask(settings.Subnet$)
		nc.SetIP4Broadcast(settings.Broadcast$)
		nc.SetIP4Gateway(settings.Gateway$)
		if settings.DNS1$ <> "" then nc.AddDNSServer(settings.DNS1$)
		if settings.DNS2$ <> "" then nc.AddDNSServer(settings.DNS2$)
		if settings.DNS3$ <> "" then nc.AddDNSServer(settings.DNS3$)

		'nc.SetDomain("mshome.comcast.net") 'set whatever your domain is
		'nc.SetTimeServer("") 'Set Time server here, add address inside quotes

		 nc.Apply()
		 nc=0
	else
		nc = CreateObject("roNetworkConfiguration", 0)
		nc.SetDHCP()
		nc=0
	endif

endif

control.settings=settings
'control.kb=CreateObject("roKeyboard")		'comment out


'control.kb.SetPort(control.msgport)	'comment out
control.video.SetPort(control.msgport)
control.audio.SetPort(control.msgport)
control.video.SetAudioOutput(control.settings.audiooutput)

control.txfer=createobject("roUrlTransfer")
control.fxfer=createobject("roUrlTransfer")
control.txfer.SetURL(settings.folderurl$+settings.download_list$)
control.fxfer.SetPort(control.msgport)
control.txfer.SetPort(control.msgport)
control.havelist=false
control.count=0
control.maxfiles=0

control.ProcessCommand=ProcessCommand
control.ParseCommand=ParseCommand
control.PlayFile=PlayFile
control.PlayAttract=PlayAttract
control.StripSpaces=StripSpaces
control.FindFile=FindFile
control.SendResponse=SendResponse
control.Listen=Listen
'control.kbListen=kbListen		'comment out
control.ResetVar=ResetVariables
control.PlayAllFiles=PlayFiles
control.GetFileType = GetFileType

control.Playlist=CreateObject("roAssociativeArray")
control.PlayAll=createobject("roList")
control.loop_video=false
control.loop_audio=false
control.loop_seamless=false
control.ext_included=false

'control.kbstring=""	'comment out
control.command=""
control.command_value=""
control.file_name=""
control.Status = "Ready"
control.search_value="No File"
control.debug=settings.debug
control.lframe = false
control.Timer=0
control.MEDEN=8
control.fileType="No FIle"
control.current_volume=100
control.timeout=0
control.allplay=false
control.loop_attract=false
control.attract$ = settings.attract$
control.mode.SetMode(settings.videoMode$)
control.ID=settings.ID 'attached before each brightsign response along with "BS"
control.DownloadActive=false
control.current_download$=""
control.dchecklist=createobject("roAssociativeArray")
control.SetDTimer=SetDTimer
control.GetText=GetText
control.GetFiles=GetFiles
control.download_cmd_received=false
control.HandleTxferEvent=HandleTxferEvent
control.HandleFxferEvent=HandleFxferEvent

	control.dTimer = CreateObject("roTimer")
	control.systemTime = CreateObject("roSystemTime")
	control.tempTimeout = control.systemTime.GetLocalDateTime()
	control.tempTimeout.AddSeconds(120)
	control.dTimer.SetDateTime(control.tempTimeout)
	control.dTimer.SetPort(control.msgPort)
	control.dTimer.Start()
				
return control

End Function


REM Not used
Sub GetVideos()

tmplist = ListDir("/")
for each video in tmplist
	if right(video,3)="MP4" or right(video,3)="WMV" or right(video,3)="MOV" or right(video,3)="VOB" or right(video,3)="MPG" or right(video,2)="TS" then
		m.Playlist.AddReplace(video,1)
	endif
next

End Sub


REM Not used
Sub PlayFiles()

m.PlayAll = ListDir("/")
'tmplist = ListDir("/")
'tmpStrCount = 0
'for each file in tmplist
'	if right(file,3)="VOB" or right(file,3)="MPG" or right(file,2)="TS" then
		rem m.Playlist.AddReplace(Str(tmpStrCount),"v"+file)
'		m.PlayFile(file)
'	endif
	
'	if right(file,3)="JPG" or right(file,3)="BMP" or right(file,3)="PNG" then
'		rem m.Playlist.AddReplace(Str(tmpStrCount),"i"+file)
'		m.PlayFile(file)
'		sleep(3000)
'	endif
	
'	if right(file,3)="MP3" or right(file,3)="WAV" then
'		rem m.Playlist.AddReplace(Str(tmpStrCount),"a"+file)
'		m.PlayFile(file)		
'	endif
'	tmpStrCount = tmpStrCount+1
	
'next

End Sub


REM command syntax is <command><space><filename or setting>
Sub ParseCommand(command As String)
'command = StripSpaces(command)
 	bl_position=instr(1, command, chr(32))
	if m.debug m.sendResponse(str(bl_position))
	if bl_position > 0 then 
		m.command_value = mid(command,bl_position+1)
		m.command = left(command, bl_position-1)
	else 
		m.command=""
		m.command_value=""
	endif
	if m.debug m.sendResponse(m.command+":"+m.command_value)
command=""
End Sub


Function FindFile(searchString As String) As String
	response="NoFl"
	temp_list=matchfiles(".", searchString)
	if m.debug then m.sendResponse(str(temp_list.Count()))
	if temp_list.Count() > 0 then 
		response = searchString
	else
		temp_list=matchfiles("USB1:", searchString)
		if temp_list.Count() > 0 then response = searchString
	endif

	m.search_value=response
	return(m.search_value)	

End Function

Sub GetFileType(file As String) as Void
	if right(file,3)="MP4" or right(file,3)="WMV" or right(file,3)="MOV" or right(file,3)="VOB" or right(file,3)="MPG" or right(file,2)="TS" then
		m.FileType = "VIDEO"
	else if right(file,3)="PNG" or right(file,3)="JPG" or right(file,3)="BMP" then
		m.FileType = "IMAGE"
	else if right(file,3)="MP3" or right(file,3)="WAV" then
		m.FileType = "AUDIO"
	else
		m.FileType = "NoFl"
	endif
End Sub
	

Function StripSpaces(command As String) As String
   leadspaces=true
   trailspaces=true

while (leadspaces or trailspaces)
   strip_space:
	if left(command,1) = chr(32) then 
		command=right(command, len(command)-1)
	else 
		leadspaces=false
	endif

	if right(command,1) = chr(32) then 
		command=left(command, len(command)-1)
	else
		trailspaces=false
	endif
end while

   return command
End Function


Sub SendResponse(rCode as String)
	if m.serialOn then m.serial.SendLine(rCode+chr(10))
	if m.ID = 0 then
		if m.networkOn then m.udpSender.Send(rcode+chr(10))		
	else
		if m.networkOn then m.udpSender.Send("BS"+mid(str(m.ID),2)+" "+rcode+chr(10))
	endif
	'print rCode
End Sub


Sub ResetVariables()
m.command=""
m.command_value=""
m.file_name=""
m.status="Ready"
m.fileType="No File"
End Sub



Sub GetText(dcount as Integer)
m.maxfiles=0
if m.debug m.sendresponse("GetText() Function")
m.txfer.AsyncCancel()
if m.settings.fullurl$ <> " " then 
	m.txfer.SetUrl(m.settings.fullurl$) 
else
	m.txfer.SetUrl(m.settings.folderurl$+m.settings.download_list$) 
endif
if not m.txfer.AsyncGetToFile(m.settings.storage$+"mydownloads.txt") then
	m.sendresponse("Can't Reach download list. Retry...")
	if dcount > 3 then return
	m.GetText(dcount + 1)
endif
m.dchecklist.Clear()
if m.debug m.sendresponse("Initiated download of downloads list..")

End Sub


Sub GetFiles()
'read through file
'get line which equals video name
if m.debug m.sendresponse("GetFiles() function")

if m.havelist then 
	m.fxfer.AsyncCancel()
    

	While true
		if m.count > 1 then
			if m.count >= m.maxfiles then exit while
		endif
		if m.maxfiles > 0 then 
			current_file$ = m.settings.dlist[m.count]
			m.current_download$=current_file$
			m.dchecklist.AddReplace(current_file$,"0")
			if m.debug then m.sendresponse(m.settings.folderurl$ +current_file$)
			m.fxfer.SetUrl(m.settings.folderurl$+current_file$)
			if not m.fxfer.AsyncGetToFile(m.settings.storage$+current_file$) then
				'fxfer=0
				m.GetFiles()
			else
				m.downloadActive=true
				m.dchecklist.AddReplace(current_file$,"1") 
				exit while
			endif
		endif
		
	end while
endif

End Sub


Sub HandleFxferEvent (msg as Object)
if m.debug m.sendresponse("HandleFxferEvent function")
if msg.GetSourceIdentity() = m.fxfer.GetIdentity() then 
		if m.debug m.sendresponse(str(msg.getint()) + " / "+ str(msg.getresponsecode()))
		
		if msg.GetInt() = 1 then
			if msg.GetResponseCode() = 200 then
				'download complete
				m.dchecklist.AddReplace(m.current_download$,"200")
				if m.debug m.sendresponse(m.settings.dlist[m.count] + " downloaded successfully.")
				m.count=m.count+1
				m.downloadActive=false
				if ucase(m.current_download$) = "AUTORUN.BRS" then
					m.sendresponse("Rebooting, new Autorun")
					RebootSystem()
				endif
				
				tdlistcount=0
				for each item in m.dchecklist
					If m.dchecklist.Lookup(item) = "200" then tdlistcount=tdlistcount+1
				next
				m.sendresponse(str(tdlistcount)+" of "+ str(m.maxfiles) + " files downloaded successfully.")
				
				if tdlistcount < m.maxfiles then m.GetFiles()
				tdlistcount=0
			else
				if m.debug m.sendresponse("Download Server Resposne: "+ msg.GetFailureReason())
				m.dchecklist.AddReplace(m.current_download$,msg.GetFailureReason())
			endif
		endif
	endif
End Sub


Sub HandleTxferEvent (msg as Object)
if m.debug then m.sendresponse("HandleTxferEvent function")

if msg.GetSourceIdentity() = m.txfer.GetIdentity() then 
	if m.debug m.sendresponse(str(msg.getint()) + " / "+ str(msg.getresponsecode()))
	
	if msg.GetInt() = 1 then
		if msg.GetResponseCode() = 200 then
			'download complete
			m.havelist=true
			if m.debug m.sendresponse("Download_list received")
			
			mylist=createobject("roReadFile", m.settings.storage$+"mydownloads.txt")

			if type(mylist) = "roReadFile" then

				if m.debug m.sendresponse("Download_list confirmed")
				While not mylist.AtEof()
					current_file$ = mylist.ReadLine()
					if ucase(right(current_file$,3)) = "WMV" or ucase(right(current_file$,3)) = "MP4" or ucase(right(current_file$,3)) = "MOV" or ucase(right(current_file$,3)) = "MPG" or ucase(right(current_file$,3)) = "WMV" or ucase(right(current_file$,2)) = "TS" or ucase(right(current_file$,3)) = "VOB" or ucase(right(current_file$,3)) = "JPG" or ucase(right(current_file$,3)) = "BMP" or ucase(right(current_file$,3)) = "BRS" then 
						m.settings.dlist[m.maxfiles]=current_file$
						m.maxfiles=m.maxfiles+1
					endif
				end while
	
				m.havelist=true
				if m.debug then m.sendresponse("Files found: "+str(m.maxfiles))
				m.count=0
				m.GetFiles()
			
			else
				m.GetText(0)
			endif
		endif
	endif
endif

End Sub

Sub SetDTimer()
	if type(m.dTimer) <> "roTimer" then m.dTimer = CreateObject("roTimer")
	m.systemTime = CreateObject("roSystemTime")
	m.tempTimeout = m.systemTime.GetLocalDateTime()
	m.tempTimeout.AddSeconds(5)
	m.dTimer.SetDateTime(m.tempTimeout)
	m.dTimer.SetPort(m.msgPort)
	m.dTimer.Start()
End Sub


'6-13-10
'added attract loop support
'added settings at top of script
'added reboot command

' **** 7-13-10
'added settings for network configuration

' **** 7-26-10
'added settings.ID to that you can use the same UDP receive and send ports. All outgoing status messages include ID in text"
'the unit ignores udp messages with the brightsign's ID in the name. 

' **** 8-23-10
'Added LOOPS - loop seamlessly

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
