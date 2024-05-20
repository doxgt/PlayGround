#Requires AutoHotkey v2
#SingleInstance

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
/*
Below are the simplest examples that merely serve as proofs of concept.
Replace "yourChoiceofAPIkey" with actual API key, of course.
Replace path-to-audio-file with actual path and name.
You should have already recorded an audio file for transcription.
Press F2 or F3. Once CMD window disappears, press Ctrl-V in any text field to confirm results are as expected.
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


F2::
{
Run A_ComSpec ' /c curl https://api.openai.com/v1/audio/transcriptions -H "Authorization: Bearer yourChoiceofAPIkey" -H "Content-Type: multipart/form-data" -F model="whisper-1" -F response_format="text" -F file="@C:/Users/username/Desktop/WhisperAudioTest.m4a" -F prompt="comma, period, new paragraph" | clip'
}


F3::
{
Run A_ComSpec ' /c curl https://api.openai.com/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer yourChoiceofAPIkey" -d "{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"assistant\", \"content\": \"Write out a random aphorism by Oscar Wilde\"}]}" | clip'
}
