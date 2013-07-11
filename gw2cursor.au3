#include <GDIPlus.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <WinAPI.au3>
#include <Constants.au3>
#include <Misc.au3>
#include "Serialize.au3"

; Global Constants
Global Const $websiteUrl = "https://github.com/fritzw/gw2-cursor"
Global Const $version = "0.1.1"
Global Const $settingsFile = "settings.ini"

; Install files needed for operation
FileInstall("cursor1.png", "cursor1.png")
FileInstall("cursor2.png", "cursor2.png")
FileInstall("tray-icon.ico", "tray-icon.ico")
FileInstall("settings-example.ini", "settings-example.ini")

; Determine overlay cursor image and position relative to the real cursor
Global $whichCursor = "Cursor" & ReadSetting("Which Cursor", "1")
Global $pngSrc = ReadSetting($whichCursor & " Image", "cursor1.png", "Cursors")
Global $offsetX = ReadSetting($whichCursor & " Offset X", 2, "Cursors")
Global $offsetY = ReadSetting($whichCursor & " Offset Y", 5, "Cursors")

; Milliseconds delay between updating the cursor position
Global $interval = 1000/ReadSetting("Updates Per Second", "120")

; Load user settings
$hideWhileDragging = ReadSetting("Hide Cursor While Dragging", False)

; Initialize tray icon
Opt("TrayAutoPause", 0)
Opt("TrayMenuMode", 3)
Global $trayTip = "GW2-Cursor (version " & $version & ")"
TraySetToolTip($trayTip)
TraySetIcon("tray-icon.ico")
$trayItemHide = TrayCreateItem("Hide while dragging")
CheckTrayItem($trayItemHide, $hideWhileDragging)
$trayItemWebsite = TrayCreateItem("Go to website")
TrayCreateItem("")
$trayItemExit = TrayCreateItem("Exit")


; Find out if the user wants update notifications
$autoUpdate = ReadSetting("Auto Update", "invalid")
If Not IsBool($autoUpdate) Then
   $answer = MsgBox(3 + 32, "GW2-Cursor", "Do you want to be notified of updates when starting the script?" & @LF & "(Note: Updates will NOT be installed automatically)")
   If $answer == 6 Then ; Yes
      $autoUpdate = True
      WriteSetting("Auto Update", True)
   ElseIf $answer == 7 Then ; No
      $autoUpdate = False
      WriteSetting("Auto Update", False)
   EndIf
EndIf

; Check for updates
If $autoUpdate == True Then
   TraySetToolTip("GW2-Cursor -- Checking for updates, please wait...")
   Local $remoteVersion = HttpGet("https://raw.github.com/fritzw/gw2-cursor/master/Version.txt")
   If $remoteVersion <> "" And _VersionCompare($remoteVersion, $version) > 0 Then
      If MsgBox(4 + 64, "GW2-Cursor", "An update to version " & $remoteVersion & " is available. You are currently running version " & $version & ". Do you want to go to the website now?") == 6 Then
         ShellExecute($websiteUrl)
      EndIf
   EndIf
   TraySetToolTip($trayTip)
EndIf


; Load cursor image file
_GDIPlus_Startup()
Global $hImage = _GDIPlus_ImageLoadFromFile($pngSrc)
Global $overlayWidth = _GDIPlus_ImageGetWidth($hImage)
Global $overlayHeight = _GDIPlus_ImageGetHeight($hImage)

; Create overlay window
Global $overlay = GUICreate("", $overlayWidth ,$overlayHeight,  -1, -1, BitOR($WS_POPUP,0), BitOr($WS_EX_TOPMOST, $WS_EX_TRANSPARENT, $WS_EX_LAYERED, $WS_EX_TOOLWINDOW))
SetBitmap($overlay, $hImage, 255)

; Some internal status variables
Global $overlayVisible = False
Global $mouseDown = False
Global $counter = 0
Global $iterations = 0
Global $begin = TimerInit()
Global $mouseX = MouseGetPos(0), $mouseY = MouseGetPos(1)

While True
   $iterations += 1
   $delay = $iterations * $interval - TimerDiff($begin)
   Sleep($delay)
   
   ; Do some things periodically (every second)
   If $counter <= 0 Then
      $counter = 1000 / $interval
      $gw2handle = WinGetHandle("[TITLE:Guild Wars 2; CLASS:ArenaNet_Dx_Window_Class]")
      $clientArea = _WinAPI_GetClientRect($gw2handle)
   EndIf
   
   ; Leave the cursor where it is, while a mouse button is held down
   If _IsPressed(2) Or _IsPressed(1) Then
      $pos = MouseGetPos()
      $distance = Abs($mouseX - $pos[0]) + Abs($mouseY - $pos[1])
      If $hideWhileDragging And $distance > 4 And $overlayVisible Then HideOverlay()
      ContinueLoop
   Endif
   
   $mouse = _WinAPI_GetMousePos()
   $mouseX = DllStructGetData($mouse, "X")
   $mouseY = DllStructGetData($mouse, "Y")
   $hwnd = _WinAPI_WindowFromPoint($mouse)
   _WinApi_ScreenToClient($hwnd, $mouse)
   If $hwnd == $gw2handle And RectContains($clientArea, $mouse) Then
      If Not $overlayVisible Then ShowOverlay()
      MoveOverlay($mouseX, $mouseY)
   Else
      If $overlayVisible Then HideOverlay()
   EndIf
   $counter = $counter - 1
   
   Switch TrayGetMsg()
      Case $trayItemHide
         $hideWhileDragging = Not $hideWhileDragging
         WriteSetting("Hide Cursor While Dragging", $hideWhileDragging)
         CheckTrayItem($trayItemHide, $hideWhileDragging)
      Case $trayItemWebsite
         ShellExecute($websiteUrl)
      Case $trayItemExit
         Exit 0
   EndSwitch
