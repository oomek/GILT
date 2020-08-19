@ECHO OFF
ECHO.
ECHO Updating G.I.L.T.
ECHO ------------------------
uploader -v -mmcu=TEENSY2 firmware.hex
IF %ERRORLEVEL% NEQ 0 ECHO UPDATE FAILED
IF %ERRORLEVEL% EQU 0 ECHO UPDATE SUCCESFUL
ECHO ------------------------
PAUSE
