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
Global Transcription_Prompt := "new paragraph, comma, period"
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


F2::                                                ; Test to ensure cURL works ... add cURL flags as required.
{
    Run A_ComSpec ' /C curl https://api.openai.com/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer yourChoiceofAPIkey" -d "{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"assistant\", \"content\": \"Write out a random aphorism by Ludwig Wittgenstein\"}]}" | clip'
}


F3::                                                ; For testing
{
    Run A_ComSpec ' /C curl https://api.openai.com/v1/audio/transcriptions -H "Authorization: Bearer yourChoiceofAPIkey" -H "Content-Type: multipart/form-data" -F model="whisper-1" -F response_format="text" -F file="@C:/Users/username/Desktop/WhisperAudioTest.m4a" -F prompt="comma, period, new paragraph" | clip'
}


F4::                                                ; For testing
{
    Run A_ComSpec " /C " ChatCurling()
}


F5::                                                ; Useful for re-sending recording if results from first-pass are compromised by "hallucination", etc.
{
    Run A_ComSpec " /C " TranscriptionCurling()
;;    PostProcessing()                              ; Optional but desirable
;;    Wait until CMD window disappears, then press Ctrl-v to see output right at the cursor (if focused in a text field)
}


;; SC029::							; Scan code for Tilde (~), shown just as an example
+RButton::
^RButton::
{
    WinID_Current := WinExist("A")
    A_Clipboard := ""
    Run A_ComSpec " /C " Phiola_Remote_Record
;;    Keywait "SC029"
    KeyWait "RButton"
    Send "{Blind}{Control up}{Alt up}{Shift up}"
    Sleep 300
    Run A_ComSpec " /C " Phiola_Remote_Stop
    Sleep 300
    Run A_ComSpec " /C " TranscriptionCurling()
    if !ClipWait(20)
    {
        MsgBox "Transcription did not happen for some reason despite waiting for 20s."
        Return
    }
    Sleep 50						
;;    PostProcessing()                              ; Optional but desirable
    WinActivate "ahk_id " WinID_Current
    SendEvent "{Ctrl down}v{Ctrl up}"
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
;    Chat_Data := "-d " . "`"@" . Chat_PromptFile . "`""
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
;;    E.g., https://www.autohotkey.com/docs/v2/lib/RegExReplace.htm
}
