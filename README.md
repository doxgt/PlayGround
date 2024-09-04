# PlayGround
By my reckoning, cURL provides the most straightforward and portable API interface to OpenAI on Windows, especially on PCs that don't have Python already installed.

The GPT_cURL.ahk file contains working implementations of transcription and chat completions through cURL.

Thanks go to the maintainers of cURL, maintainers of AHK, and maker of fmedia/phiola (portable audio recorder with CLI).

NB: If working behind a proxy server, cURL command flags will need to be updated accordingly.

Added PostProcessing to enable basic formatting and manual punctuation in order to deliver a "Dragon-like" experience.  Auto-punctuations with period and comma are eliminated.  

Following punctuations/formatting are supported: 
"no cap, cap, no space, open paren, close paren, left paren, right paren, ellipsis, colon mark, number one, spacebar, new paragraph, comma, literal period, period"

Any suggestion in improving postprocessing is appreciated!
