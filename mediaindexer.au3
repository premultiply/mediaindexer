#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

Opt("TrayIconHide", 1)

If $CmdLine[0] > 0 Then
	Select
		Case $CmdLine[1] = "filmstrip"
			Local $INSTANCE_TYPE = $CmdLine[1]
			Local $INSTANCE_EXT = "jpg"
		Case $CmdLine[1] = "waveform"
			Local $INSTANCE_TYPE = $CmdLine[1]
			Local $INSTANCE_EXT = "gif"
		Case $CmdLine[1] = "r128sum"
			Local $INSTANCE_TYPE = $CmdLine[1]
			Local $INSTANCE_EXT = "r128sum"
		Case $CmdLine[1] = "r128log"
			Local $INSTANCE_TYPE = $CmdLine[1]
			Local $INSTANCE_EXT = "r128log"
		Case $CmdLine[1] = "xmlinfo"
			Local $INSTANCE_TYPE = $CmdLine[1]
			Local $INSTANCE_EXT = "xml"
		Case $CmdLine[1] = "jsoninfo"
			Local $INSTANCE_TYPE = $CmdLine[1]
			Local $INSTANCE_EXT = "json"
		Case $CmdLine[1] = "mxfinfo"
			Local $INSTANCE_TYPE = $CmdLine[1]
			Local $INSTANCE_EXT = "xml"
		Case Else
			ConsoleWriteError("Wrong instance type parameter." & @CRLF)
			ConsoleWriteError("Supported instance types are [filmstrip, waveform, r128sum, r128log, xmlinfo, jsoninfo, mxfinfo]." & @CRLF)
			Exit
	EndSelect
Else
	ConsoleWriteError("Instance type parameter is missing." & @CRLF)
	Exit
EndIf

ConsoleWriteError($INSTANCE_TYPE & @CRLF)


