:: fchooser.bat
:: launches a folder chooser and outputs choice to the console
:: https://stackoverflow.com/a/15885133/1683264

@echo off

set "psCommand="(new-object -COM 'Shell.Application')^
.BrowseForFolder(0,'Choose a folder for the output HEX/BIN file',0,0).self.path""

for /f "usebackq delims=" %%I in (`powershell %psCommand%`) do set "folderName=%%I"

setlocal enabledelayedexpansion
echo You chose !folderName!