WEnd

Func MoveOverlay($x, $y)
   Global $overlay, $offsetX, $offsetY
   WinMove($overlay, "", $x - $offsetX, $y - $offsetY)
EndFunc

Func ShowOverlay()
   Global $overlay, $overlayVisible = True
   GUISetState(@SW_SHOWNOACTIVATE, $overlay)
   Local $mouse = MouseGetPos()
   MoveOverlay($mouse[0], $mouse[1])
EndFunc

Func HideOverlay()
   Global $overlay, $overlayVisible = False
   GUISetState(@SW_HIDE, $overlay)
EndFunc

Func CheckTrayItem($item, $bool)
   If $bool Then
      TrayItemSetState($item, $TRAY_CHECKED)
   Else
      TrayItemSetState($item, $TRAY_UNCHECKED)
   EndIf
EndFunc


Func RectContains($rectangle, $point)
   Local $left = DllStructGetData($rectangle, "Left")
   Local $right = DllStructGetData($rectangle, "Right")
   Local $top = DllStructGetData($rectangle, "Top")
   Local $bottom = DllStructGetData($rectangle, "Bottom")
   Local $x = DllStructGetData($point, "X")
   Local $y = DllStructGetData($point, "Y")
   Return $x >= $left And $x < $right And $y >= $top And $y < $bottom
EndFunc


Func ReadSetting($key, $default="", $section="General")
   Local Const $invalid = "sv8one765sl874vn6o87465bv7w45687v6s87w348v7"
   Local $value = IniRead($settingsFile, $section, $key, $invalid)
   If $value == $invalid Then
      Return $default
   Else
      Local $decoded = Deserialize($value)
      If @error Then ErrorBox("Error decoding '" & $key & "=" & $value & " in section [" & $section & "] in " & $settingsFile)
      Return $decoded
   EndIf
EndFunc

Func ErrorBox($text, $fatal=True, $code=1)
   MsgBox(48, "GW2-Cursor Error", $text)
   If $fatal Then Exit $code
EndFunc

Func WriteSetting($key, $value="", $section="General")
   $data = Serialize($value)
   ; Strings containing , or ; should be quoted in ini files.
   If StringInStr($data, ",") <> 0 Or StringInStr($data, ";") <> 0 Then
      $data = '"' & $data & '"'
   EndIf
   IniWrite($settingsFile, $section, $key, $data)
EndFunc

Func Debug($message)
   ConsoleWrite($message & @CRLF)
EndFunc


Func HttpGet($url)
   Local $oHTTP = ObjCreate("winhttp.winhttprequest.5.1")
   $oHTTP.SetTimeouts(3000, 3000, 3000, 3000)
   $oHTTP.Open("GET", $url, False)
   $oHTTP.Send()
   If $oHTTP.Status == 200 Then Return $oHTTP.ResponseText
   Return ""
EndFunc

Func Terminate()
   Exit 0
EndFunc

; Courtesy of Pinguin94 (http://autoit.de/index.php?page=Thread&threadID=17900)
Func SetBitmap($hGUI, $hImage, $iOpacity)
   Local $hScrDC, $hMemDC, $hBitmap, $hOld, $pSize, $tSize, $pSource, $tSource, $pBlend, $tBlend
   Local Const $AC_SRC_ALPHA = 1

   $hScrDC = _WinAPI_GetDC(0)
   $hMemDC = _WinAPI_CreateCompatibleDC($hScrDC)
   $hBitmap = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hImage)
   $hOld = _WinAPI_SelectObject($hMemDC, $hBitmap)
   $tSize = DllStructCreate($tagSIZE)
   $pSize = DllStructGetPtr($tSize)
   DllStructSetData($tSize, "X", _GDIPlus_ImageGetWidth($hImage))
   DllStructSetData($tSize, "Y", _GDIPlus_ImageGetHeight($hImage))
   $tSource = DllStructCreate($tagPOINT)
   $pSource = DllStructGetPtr($tSource)
   $tBlend = DllStructCreate($tagBLENDFUNCTION)
   $pBlend = DllStructGetPtr($tBlend)
   DllStructSetData($tBlend, "Alpha", $iOpacity)
   DllStructSetData($tBlend, "Format", $AC_SRC_ALPHA)
   _WinAPI_UpdateLayeredWindow($hGUI, $hScrDC, 0, $pSize, $hMemDC, $pSource, 0, $pBlend, $ULW_ALPHA)
   _WinAPI_ReleaseDC(0, $hScrDC)
   _WinAPI_SelectObject($hMemDC, $hOld)
   _WinAPI_DeleteObject($hBitmap)
   _WinAPI_DeleteDC($hMemDC)
EndFunc   ;==>SetBitmap

