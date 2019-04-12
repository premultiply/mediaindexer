#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <AutoItConstants.au3>
#include <StringConstants.au3>
#include <FileConstants.au3>
#include <File.au3>


Global Const $FFPROBE_EXE = @ScriptDir & "\ffprobe.exe"
Global Const $FFPROBE_OPTS = " -loglevel level+quiet"

Global Const $FFMPEG_EXE = @ScriptDir & "\ffmpeg.exe"
Global Const $FFMPEG_OPTS = " -hide_banner -nostdin -nostats -probesize 16M"
;Global Const $FFMPEG_OPTS = " -hide_banner -nostdin -nostats -analyzeduration 9223372036854775807 -probesize 9223372036854775807"

Global Const $MXF2RAW_EXE = @ScriptDir & "\mxf2raw.exe"

Global Const $BMXTRANSWRAP_EXE = @ScriptDir & "\bmxtranswrap.exe"

Global Const $IMG_WIDTH = 2048


Func RunFFPROBE_JSON($file, $destination)
	Local $cmdline = $FFPROBE_EXE & $FFPROBE_OPTS & " -show_format -show_programs -show_streams -show_chapters -show_error -print_format json """ & $file & """"
	$hFFmpeg = Run($cmdline, @ScriptDir, @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($hFFmpeg)
	Local $lFFmpeg = StdoutRead($hFFmpeg)
	StdioClose($hFFmpeg)
	If $lFFmpeg Then
		FileDelete($destination)
		Return FileWrite($destination, $lFFmpeg)
	Else
		Return False
	EndIf
EndFunc   ;==>RunFFPROBE_JSON


Func RunFFPROBE_XML($file, $destination)
	Local $cmdline = $FFPROBE_EXE & $FFPROBE_OPTS & " -show_format -show_programs -show_streams -show_chapters -show_error -print_format xml """ & $file & """"
	$hFFmpeg = Run($cmdline, @ScriptDir, @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($hFFmpeg)
	Local $lFFmpeg = StdoutRead($hFFmpeg)
	StdioClose($hFFmpeg)
	If $lFFmpeg Then
		FileDelete($destination)
		Return FileWrite($destination, $lFFmpeg)
	Else
		Return False
	EndIf
EndFunc   ;==>RunFFPROBE_XML


Func RunFFPROBE_GetDuration($file)
	Local $cmdline = $FFPROBE_EXE & $FFPROBE_OPTS & " -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 """ & $file & """"
	$hFFmpeg = Run($cmdline, @ScriptDir, @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($hFFmpeg)
	Local $lFFmpeg = StdoutRead($hFFmpeg)
	StdioClose($hFFmpeg)
	;ConsoleWriteError($lFFmpeg & @CRLF)
	Return $lFFmpeg
EndFunc   ;==>RunFFPROBE_GetDuration


Func RunFFMPEG_GetDuration($file)
	Local $cmdline = $FFMPEG_EXE & $FFMPEG_OPTS & " -i """ & $file & """"
	$hFFmpeg = Run($cmdline, @ScriptDir, @SW_HIDE, $STDERR_CHILD)
	ProcessWaitClose($hFFmpeg)
	Local $lFFmpeg = StderrRead($hFFmpeg)
	StdioClose($hFFmpeg)
	Local $duration_time = 0
	Local $duration = StringRegExp($lFFmpeg, 'Duration: (\d+):(\d+):(\d+\.\d+),', $STR_REGEXPARRAYMATCH)
	;ConsoleWriteError($lFFmpeg & @CRLF)
	If IsArray($duration) Then
		$duration_time = ($duration[0] * 3600) + ($duration[1] * 60) + ($duration[2])
		Return $duration_time
	EndIf
	Return -1
EndFunc   ;==>RunFFMPEG_GetDuration


Func RunBMXTransWrap_GetDuration($file)
	Local $cmdline = $BMXTRANSWRAP_EXE & " -t op1a --start 9223372036854775807 --dur 0 --check-end --check-complete --disable-audio --disable-data """ & $file & """"
	Local $hBMXTransWrap = Run($cmdline, @ScriptDir, @SW_HIDE, $STDERR_CHILD)
	ProcessWaitClose($hBMXTransWrap)
	Local $lBMXTransWrap = StderrRead($hBMXTransWrap)
	StdioClose($hBMXTransWrap)
	Local $duration_frames = 0
	Local $duration = StringRegExp($lBMXTransWrap, 'input duration (\d+)', $STR_REGEXPARRAYMATCH)
	;ConsoleWriteError($lBMXTransWrap & @CRLF)
	If IsArray($duration) Then
		$duration_frames = $duration[0]
		Return $duration_frames
	EndIf
	Return -1
EndFunc   ;==>RunBMXTransWrap_GetDuration


Func RunBMXTransWrap_PosFrame($file, $pos, $duration)
	Local $cmdline = $BMXTRANSWRAP_EXE & " --log-level 0 -t op1a --start " & Round($duration) & " --dur 1 --check-complete -o """ & $TempDir & "temp" & StringFormat("%02i", $pos) & ".mxf"" --disable-audio --disable-data """ & $file & """"
	If RunWait($cmdline, @ScriptDir, @SW_HIDE) = 0 Then
		Local $retcode = RunFFMPEG_PosFrame($TempDir & "temp" & StringFormat("%02i", $pos) & ".mxf", $pos, 0, True)
		FileDelete($TempDir & "temp" & StringFormat("%02i", $pos) & ".mxf")
		Return $retcode
	EndIf
	Return False
EndFunc   ;==>RunBMXTransWrap_PosFrame


Func RunFFMPEG_PosFrame($file, $pos = 0, $duration = 0, $reverse = False)
	Local $cmdline = $FFMPEG_EXE & $FFMPEG_OPTS & " -loglevel quiet" & (($duration > 0) ? (" -ss " & $duration) : "") & " -i """ & $file & """ -an -vsync 0 -vf " & ($reverse ? "reverse," : "") & "scale=dar*ih/2:ih/2 -vframes 1 -y """ & $TempDir & "temp" & StringFormat("%02i", $pos) & ".bmp"""
	Return RunWait($cmdline, @ScriptDir, @SW_HIDE) = 0
