#include <Array.au3>

Func Serialize_AssertEquals($value, $expected, $erl=@ScriptLineNumber)
     If $value <> $expected Then 
         ConsoleWrite("(" & $erl & ") := Assertion failed: Expected " & $expected & ", got " & $value & @LF)
     EndIf
     Return $value <> $expected
EndFunc

; Some test cases
If @ScriptName == "Serialize.au3" Then
   Serialize_AssertEquals(Deserialize("5"), 5)
   Serialize_AssertEquals(Deserialize("Str(ab\tc)"), "ab"&@TAB&"c")
   Serialize_AssertEquals(Deserialize("Str(ab\""c)"), 'ab"c')
   Serialize_AssertEquals(Deserialize("Str(ab\r\ncd\t)"), "ab"&@CRLF&"cd"&@TAB)
   
   Local $test3[4] = ["7", 3.0, 3, 0]
   Local $test2[4] = [$test3, 2.0, False]
   Local $test[5] = [True, "False", $test2, 3.14, 42]
   Local $serial = Serialize($test)
   Serialize_AssertEquals(Serialize(Deserialize($serial)), $serial)
   
   Exit 0
EndIf

Func Serialize($value)
   If IsFloat($value) Or IsInt($value) Or IsBool($value) Then Return String($value)
   If IsString($value) Then
      $value = StringReplace($value, "\", "\\", Default, 1)
      $value = StringReplace($value, @CR, "\r", Default, 1)
      $value = StringReplace($value, @LF, "\n", Default, 1)
      $value = StringReplace($value, @TAB, "\t", Default, 1)
      $value = StringReplace($value, '"', '\"', Default, 1)
      Return "Str("&$value&")"
   EndIf
   If IsArray($value) Then
      Local $result = "[", $i
      For $i = 0 To UBound($value) - 1
         If $i > 0 Then $result &= ","
         $result &= Serialize($value[$i])
      Next
      Return $result & "]"
   EndIf
EndFunc

Func Deserialize($string, $start = 1)
   Local Const $errInvalid = 1, $errLength = 2, $errArray = 3, $errString = 4, $errNumber = 5
   Local $char, $end, $result, $length = StringLen($string)
   
   If $start > $length Then
      SetExtended($start)
      SetError($errLength)
      Return ""
   EndIf
   
   ; Skip whitespace at current starting position
   While $start <= $length And StringIsSpace(StringMid($string, $start, 1))
      $start += 1
   WEnd
   
   ; Parse Array
   If StringMid($string, $start, 1) == "[" Then
      ;p("Parsing Array")
      $end = $start + 1
      While $end <= $length And StringMid($string, $end, 1) <> "]"
         Local $value = Deserialize($string, $end)
         $end = @extended
         If @error Then Return ""
         If IsArray($result) Then
            _ArrayAdd($result, $value)
         Else
            Local $result[1] = [$value]
         EndIf
         
         ; Skip whitespace after parsed array element
         While $end <= $length And StringIsSpace(StringMid($string, $end, 1))
            $end += 1
         WEnd
         
         If StringMid($string, $end, 1) == "," Then
            $end = $end + 1
         ElseIf StringMid($string, $end, 1) <> "]" Then
            SetExtended($end)
            SetError($errArray)
            Return ""
         EndIf
      WEnd
      If $end > $length Then
         SetExtended($end)
         SetError($errArray)
         Return ""
      Else
         SetExtended($end + 1)
         Return $result
      EndIf
   EndIf
   
   ; Parse Strings
   If StringMid($string, $start, 4) == "Str(" Then
      $result = ""
      $end = $start + 4
      $char = StringMid($string, $end, 1)
      While $end <= $length And StringMid($string, $end, 1) <> ")"
         $char = StringMid($string, $end, 1)
         If $char == "\" Then
            $end += 1
            $char = StringMid($string, $end, 1)
            If $end < $length Then
               Switch $char
                  Case "n"
                     $char = @LF
                  Case "r"
                     $char = @CR
                  Case "t"
                     $char = @TAB
                  Case "v"
                     $char = Chr(11) ; Vertical Tab
                  Case Else
                     ; Every other char is just mapped to itself
                     ; For example \' => ', \" => ", \\ => \
               EndSwitch
            EndIf
         EndIf
         $result = $result & $char
         $end = $end + 1
      WEnd
      If $end > $length Then
         SetExtended($end)
         SetError($errString)
         Return ""
      Else
         SetExtended($end + 1)
         Return $result
      EndIf
   EndIf
   
   ; Parse Numbers
   $end = $start 
   If $end <= $length And (StringIsDigit(StringMid($string, $end, 1)) Or StringMid($string, $end, 1) == "-" Or StringMid($string, $end, 1) == "+" Or StringMid($string, $end, 1) == ".") Then
      If $end <= $length And (StringMid($string, $end, 1) == "-" Or StringMid($string, $end, 1) == "+") Then
         $end = $end + 1
      EndIf
      While $end <= $length And StringIsDigit(StringMid($string, $end, 1))
         $end = $end + 1
      WEnd
      If $end <= $length And StringMid($string, $end, 1) == "." Then
         $end = $end + 1
      EndIf
      While $end <= $length And StringIsDigit(StringMid($string, $end, 1))
         $end = $end + 1
      WEnd
      $result = StringMid($string, $start, $end - $start)
      If StringIsFloat($result) Or StringIsInt($result) Then
         $result = Number($result)
         SetExtended($end)
         Return $result
      Else
         SetExtended($end)
         SetError($errNumber)
         Return ""
      EndIf
   EndIf
   
   ; Parse Booleans
   If StringLower(StringMid($string, $start, 4)) == "true" Then
      SetExtended($start + 4)
      Return True
   EndIf
   If StringLower(StringMid($string, $start, 5)) == "false" Then
      SetExtended($start + 5)
      Return False
   EndIf
   
   ; Unknown Data
   SetExtended($start)
   SetError($errInvalid)
   Return ""
EndFunc
   
