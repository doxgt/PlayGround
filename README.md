# PlayGround
By my reckoning, cURL provides the most straightforward and portable API interface to OpenAI (Groq, etc.) on Windows, especially on PCs that don't have Python already installed.

The GPT_cURL.ahk file contains working implementations of transcription and chat completions through cURL.

Thanks go to the maintainers of cURL, maintainers of AHK, and maker of fmedia/phiola (portable audio recorder with CLI).

NB: If working behind a proxy server, cURL command flags will need to be updated accordingly.

Added PostProcessing to enable basic formatting and manual punctuation in order to approximate a "Dragon-like" experience.  Auto-punctuations with period and comma are eliminated.  Of course, retaining auto-punctuation is as simple as commenting out "PostProcessing()".  It is trivial to make this feature user-switchable.

Following punctuations/formatting are supported: 
"no cap, cap, no space, spacebar, open/left paren, close/right paren, ellipsis, colon mark, number 1-5, new paragraph, comma, literal period, period, quotation mark, question mark, exclamation mark" ... basically anything contained in "Transcription_Prompt".

Any suggestion on improving postprocessing is appreciated!


Files last updated 2024-09-30.


P.S., the latest stable release of Phiola, as of 2024-12-03, is v2.2.8 (https://github.com/stsaz/phiola/releases/tag/v2.2.8).  The fastest way to test things out is to simply download its Zip package (https://github.com/stsaz/phiola/releases/download/v2.2.8/phiola-2.2.8-windows-x64.zip) and extract the "phiola-2" directory to Username/Desktop.  The rest is close to "plug-n-play".