EndFunc   ;==>RunFFMPEG_PosFrame


Func RunFFMPEG_StackFrames($sourcepattern, $destination)
	Local $cmdline = $FFMPEG_EXE & $FFMPEG_OPTS & " -loglevel quiet -i """ & $sourcepattern & """ -vf tile=11x1:color=lime,scale=" & $IMG_WIDTH & ":-1 -qscale:v 5 -y """ & $destination & """"
	Return RunWait($cmdline, @ScriptDir, @SW_HIDE) = 0
EndFunc   ;==>RunFFMPEG_StackFrames


;~ Func RunFFMPEG_Audio($file, $destination1, $destination2, $destination3, $singleAudioTrack = True)
;~ 	Local $cmdline = $FFMPEG_EXE & $FFMPEG_OPTS & " -loglevel level+verbose -i """ & $file & """ -vn -filter_complex:a """ & (($singleAudioTrack) ? "pan=stereo|c0=c0|c1=c1," : "amerge=inputs=2,") & "ebur128=peak=true:framelog=verbose,showwavespic=s=" & $IMG_WIDTH & "x64:colors=white:scale=log,negate"" -y """ & $destination1 & """"
;~ 	$hFFmpeg = Run($cmdline, @ScriptDir, @SW_HIDE, $STDERR_CHILD)
;~ 	ProcessWaitClose($hFFmpeg)
;~ 	Local $lFFmpeg = StderrRead($hFFmpeg)
;~ 	StdioClose($hFFmpeg)
;~ 	$array2 = StringRegExp($lFFmpeg, "(?s)time=[:\.\d]+.*\[Parsed_ebur128_.*\] \[info\] Summary:[\r\n]*([^\[]*)", $STR_REGEXPARRAYMATCH)
;~ 	$array3 = StringRegExp($lFFmpeg, "\[Parsed_ebur128_.*\] \[verbose\] (?=t: )([^\[]*)", $STR_REGEXPARRAYGLOBALMATCH)
;~ 	If IsArray($array2) And IsArray($array3) Then
;~ 		FileDelete($destination2)
;~ 		FileWrite($destination2, $array2[0])
;~ 		FileDelete($destination3)
;~ 		FileWrite($destination3, _ArrayToString($array3, @CRLF))
;~ 	Else
;~ 		Return False
;~ 	EndIf
;~ EndFunc   ;==>RunFFMPEG_Audio


Func RunFFMPEG_Waves($file, $destination, $singleAudioTrack = True)
	Local $cmdline = $FFMPEG_EXE & $FFMPEG_OPTS & " -loglevel quiet -i """ & $file & """ -vn -filter_complex:a """ & (($singleAudioTrack) ? "pan=stereo|c0=c0|c1=c1," : "amerge=inputs=2,") & "showwavespic=s=" & $IMG_WIDTH & "x64:colors=white:scale=log,negate"" -frames:v 1 -y """ & $destination & """"
	Return RunWait($cmdline, @ScriptDir, @SW_HIDE) = 0
EndFunc   ;==>RunFFMPEG_Waves


Func RunFFMPEG_EBUR128log($file, $destination, $singleAudioTrack = True)
	Local $cmdline = $FFMPEG_EXE & $FFMPEG_OPTS & " -loglevel level+verbose -i """ & $file & """ -vn -filter_complex:a """ & (($singleAudioTrack) ? "pan=stereo|c0=c0|c1=c1," : "amerge=inputs=2,") & "ebur128=peak=true:framelog=verbose"" -f null - "
	$hFFmpeg = Run($cmdline, @ScriptDir, @SW_HIDE, $STDERR_CHILD)
	ProcessWaitClose($hFFmpeg)
	Local $lFFmpeg = StderrRead($hFFmpeg)
	StdioClose($hFFmpeg)
	$array = StringRegExp($lFFmpeg, "\[Parsed_ebur128_.*\] \[verbose\] (?=t: )([^\[]*)", $STR_REGEXPARRAYGLOBALMATCH)
	If IsArray($array) Then
		FileDelete($destination)
		Return FileWrite($destination, _ArrayToString($array, ""))
	Else
		Return False
	EndIf
