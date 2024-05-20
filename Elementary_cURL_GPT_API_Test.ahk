#Requires AutoHotkey v2
#SingleInstance

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
/*
Below are more modular examples that serve as further proofs of concept.
Replace "yourAPIkey" with actual API key.
Replace path-to-file with actual path and name.
You should have already recorded an audio file for transcription.
I personally use fmedia/phiola (https://github.com/stsaz/phiola).
Press F4 or F5. Once CMD window disappears, press Ctrl-V in any text field to confirm results are as expected.
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

API_Key := "yourAPIkey"
API_URL := "https://api.openai.com/v1/chat/completions"
SAPI_URL := "https://api.openai.com/v1/audio/transcriptions"
API_Model := "gpt-3.5-turbo"
API_PromptFile := "C:\Users\yourname\Desktop\Promtjson.txt"			; Optional and better able to deal with escaping in json strings (https://developer.zendesk.com/documentation/api-basics/getting-started/installing-and-using-curl/#move-json-data-to-a-file)
SAPI_Model := "whisper-1"
SAPI_Prompt := "comma, period, new paragraph"
SAPI_AudioFile := "C:\Users\yourname\Desktop\Recording.m4a"

ChatGPT_Prompt := "   Write out a random title, or 2, from Oscar Wilde's collection: `"The Happy Prince and Other Tales`".   "			; double-quote escaping is a headache

ChatGPT_Prompt := RegExReplace(ChatGPT_Prompt, "\R", "\n")				
ChatGPT_Prompt := Trim(ChatGPT_Prompt)
ChatGPT_Prompt := StrReplace(ChatGPT_Prompt, "`"", "\\\`"")

;; MsgBox(ChatGPT_Prompt)

API_Endpoint := API_URL . A_Space

SAPI_Endpoint := SAPI_URL . A_Space

Key_Header :=  "-H `"Authorization: Bearer " . API_Key . "`"" . A_Space

API_ContentType_Header :=  "-H `"Content-Type: application/json" . "`"" . A_Space

SAPI_ContentType_Header :=  "-H `"Content-Type: multipart/form-data" . "`"" . A_Space

API_Data := "-d " . "`"{\`"model\`": \`"" . API_Model . "\`", \`"messages\`": [{\`"role\`": \`"assistant\`", \`"content\`": \`"" . ChatGPT_Prompt . "\`"}]}`"" . A_Space

;; API_Data := "-d " . "`"@" . API_PromptFile . "`"" . A_Space

SAPI_Model_Form :=  "-F model=" . "`"" . SAPI_Model . "`"" . A_Space	

SAPI_ResponseFormat_Form := "-F response_format=" . "`"text`"" . A_Space	

SAPI_AudioFile_Form := "-F file=" . "`"@" . SAPI_AudioFile . "`"" . A_Space

SAPI_Prompt_Form := "-F prompt=" . "`"" . SAPI_Prompt . "`"" . A_Space

PipetoClip := "| clip"

API_Curling := "curl " . API_Endpoint . Key_Header . API_ContentType_Header . API_Data . PipetoClip

SAPI_Curling := "curl " . SAPI_Endpoint . Key_Header . SAPI_ContentType_Header . SAPI_Model_Form . SAPI_ResponseFormat_Form . SAPI_AudioFile_Form . SAPI_Prompt_Form . PipetoClip


F4::
{
    RunWaitOne(API_Curling)
}


F5::
{
    RunWaitOne(SAPI_Curling)
}


;;;; https://www.autohotkey.com/docs/v2/lib/Run.htm#ExStdOut
RunWaitOne(command) 
{
    shell := ComObject("WScript.Shell")
    ; Execute a single command via cmd.exe
    exec := shell.Exec(A_ComSpec " /C " command)
    ; Read and return the command's output
    return exec.StdOut.ReadAll()
}
