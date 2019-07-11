while(True){

while(!FileExist("Y:\*.png")){
	Sleep 300
}

if WinExist("BERNINA-"){
	WinActivate

	type = 0

	if FileExist("Y:\1.png"){
		type = 1
	}

	if FileExist("Y:\2.png"){
		type = 2
	}

	if FileExist("Y:\3.png"){
		type = 3
	}

	if FileExist("Y:\4.png"){
		type = 4
	}

	CoordMode, Mouse, Client
	Sleep 100
	; Create New Project
	Send ^n 
	Sleep 600
	
	; Set Hoop Settings
	MouseMove, 1524, 85
	Click
	Sleep 100
	MouseMove, 668, 72
	Click
	Sleep 100
	MouseMove, 370, 285
	Click
	Sleep 100
	MouseMove, 370, 430
	Click
	Sleep 100
	MouseMove, 74, 593
	Click
	Sleep 100
	Send {Enter}
	Sleep 300

	; Insert Image 
	MouseMove, 692, 25
	Click
	Sleep 300
	MouseMove, 692, 77
	Click
	Sleep 300
	MouseMove, 230, 32
	Click
	Sleep 300
	Send Y:\ {Enter}
	Sleep 300
	MouseMove, 372, 214
	Click, 2
	Sleep 600

	; AutoDigitize
	MouseMove, 105, 326
	Click
	Sleep 100
	MouseMove, 105, 737
	Click
	Sleep 100
	MouseMove, 1120, 827
	Click, 2
	Send 2
	Send {Enter}
	Sleep 400
	MouseMove, 829, 207
	Click
	Sleep 100
	MouseMove, 829, 288
	Click
	Sleep 100
	MouseMove, 1610, 735
	Click
	Sleep 400
	MouseMove, 94, 1755
	Click
	Sleep 100
	
	; Delete Background
	MouseMove 3670, 575
	Click, 2
	Sleep 200
	Send {Del}

	; Set Outline Type

	if(type != 0){
	
		Send ^a

		if(type == 1){
		MouseMove, 177, 2130
		Click
		Sleep 100
		}

		if(type == 2){
		MouseMove, 480, 2130
		Click
		Sleep 100
		}

		if(type == 3){
		MouseMove, 240, 2130
		Click
		Sleep 100
		}

		if(type == 4){
		MouseMove, 530, 2130
		Click
		Sleep 100
		}

	}

	; Close Current Project
	MouseMove, 60, 25
	Click
	Sleep 100
	MouseMove, 60, 267
	Click
	Sleep 100
	Send {Enter}
	Sleep 100
	MouseMove, 230, 89
	Click
	Sleep 100
	Send Y:\
	Send {Enter}
	Sleep 200
	MouseMove, 270, 608
	Click
	Sleep 100
	Send Output
	Sleep 200
	Send {Enter}
	Sleep 500
	Send #d
	FileDelete, Y:\*.png
}
	


}