EndFunc   ;==>RunFFMPEG_EBUR128log


Func RunFFMPEG_EBUR128sum($file, $destination, $singleAudioTrack = True)
	Local $cmdline = $FFMPEG_EXE & $FFMPEG_OPTS & " -loglevel level+info -i """ & $file & """ -vn -filter_complex:a """ & (($singleAudioTrack) ? "pan=stereo|c0=c0|c1=c1," : "amerge=inputs=2,") & "ebur128=peak=true:framelog=verbose"" -f null - "
	$hFFmpeg = Run($cmdline, @ScriptDir, @SW_HIDE, $STDERR_CHILD)
	ProcessWaitClose($hFFmpeg)
	Local $lFFmpeg = StderrRead($hFFmpeg)
	StdioClose($hFFmpeg)
	$array = StringRegExp($lFFmpeg, "(?s)time=[:\.\d]+.*\[Parsed_ebur128_.*\] \[info\] Summary:[\r\n]*([^\[]*)", $STR_REGEXPARRAYMATCH)
	If IsArray($array) Then
		FileDelete($destination)
		Return FileWrite($destination, $array[0])
	Else
		Return False
	EndIf
EndFunc   ;==>RunFFMPEG_EBUR128sum


Func RunMXF2RAW($file, $destination)
	Local $result = False
	Local $cmdline = $MXF2RAW_EXE & " --info --info-format xml --info-file """ & $destination & """ --check-complete --check-end """ & $file & """"
	If RunWait($cmdline, @ScriptDir, @SW_HIDE) = 0 Then
		If FileGetSize($destination) > 0 Then
			$result = True
		Else
			FileDelete($destination)
		EndIf
	EndIf
	Return $result
EndFunc   ;==>RunMXF2RAW


Func CheckCompare($source, $destination)
	Local $result = False
	;ConsoleWrite("Checking Attributes for " & $source & @CRLF)
	If Not StringInStr(FileGetAttrib($source), "D") And (FileGetSize($source) > 65536) Then
		If (FileGetTime($source, $FT_MODIFIED, 1) <> FileGetTime($destination, $FT_MODIFIED, 1)) Or (FileGetSize($destination) = 0) Then
;~ 			ConsoleWrite(FileGetTime($source, $FT_CREATED, 1) & @CRLF)
;~ 			ConsoleWrite(FileGetTime($destination, $FT_CREATED, 1) & @CRLF)
;~ 			ConsoleWrite(FileGetTime($source, $FT_MODIFIED, 1) & @CRLF)
;~ 			ConsoleWrite(FileGetTime($destination, $FT_MODIFIED, 1) & @CRLF)
;~ 			ConsoleWrite(FileGetSize($destination) & @CRLF)
;~ 			ConsoleWrite((FileGetTime($source, $FT_CREATED, 1) <> FileGetTime($destination, $FT_CREATED, 1)) & @CRLF)
;~ 			ConsoleWrite((FileGetTime($source, $FT_MODIFIED, 1) <> FileGetTime($destination, $FT_MODIFIED, 1)) & @CRLF)
;~ 			ConsoleWrite((FileGetSize($destination) = 0) & @CRLF)
			If _FileNotLocked($source) And Not _FileInUse($source, 1) Then
				$result = True
			EndIf
		EndIf
	EndIf
	Return $result
EndFunc


Func FileExistsWildcard($pattern)
	Local $result = False
	Local $hSearch = FileFindFirstFile($pattern)
	If $hSearch <> -1 Then
		While 1
			Local $sFileName = FileFindNextFile($hSearch)
			If @error Then ExitLoop
			Local $sDrive, $sDir, $sFileName2, $sExtension2
			_PathSplit($pattern, $sDrive, $sDir, $sFileName2, $sExtension2)
			If Not StringInStr(FileGetAttrib($sDrive & $sDir & $sFileName), "D") Then
				$result = True
				ExitLoop
			EndIf
		WEnd
	EndIf
	FileClose($hSearch)
	Return $result
EndFunc


Func CopyTimeProps($source, $destination)
	If FileExists($destination) Then
		FileSetTime($destination, FileGetTime($source, $FT_CREATED, 1), $FT_CREATED)
		FileSetTime($destination, FileGetTime($source, $FT_MODIFIED, 1), $FT_MODIFIED)
	EndIf
EndFunc


Func _FileNotLocked($sFilename)
	Return FileMove($sFilename, $sFilename, 1)
EndFunc   ;==>_FileNotLocked


;from this post:
;Need help with copy verification
;http://www.autoitscript.com/forum/index.php?showtopic=53994
;===============================================================================
;
; Function Name:    _FileInUse()
; Description:      Checks if file is in use
; Syntax.........: _FileInUse($sFilename, $iAccess = 1)
; Parameter(s):     $sFilename = File name
; Parameter(s):     $iAccess = 0 = GENERIC_READ - other apps can have file open in readonly mode
;                   $iAccess = 1 = GENERIC_READ|GENERIC_WRITE - exclusive access to file,
;                   fails if file open in readonly mode by app
; Return Value(s):  1 - file in use (@error contains system error code)
;                   0 - file not in use
;                   -1 dllcall error (@error contains dllcall error code)
; Author:           Siao
; Modified          rover - added some additional error handling, access mode
; Remarks           _WinAPI_CreateFile() WinAPI.au3
;===============================================================================
Func _FileInUse($sFilename, $iAccess = 0)
	Local $aRet, $hFile, $iError, $iDA
	Local Const $GENERIC_WRITE = 0x40000000
	Local Const $GENERIC_READ = 0x80000000
	Local Const $FILE_ATTRIBUTE_NORMAL = 0x80
	Local Const $OPEN_EXISTING = 3
	$iDA = $GENERIC_READ
	If BitAND($iAccess, 1) <> 0 Then $iDA = BitOR($GENERIC_READ, $GENERIC_WRITE)
	$aRet = DllCall("Kernel32.dll", "hwnd", "CreateFile", _
			"str", $sFilename, _ ;lpFileName
			"dword", $iDA, _ ;dwDesiredAccess
			"dword", 0x00000000, _ ;dwShareMode = DO NOT SHARE
			"dword", 0x00000000, _ ;lpSecurityAttributes = NULL
			"dword", $OPEN_EXISTING, _ ;dwCreationDisposition = OPEN_EXISTING
			"dword", $FILE_ATTRIBUTE_NORMAL, _ ;dwFlagsAndAttributes = FILE_ATTRIBUTE_NORMAL
			"hwnd", 0) ;hTemplateFile = NULL
	$iError = @error
	If @error Or IsArray($aRet) = 0 Then Return SetError($iError, 0, -1)
	$hFile = $aRet[0]
	If $hFile = -1 Then ;INVALID_HANDLE_VALUE = -1
		$aRet = DllCall("Kernel32.dll", "int", "GetLastError")
		;ERROR_SHARING_VIOLATION = 32 0x20
		;The process cannot access the file because it is being used by another process.
		If @error Or IsArray($aRet) = 0 Then Return SetError($iError, 0, 1)
		Return SetError($aRet[0], 0, 1)
	Else
		;close file handle
		DllCall("Kernel32.dll", "int", "CloseHandle", "hwnd", $hFile)
		Return SetError(@error, 0, 0)
	EndIf
EndFunc   ;==>_FileInUse


#cs ----------------------------------------------------------------------------
    AutoIt Version: 3.2.10.0
    Author: WeaponX
    Updated: 2/21/08
    Script Function: Recursive file search
    2/21/08 - Added pattern for folder matching, flag for return type
    1/24/08 - Recursion is now optional
    Parameters:
        RFSstartdir: Path to starting folder
        RFSFilepattern: RegEx pattern to match
            "\.(mp3)" - Find all mp3 files - case sensitive (by default)
            "(?i)\.(mp3)" - Find all mp3 files - case insensitive
            "(?-i)\.(mp3|txt)" - Find all mp3 and txt files - case sensitive
        RFSFolderpattern:
            "(Music|Movies)" - Only match folders named Music or Movies - case sensitive (by default)
            "(?i)(Music|Movies)" - Only match folders named Music or Movies - case insensitive
            "(?!(Music|Movies)\:)\b.+" - Match folders NOT named Music or Movies - case sensitive (by default)
    RFSFlag: Specifies what is returned in the array
        0 - Files and folders
        1 - Files only
        2 - Folders only
    RFSrecurse: TRUE = Recursive, FALSE = Non-recursive
    RFSdepth: Internal use only
#ce ----------------------------------------------------------------------------

Func RecursiveFileSearch($RFSstartDir, $RFSFilepattern = ".", $RFSFolderpattern = ".", $RFSFlag = 0, $RFSrecurse = True, $RFSdepth = 0)
    ;Ensure starting folder has a trailing slash
    If StringRight($RFSstartDir, 1) <> "\" Then $RFSstartDir &= "\"
    If $RFSdepth = 0 Then
        ;Get count of all files in subfolders for initial array definition
        $RFSfilecount = DirGetSize($RFSstartDir, 1)
        ;File count + folder count (will be resized when the function returns)
        Global $RFSarray[$RFSfilecount[1] + $RFSfilecount[2] + 1]
    EndIf
    $RFSsearch = FileFindFirstFile($RFSstartDir & "*.*")
    If @error Then Return
    ;Search through all files and folders in directory
    While 1
        $RFSnext = FileFindNextFile($RFSsearch)
        If @error Then ExitLoop
        ;If folder and recurse flag is set and regex matches
        If StringInStr(FileGetAttrib($RFSstartDir & $RFSnext), "D") Then
            If $RFSrecurse And StringRegExp($RFSnext, $RFSFolderpattern, 0) Then
                RecursiveFileSearch($RFSstartDir & $RFSnext, $RFSFilepattern, $RFSFolderpattern, $RFSFlag, $RFSrecurse, $RFSdepth + 1)
                If $RFSFlag <> 1 Then
                    ;Append folder name to array
                    $RFSarray[$RFSarray[0] + 1] = $RFSstartDir & $RFSnext
                    $RFSarray[0] += 1
                EndIf
            EndIf
        ElseIf StringRegExp($RFSnext, $RFSFilepattern, 0) And $RFSFlag <> 2 Then
            ;Append file name to array
            $RFSarray[$RFSarray[0] + 1] = $RFSstartDir & $RFSnext
            $RFSarray[0] += 1
        EndIf
    WEnd
    FileClose($RFSsearch)
    If $RFSdepth = 0 Then
        ReDim $RFSarray[$RFSarray[0] + 1]
        Return $RFSarray
    EndIf
EndFunc   ;==>RecursiveFileSearch