Global $TempDir 			= IniRead(@ScriptDir & "\config.ini",	"general",	"TempDir",				@TempDir & "\"				)
Local $SourcePattern 		= IniRead(@ScriptDir & "\config.ini",	"general",	"SourceDir", 			@ScriptDir & "\input\" 		) & "*.*"
Local $DestinationPattern 	= IniRead(@ScriptDir & "\config.ini",	"general",	"DestinationDir",		@ScriptDir & "\output\"		) & "*." & $INSTANCE_EXT
Local $DisableRemoval		= IniRead(@ScriptDir & "\config.ini",	"general",	"DisableRemoval",		0)
Local $IgnoreMissingFrames	= IniRead(@ScriptDir & "\config.ini",	"general",	"IgnoreMissingFrames",	0)

ConsoleWriteError($TempDir & @CRLF)
ConsoleWriteError($SourcePattern & @CRLF)
ConsoleWriteError($DestinationPattern & @CRLF)


#include <mi_include.au3>
#include <File.au3>
#include <Array.au3>
#include <Math.au3>
#include <TrayConstants.au3>
#include <FileConstants.au3>


Local $SourceDrive, $SourceDir, $SourceFileName, $SourceExtension
Local $DestinationDrive, $DestinationDir, $DestinationFileName, $DestinationExtension
_PathSplit($SourcePattern, $SourceDrive, $SourceDir, $SourceFileName, $SourceExtension)
_PathSplit($DestinationPattern, $DestinationDrive, $DestinationDir, $DestinationFileName, $DestinationExtension)

Local $hSearch = -1


; Shows the filenames of all files in the current directory.
While 1
	ConsoleWriteError($INSTANCE_TYPE & @CRLF)

	ConsoleWriteError("Entering search loop." & @CRLF)
	Local $hSearch = FileFindFirstFile($SourcePattern)

	; Check if the search was successful
	If $hSearch <> -1 Then
		While 1
			Local $currSource = $SourceDrive & $SourceDir & FileFindNextFile($hSearch)
			If @error Then ExitLoop ;FileFindNextFile()

			Local $currDrive, $currDir, $currFileName, $currExtension
			_PathSplit($currSource, $currDrive, $currDir, $currFileName, $currExtension)
			Local $currDestination = $DestinationDrive & $DestinationDir & $currFileName & $DestinationExtension

			If CheckCompare($currSource, $currDestination) Then
				ConsoleWriteError($currDestination & " is not found or is outdated. Creating or updating from " & $currSource & @CRLF)
				Select
					Case $INSTANCE_TYPE = "filmstrip"
						Filmstrip($currSource, $currDestination, StringCompare(".mxf", $currExtension) = 0)
					Case $INSTANCE_TYPE = "waveform"
						If Not RunFFMPEG_Waves($currSource, $currDestination, False) Then
							RunFFMPEG_Waves($currSource, $currDestination, True)
						EndIf
					Case $INSTANCE_TYPE = "r128sum"
						If Not RunFFMPEG_EBUR128sum($currSource, $currDestination, False) Then
							RunFFMPEG_EBUR128sum($currSource, $currDestination, True)
						EndIf
					Case $INSTANCE_TYPE = "r128log"
						If Not RunFFMPEG_EBUR128log($currSource, $currDestination, False) Then
							RunFFMPEG_EBUR128log($currSource, $currDestination, True)
						EndIf
					Case $INSTANCE_TYPE = "xmlinfo"
						RunFFPROBE_XML($currSource, $currDestination)
					Case $INSTANCE_TYPE = "jsoninfo"
						RunFFPROBE_JSON($currSource, $currDestination)
					Case $INSTANCE_TYPE = "mxfinfo"
						RunMXF2RAW($currSource, $currDestination)
				EndSelect
				CopyTimeProps($currSource, $currDestination)
			EndIf
		WEnd
	EndIf

	; Close the search handle
	FileClose($hSearch)
	ConsoleWriteError("FileSearch loop done." & @CRLF)

	If $DisableRemoval <> 1 Then
		ConsoleWriteError("Entering deletion loop." & @CRLF)
		Local $hSearch = FileFindFirstFile($DestinationPattern)

		; Check if the search was successful
		If $hSearch <> -1 Then
			While 1
				Local $currDestination = $DestinationDrive & $DestinationDir & FileFindNextFile($hSearch)
				If @error Then ExitLoop ;FileFindNextFile()

				Local $currDrive, $currDir, $currFileName, $currExtension
				_PathSplit($currDestination, $currDrive, $currDir, $currFileName, $currExtension)
				Local $currSource = $SourceDrive & $SourceDir & $currFileName & ".*"

				If Not FileExistsWildcard($currSource) Then
					ConsoleWriteError($currSource & " has gone. Removing " & $currDestination & @CRLF)
					FileDelete($currDestination)
				EndIf
			WEnd
		EndIf

		; Close the search handle
		FileClose($hSearch)
		ConsoleWriteError("Finished deletion loop." & @CRLF)
	Else
		ConsoleWriteError("File removal disabled by configuration." & @CRLF)
	EndIf


	Sleep(10000)
WEnd


Func Filmstrip($file, $target, $MXFfile = False)
	If $MXFfile Then
		Local $duration = RunBMXTransWrap_GetDuration($file)
	Else
		Local $duration = RunFFMPEG_GetDuration($file)
	EndIf
	If $duration > 0 Then
		Local $successful = 0
		If $MXFfile Then
			$duration -= 1 ;0-based Frame position
			$successful += Int(RunBMXTransWrap_PosFrame($file,  0, 0))
			$successful += Int(RunBMXTransWrap_PosFrame($file,  1, $duration * 0.1))
			$successful += Int(RunBMXTransWrap_PosFrame($file,  2, $duration * 0.2))
			$successful += Int(RunBMXTransWrap_PosFrame($file,  3, $duration * 0.3))
			$successful += Int(RunBMXTransWrap_PosFrame($file,  4, $duration * 0.4))
			$successful += Int(RunBMXTransWrap_PosFrame($file,  5, $duration * 0.5))
			$successful += Int(RunBMXTransWrap_PosFrame($file,  6, $duration * 0.6))
			$successful += Int(RunBMXTransWrap_PosFrame($file,  7, $duration * 0.7))
			$successful += Int(RunBMXTransWrap_PosFrame($file,  8, $duration * 0.8))
			$successful += Int(RunBMXTransWrap_PosFrame($file,  9, $duration * 0.9))
			$successful += Int(RunBMXTransWrap_PosFrame($file, 10, $duration))
		Else
			$successful += Int(RunFFMPEG_PosFrame($file,  0, 0))
			$successful += Int(RunFFMPEG_PosFrame($file,  1, $duration * 0.1))
			$successful += Int(RunFFMPEG_PosFrame($file,  2, $duration * 0.2))
			$successful += Int(RunFFMPEG_PosFrame($file,  3, $duration * 0.3))
			$successful += Int(RunFFMPEG_PosFrame($file,  4, $duration * 0.4))
			$successful += Int(RunFFMPEG_PosFrame($file,  5, $duration * 0.5))
			$successful += Int(RunFFMPEG_PosFrame($file,  6, $duration * 0.6))
			$successful += Int(RunFFMPEG_PosFrame($file,  7, $duration * 0.7))
			$successful += Int(RunFFMPEG_PosFrame($file,  8, $duration * 0.8))
			$successful += Int(RunFFMPEG_PosFrame($file,  9, $duration * 0.9))
			$successful += Int(RunFFMPEG_PosFrame($file, 10, _Max($duration - 10.0, 0), True))
		EndIf
		If $successful = 11 Or $IgnoreMissingFrames = 1 Then ; All frames extracted?
			RunFFMPEG_StackFrames($TempDir & "temp%02d.bmp", $target)
		EndIf
		FileDelete($TempDir & "temp??.bmp")
	EndIf
EndFunc   ;==>Filmstrip