#Requires AutoHotkey v2
#SingleInstance

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
/*
Replace "yourChoiceofAPIkey" with working API key.
Replace path-to-file with actual path and file name.
Download phiola (lightweight, portable audio recorder with convenient CLI controls) at https://github.com/stsaz/phiola.
F2 - F4 are mainly for testing purposes.  Once CMD window disappears, press Ctrl-V in any text field to observe results.
For transcription demonstration, audio file (e.g., WhisperAudioTest.m4a) should be pre-recorded, unless using PTT.
The hotkeys that perform PTT are Ctrl + Right-Click or Shift + Right-Click.  If cursor has focus in a text field, transcribed output would be auto-pasted at the cursor.
Switching syntax to AHK v1, if necessary, is straightforward ... mainly just need to note that double-quote escaping in v1 is different.
If working behind a proxy server, will need to update cURL command flags accordingly.
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; OpenAI Related
Global API_Key := "yourChoiceofAPIkey"
Global Chat_Endpoint := "https://api.openai.com/v1/chat/completions"
Global Transcription_Endpoint := "https://api.openai.com/v1/audio/transcriptions"
Global Chat_Model := "gpt-3.5-turbo"
Global Chat_PromptFile := "C:\Users\username\Desktop\Promtjson.txt"			 ; Optional and better able to deal with escaping in json strings (https://developer.zendesk.com/documentation/api-basics/getting-started/installing-and-using-curl/#move-json-data-to-a-file)
Global Transcription_Model := "whisper-1"
Global Transcription_Language := "en"
Global Transcription_ResponseFormat := "text"
Global Transcription_Prompt := "no cap, cap, no space, open paren, close paren, left paren, right paren, ellipsis, colon mark, number one, spacebar, new paragraph, comma, literal period, period"
Global Transcription_AudioTestFile := "C:\Users\username\Desktop\WhisperAudioTest.m4a"
Global Transcription_AudioOverwrittenFile := "C:\Users\username\Desktop\WhisperAudio.m4a"

Global Chat_Prompt := "Write out a random title, or 2, from Oscar Wilde's collection: `"The Happy Prince and Other Tales`"."			; double-quote escaping can be a headache
Chat_Prompt := RegExReplace(Chat_Prompt, "\R", "\n")				
Chat_Prompt := Trim(Chat_Prompt)
Chat_Prompt := StrReplace(Chat_Prompt, "`"", "\\\`"")                        ; for escaping purposes inside cURL


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; cURL Related
Global Curl_Command := "curl"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Misc Windows Shell Related
Global Pipe_toClip := "| clip"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Phiola Related
Path_toPhiola := "C:\Users\username\Desktop\phiola-2\phiola.exe"
Phiola_Remote_Record := Path_toPhiola . " -Background record -f -o " . Transcription_AudioOverwrittenFile . " -remote"
Phiola_Remote_Stop := Path_toPhiola . " remote stop"

;;ListeningTrayIconFile := "Path-to-TrayIconFile"           ; Useful as Mic On indicator


F2::                                                ; Test to ensure cURL works ... add cURL flags as required.
{
    Run A_ComSpec ' /C curl https://api.openai.com/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer yourChoiceofAPIkey" -d "{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"assistant\", \"content\": \"Write out a random aphorism by Ludwig Wittgenstein\"}]}" | clip'
}


F3::                                                ; For testing
{
    Run A_ComSpec ' /C curl https://api.openai.com/v1/audio/transcriptions -H "Authorization: Bearer yourChoiceofAPIkey" -H "Content-Type: multipart/form-data" -F model="whisper-1" -F response_format="text" -F file="@C:/Users/username/Desktop/WhisperAudioTest.m4a" -F prompt="comma, period, new paragraph" | clip',, "Hide"
}


F4::                                                ; For testing
{
    Run A_ComSpec " /C " ChatCurling(),, "Hide"
}


F5::                                                ; Useful for re-sending recording if results from first-pass are compromised by "hallucination", etc.
{
    Run A_ComSpec " /C " TranscriptionCurling()
;;    Clipwait for content, then PostProcessing() as desired.
;;    Wait until CMD window disappears, then press Ctrl-v to see output right at the cursor (if focused in a text field)
}


;; SC029::							; Scan code for Tilde (~), shown just as an example
+RButton::
^RButton::
{
    WinID_Current := WinExist("A")
    A_Clipboard := ""
    Run A_ComSpec " /C " Phiola_Remote_Record,, "Hide"
;;    TraySetIcon(ListeningTrayIconFile)
;;    Keywait "SC029"
    KeyWait "RButton"
    Send "{Blind}{Control up}{Alt up}{Shift up}"
    Sleep 500
    Run A_ComSpec " /C " Phiola_Remote_Stop,, "Hide"
    Sleep 300
    Run A_ComSpec " /C " TranscriptionCurling(),, "Hide"
    if !ClipWait(20)
    {
        MsgBox "Transcription did not happen for some reason despite waiting for 20s."
        Return
    }
;;    TraySetIcon("*")                                         ; Restore default AHK icon
;;    Sleep 50						
    PostProcessing()                              ; Optional but desirable
    WinActivate "ahk_id " WinID_Current
    SendEvent "{Ctrl down}v{Ctrl up}"             ; Send "^v" may work better in some places
}


Join(sep, params*) 
{
    For index, param in params
        str .= param . sep
    Return str
}


ChatCurling()
{
    Key_Header :=  "-H `"Authorization: Bearer " . API_Key . "`""
    Chat_ContentType_Header :=  "-H `"Content-Type: application/json" . "`""
    Chat_Data := "-d " . "`"{\`"model\`": \`"" . Chat_Model . "\`", \`"messages\`": [{\`"role\`": \`"assistant\`", \`"content\`": \`"" . Chat_Prompt . "\`"}]}`""
;;    Chat_Data := "-d " . "`"@" . Chat_PromptFile . "`""
    Return Join(A_Space, Curl_Command, Chat_Endpoint, Key_Header, Chat_ContentType_Header, Chat_Data, Pipe_toClip)
}


TranscriptionCurling()
{
    Key_Header :=  "-H `"Authorization: Bearer " . API_Key . "`""
    Transcription_ContentType_Header :=  "-H `"Content-Type: multipart/form-data" . "`""
    Transcription_Model_Form :=  "-F model=" . "`"" . Transcription_Model . "`""	
    Transcription_Language_Form := "-F language=" . "`"" . Transcription_Language . "`""	
    Transcription_ResponseFormat_Form := "-F response_format=" . "`"" . Transcription_ResponseFormat . "`""
    Transcription_AudioFile_Form := "-F file=" . "`"@" . Transcription_AudioOverwrittenFile . "`""
    Transcription_Prompt_Form := "-F prompt=" . "`"" . Transcription_Prompt . "`""
    Return Join(A_Space, Curl_Command, Transcription_Endpoint, Key_Header, Transcription_ContentType_Header, Transcription_Model_Form, Transcription_Language_Form, Transcription_ResponseFormat_Form, Transcription_AudioFile_Form, Transcription_Prompt_Form, Pipe_toClip)
}


PostProcessing()
{
;;    Reference https://www.autohotkey.com/docs/v2/lib/RegExReplace.htm
;;    Below is "empirically validated", not by any means "optimized".
    Temp_String := A_Clipboard
    Temp_String := RegExReplace(Temp_String, "i)(come on[,.]*|come out[,.]*|come up[,.]*)", "comma")
    Temp_String := RegExReplace(Temp_String, "([.])(\w)", "decimalpointdot$2")    
    Temp_String := RegExReplace(Temp_String, "[.,]", "")    
    Temp_String := RegExReplace(Temp_String, "i)( |\b)(literal[\s.,]period)( |\b)", "$1prd$3")
    Temp_String := RegExReplace(Temp_String, "i)( |\b)(quotation[\s-]mark[[:blank:]]?|open[\s-]quote[[:blank:]]?|close[d]*[\s-]quote[[:blank:]]?|left[\s-]quote[[:blank:]]?|right[\s-]quote[[:blank:]]?)(\b)", "`"$3")
    Temp_String := RegExReplace(Temp_String, "i)( |\b)(open[ed]*[\s-]paren[t]*[[:blank:]]?|left[\s-]paren[t]*[[:blank:]]?)", "$1(")
    Temp_String := RegExReplace(Temp_String, "i)( close[d]*[\s-]paren[t]*[[:blank:]]?| right[\s-]paren[t]*[[:blank:]]?)(\b)", ")$2")
    Temp_String := RegExReplace(Temp_String, "i)( |\b)(comma| kama| karma)( |\b)", ",$3")
    Temp_String := RegExReplace(Temp_String, "i)( |\b)(colon mark| Cohen mark| column mark)( |\b)", ":$3")
    Temp_String := RegExReplace(Temp_String, "i)( |\b)(semicolon)( |\b)", ";$3")
    Temp_String := RegExReplace(Temp_String, "i)( |\b)(hyphen)( |\b)", "-")
    Temp_String := RegExReplace(Temp_String, "i)( |\b)(forward slash|4 slash|for slash)( |\b)", "/")
    Temp_String := RegExReplace(Temp_String, "i)( |\b)(period| PewDiePie| full stop)( \w|\b)", ". $u3")
    Temp_String := RegExReplace(Temp_String, "i)( |\b)(exclamation)([\s-]*)(mark)*( \w|\b)", "! $u5")
    Temp_String := RegExReplace(Temp_String, "i)( |\b)(question mark)( \w|\b)", "? $u3")
    Temp_String := RegExReplace(Temp_String, "i)( |\b)(apostrophe)( \w|\b)", "'$l3")
    Temp_String := RegExReplace(Temp_String, "i)(ellipsis|dot dot dot)", "...")
    Temp_String := StrReplace(Temp_String, "single dash", "-")
    Temp_String := RegExReplace(Temp_String, "i)(plus[\s-]minus)", "+/-")
    Temp_String := RegExReplace(Temp_String, "`"[[:blank:]]*([\S\s]*?)[[:blank:]]*`"", " `"$1`" ")
    Temp_String := RegExReplace(Temp_String, "([[:blank:]]*)(\Q(\E)([[:blank:]]*)([\S\s]*?)([[:blank:]]*)(\Q)\E)([[:blank:]]*)", " $2$4$6 ")
    Temp_String := RegExReplace(Temp_String, "(`")([[:blank:]]*)([,.;:!?])", "$1$3")
    Temp_String := RegExReplace(Temp_String, "(\Q)\E)([[:blank:]]*)([,.;:!?])", "$1$3")
    Temp_String := RegExReplace(Temp_String, "[.!?:]+[[:blank:]]*[a-z]", "$u0")
    Temp_String := RegExReplace(Temp_String, "(\w)([[:blank:]]+)(\w)", "$1 $3")
    Temp_String := RegExReplace(Temp_String, "([.!?]\s*\()([a-zA-Z])", "$1$u2")
    Temp_String := RegExReplace(Temp_String, "i)(number[[:blank:]]*)([0-9])", "#$2")
    Temp_String := RegExReplace(Temp_String, "i)(number one)", "#1")
    Temp_String := RegExReplace(Temp_String, "i)(number two)", "#2")
    Temp_String := RegExReplace(Temp_String, "i)(number three)", "#3")
    Temp_String := RegExReplace(Temp_String, "i)(number four)", "#4")
    Temp_String := RegExReplace(Temp_String, "i)(number five)", "#5")
    Temp_String := RegexReplace(Temp_String, "(\R)$", "")			; Whisper tends to add a single newline at the end ...
    Temp_String := Trim(Temp_String)
    Temp_String := RegExReplace(Temp_String, "i)[[:blank:]]*(a new paragraph|new paragraph|new, paragraph)\b", "`r`n`r`n")
    Temp_String := RegExReplace(Temp_String, "`am)^([[:blank:]]*)(\S)", "$u2")
    Temp_String := RegExReplace(Temp_String, "i)(no cap[s]*[[:blank:]]*)(\w)", "$l2")
    Temp_String := RegExReplace(Temp_String, "i)(\bcap[s]*[[:blank:]]*)(\w)", "$u2")
    Temp_String := RegExReplace(Temp_String, "i)([.!?])([[:blank:]]*[`"|\)][[:blank:]]*)(\w)", "$1$2$u3")
    Temp_String := RegExReplace(Temp_String, "i)([.!?])(\Q (\E)", "$1  (")
    Temp_String := RegExReplace(Temp_String, "i)(\Q) \E)([.!?])", ")$2")
    Temp_String := StrReplace(Temp_String, "prd", "period")
    Temp_String := StrReplace(Temp_String, "decimalpointdot", ".")
    Temp_String := RegExReplace(Temp_String, "(\QMr\E|\QMrs\E|\QMs\E|\QDr\E|\QSt\E)( )([a-zA-Z])", "$1. $u3")
    Temp_String := RegExReplace(Temp_String, "i)([[:blank:]]*no[\s-]space[[:blank:]]*)", "")
    Temp_String := RegExReplace(Temp_String, "i)([[:blank:]]*spacebar[[:blank:]]*)", " ")
    Temp_String := RegExReplace(Temp_String, "([?!])([[:blank:]]*)([?!])", "$3")
    A_Clipboard := Temp_String
}
