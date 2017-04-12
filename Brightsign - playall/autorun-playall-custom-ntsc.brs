
VideoResolution$="ntsc-m"

tmpfile = createobject("roReadFile", "playlogcount.txt")
if type(tmpfile) <> "roReadFile" then
	newFile = CreateObject("roCreateFile", "playlogcount.txt")
	newFile.SendLine("Starting gpio capture")
	newFile.Flush()
else
	newFile = CreateObject("roAppendFile", "playlogcount.txt")
endif

v=CreateObject("roVideoPlayer")
p=createobject("roMessagePort")
v.SetPort(p)
v.SetVolume(50)

mode = CreateObject("roVideoMode")
mode.SetMode(VideoResolution$)


playcount=0
count=0
countFound=0
countMax=100
DIM mylist[countMax]

read:
list=ListDir("/")

for each file in list
	if ucase(right(file,3)) = "MPG" or ucase(right(file,3)) = "VOB" or ucase(right(file,2)) = "TS" then 
		mylist[countFound]=file
		countFound=countFound+1
	endif
next

print countFound
 
play:
v.PlayFile(mylist[count])
playcount=playcount+1

newFile.SendLine(str(playcount)+" playing "+ mylist[count])
newFile.Flush()

loop:
	msg=wait(0,p)
if type(msg) = "roVideoEvent" then
		if msg.GetInt() = 8 then
			if count = countFound-1 then
				count=0
			else
				count = count+1
			endif
			goto play
		endif
	endif
	
goto loop