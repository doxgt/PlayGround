#Requires AutoHotkey v2
#SingleInstance

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
/*
Replace "yourChoiceofAPIkey" with actual API key.

Replace path-to-file with actual path and file name.

Download phiola (lightweight, portable audio recorder with convenient CLI controls) at https://github.com/stsaz/phiola.

F2 - F5 are merely to demonstrate proofs of concept.  Once CMD window disappears, press Ctrl-V in any text field to observe results.

For F3 and F5 demonstrations, you should have already recorded an audio file (WhisperAudioTest.m4a) for transcription upload.

The hotkeys that do PTT are what I am using in production (the Tilde, or SC029, was already appropriated for other purposes; but included here for illustration).  Leave cursor in a text field.  Transcribed output should be pasted automatically at the cursor.

Switching back to AHK v1 syntax is fairly simple if necessary ... mainly just need to note that double-quote escaping in v1 is different.
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


API_Key := "yourChoiceofAPIkey"
API_URL := "https://api.openai.com/v1/chat/completions"
SAPI_URL := "https://api.openai.com/v1/audio/transcriptions"
API_Model := "gpt-3.5-turbo"
API_PromptFile := "C:\Users\username\Desktop\Promtjson.txt"			; Optional and better able to deal with escaping in json strings (https://developer.zendesk.com/documentation/api-basics/getting-started/installing-and-using-curl/#move-json-data-to-a-file)
SAPI_Model := "whisper-1"
SAPI_Prompt := "comma, period, new paragraph"
SAPI_AudioTestFile := "C:\Users\username\Desktop\WhisperAudioTest.m4a"
SAPI_AudioOverwrittenFile := "C:\Users\username\Desktop\WhisperAudio.m4a"

Path_toPhiola := "C:\Users\username\Documents\phiola-2.0.24-windows-x64\phiola-2\phiola.exe"

ChatGPT_Prompt := "Write out a random title, or 2, from Oscar Wilde's collection: `"The Happy Prince and Other Tales`"."			; This tests double-quote escaping, which is a headache

ChatGPT_Prompt := RegExReplace(ChatGPT_Prompt, "\R", "\n")				
ChatGPT_Prompt := Trim(ChatGPT_Prompt)
ChatGPT_Prompt := StrReplace(ChatGPT_Prompt, "`"", "\\\`"")

; MsgBox(ChatGPT_Prompt)

API_Endpoint := API_URL . A_Space

SAPI_Endpoint := SAPI_URL . A_Space

Key_Header :=  "-H `"Authorization: Bearer " . API_Key . "`"" . A_Space

API_ContentType_Header :=  "-H `"Content-Type: application/json" . "`"" . A_Space

SAPI_ContentType_Header :=  "-H `"Content-Type: multipart/form-data" . "`"" . A_Space

API_Data := "-d " . "`"{\`"model\`": \`"" . API_Model . "\`", \`"messages\`": [{\`"role\`": \`"assistant\`", \`"content\`": \`"" . ChatGPT_Prompt . "\`"}]}`"" . A_Space

; API_Data := "-d " . "`"@" . API_PromptFile . "`"" . A_Space		; if uploading a json string file - less problems with escaping

SAPI_Model_Form :=  "-F model=" . "`"" . SAPI_Model . "`"" . A_Space	

SAPI_ResponseFormat_Form := "-F response_format=" . "`"text`"" . A_Space	

SAPI_AudioTestFile_Form := "-F file=" . "`"@" . SAPI_AudioTestFile . "`"" . A_Space

SAPI_AudioFile_Form := "-F file=" . "`"@" . SAPI_AudioOverwrittenFile . "`"" . A_Space

SAPI_Prompt_Form := "-F prompt=" . "`"" . SAPI_Prompt . "`"" . A_Space

PipetoClip := "| clip"

API_Curling := "curl " . API_Endpoint . Key_Header . API_ContentType_Header . API_Data . PipetoClip

SAPI_CurlingTest := "curl " . SAPI_Endpoint . Key_Header . SAPI_ContentType_Header . SAPI_Model_Form . SAPI_ResponseFormat_Form . SAPI_AudioTestFile_Form . SAPI_Prompt_Form . PipetoClip

SAPI_Curling := "curl " . SAPI_Endpoint . Key_Header . SAPI_ContentType_Header . SAPI_Model_Form . SAPI_ResponseFormat_Form . SAPI_AudioFile_Form . SAPI_Prompt_Form . PipetoClip

Phiola_Remote_Record := Path_toPhiola . " -Background -Debug record -o " . SAPI_AudioOverwrittenFile . " -remote"

Phiola_Remote_Stop := Path_toPhiola . " remote stop"


F2::
{
Run A_ComSpec ' /c curl https://api.openai.com/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer yourChoiceofAPIkey" -d "{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"assistant\", \"content\": \"Write out a random aphorism by Ludwig Wittgenstein\"}]}" | clip'
}


F3::
{
Run A_ComSpec ' /c curl https://api.openai.com/v1/audio/transcriptions -H "Authorization: Bearer yourChoiceofAPIkey" -H "Content-Type: multipart/form-data" -F model="whisper-1" -F response_format="text" -F file="@C:/Users/username/Desktop/WhisperAudioTest.m4a" -F prompt="comma, period, new paragraph" | clip'
}


F4::
{
    RunWaitOne(API_Curling)
}


F5::
{
    RunWaitOne(SAPI_CurlingTest)
}


SC029::									; Scan code for Tilde (~)
+RButton::
^RButton::
{
    If FileExist("" SAPI_AudioOverwrittenFile  "")
        FileDelete "" SAPI_AudioOverwrittenFile "" 
    A_Clipboard := ""
    RunWaitOne(Phiola_Remote_Record)
    Keywait "SC029"
    KeyWait "RButton"
    Sleep 300
    RunWaitOne(Phiola_Remote_Stop)
    Sleep 300
    RunWaitOne(SAPI_Curling)
    if !ClipWait(20)
    {
        MsgBox "Transcription did not happen for some reason despite waiting for 20s."
        If FileExist("" SAPI_AudioOverwrittenFile  "")
            FileDelete "" SAPI_AudioOverwrittenFile "" 
        Return
    }
    If FileExist("" SAPI_AudioOverwrittenFile  "")
        FileDelete "" SAPI_AudioOverwrittenFile "" 
    Send "{Control up}{Alt up}{Shift up}"
    Sleep 50
    SendEvent "{Ctrl down}v{Ctrl up}"
}


;;;;https://www.autohotkey.com/docs/v2/lib/Run.htm#ExStdOut
RunWaitOne(command) 
{
    shell := ComObject("WScript.Shell")
    ; Execute a single command via cmd.exe
    exec := shell.Exec(A_ComSpec " /C " command)
    ; Read and return the command's output
;    return exec.StdOut.ReadAll()					; Prevents "Phiola_Remote_Stop from working
    return
}
