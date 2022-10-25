cls
@echo off
rem ------------------------------------------------------------------------------------------------------------------------------
rem -- This file requires a diamondInstallationPath.txt to be in the same folder in order to point at the right path where Diamond installation is at
rem -- CEB 12.07.2022

:init
rem Set Diamond installation path variable, including version number
set modifiedPath=C:\lscc\diamond\3.12
rem Returns path at which this script is running and store it in scriptPath variable
for %%i in ("%~dp0.") do SET "scriptPath=%%~fi"
set dependenciesPath=%scriptPath%\Dependencies
if not exist %dependenciesPath% (
    echo --------------------------------------
    echo -- ERROR:                           --
    echo -- .\Dependencies folder not found! --
    echo -- Make sure folder is not corrupt  --
    echo -- or missing folders               --
    echo --------------------------------------
    pause
    goto :eof
)
rem promgenPath assumes that promgen is available in Windows environmental variables
rem It will try to run it locally if binary file generation is unsuccessful
set promgenPath=promgen
echo ------------------------------------------------------------------------------------------------------
echo BIT 2 HEX/BIN Generator v3.0 - CEB 13.07.2022
echo I've created this batch file that will generate an SPI Flash binary (MCS) or Binary (BIN)
echo from a Bitstream and automatically converts it to a HEX or BIN file, to be used with FlashCatUSB
echo Some versions of FlashCatUSB will not flash the binary correctly if the extension is not HEX/BIN
echo.
rem Set default values
set compress=on
set device=
set address=0x00000000
set mirror= -mirror
set frequency=

set pathTxtPath=%dependenciesPath%\diamondInstallationPath.txt
goto :pathTxtCheck

rem Check if diamondInstallationPath.txt exists in dependencies folder
:pathTxtCheck
if not exist %pathTxtPath% goto :pathTxtMissing
goto :menuSelection

:menuSelection
echo Choose an option below:
echo 1: Convert .BIT to .HEX
echo 2: Convert .BIT to .BIN
echo 3: Convert .MCS to .BIN
echo 4: Change binary generation options (Compression, device, address, frequency and byte mirror)
echo 5: Exit script
echo ------------------------------------------------------------------------------------------------------
%SystemRoot%\System32\choice.exe /c 12345 /m "Please, enter an option (default is .HEX from .BIT)"
if %errorlevel% equ 2 (
(
    echo Starting BIT2BIN conversion
    set convType=BIN
    goto :setPaths
)
)
if %errorlevel% equ 3 (
    echo Starting MCS2BIN conversion
    set convType=MCS2BIN
    goto :setPaths
)
rem set convType=BIT2BIN
if %errorlevel% equ 4 goto :subMenuSelection 
if %errorlevel% equ 5 goto eof
rem Standard option 1 - BIT2HEX
echo Starting BIT2HEX conversion
set convType=HEX
goto :setPaths
pause
goto :eof

:subMenuSelection
cls
echo ------------------------------------------------------------------------------------------------------
echo Custom binary generation options
echo 1: Enable/Disable Compression (default: -compress on)
echo 2: Force device type (default from bitstream)
echo 3: Change memory start address (default 0x00000000)
echo 4: Custom frequency selection (default from bitstream)
echo 5: Enable/Disable byte mirror (Only applies for Bin to Hex - default enabled)
echo 6: Main Menu
echo ------------------------------------------------------------------------------------------------------
%SystemRoot%\System32\choice.exe /c 123456 /m "Please, enter an option:"
if %errorlevel% equ 1 goto :customCompression
if %errorlevel% equ 2 goto :customDevice
if %errorlevel% equ 3 goto :customAddress
if %errorlevel% equ 4 (
    cls
    echo ------------------------------------------------------------------------------------------------------
    echo Option 4: Custom frequency selection
    echo Possible frequencies for LFE5U are 2.4, 3.2, 4.1, 4.8, 6.5, 8.2, 9.7, 12.9, 15.5, 16.3, 19.4, 20.7, 25.8, 31, 34.4, 38.8, 44.3, 51.7, 62, 77.5, 103.3, and 155 MHz
    echo ------------------------------------------------------------------------------------------------------
    goto :customFrequency
)
if %errorlevel% equ 5 goto :customMirror
cls
goto :menuSelection

:customCompression
cls
echo ------------------------------------------------------------------------------------------------------
echo Option 1: Custom binary generation options
echo 1: Enable Compression (-compress on)
echo 2: Disable Compression (-compress off)
echo ------------------------------------------------------------------------------------------------------
%SystemRoot%\System32\choice.exe /c 12 /m "Please, enter an option:"
if %errorlevel% equ 2 (
    echo Compression disabled
    set compress=off
    goto :subMenuSelection
) 
echo Compression enabled
set compress=on
goto :subMenuSelection

:customDevice
cls
echo ------------------------------------------------------------------------------------------------------
echo Option 2: Enter custom device:
echo ------------------------------------------------------------------------------------------------------
set /p device=
if "%device%"=="" (
    echo Empty, will use default from bitstream
    set device=
) else (
    echo Device set to %device%
    set device= -dev %device%
)
goto :subMenuSelection

:customAddress
cls
echo ------------------------------------------------------------------------------------------------------
echo Option 3: Enter custom start address (format as per example: 0x00000000)
echo ------------------------------------------------------------------------------------------------------
set /p address=
echo Initial address set to %address%
goto :subMenuSelection

:customFrequency
set /p frequency=
FOR %%a in (2.4 3.2 4.1 4.8 6.5 8.2 9.7 12.9 15.5 16.3 19.4 20.7 25.8 31 34.4 38.8 44.3 51.7 62 77.5 103.3 155) do if %frequency%==%%a (
    set frequency= -frequency %frequency%
    goto :subMenuSelection
)
cls
echo ------------------------------------------------------------------------------------------------------
echo NOTICE: Invalid Frequency!
echo Choose from one of possible frequencies:
echo Possible frequencies for LFE5U are 2.4, 3.2, 4.1, 4.8, 6.5, 8.2, 9.7, 12.9, 15.5, 16.3, 19.4, 20.7, 25.8, 31, 34.4, 38.8, 44.3, 51.7, 62, 77.5, 103.3, and 155 MHz
echo ------------------------------------------------------------------------------------------------------
goto :customFrequency

:customMirror
cls
echo ------------------------------------------------------------------------------------------------------
echo Option 5: Mirror byte order options
echo 1: Enable Mirror (default)
echo 2: Disable Mirror
echo ------------------------------------------------------------------------------------------------------
%SystemRoot%\System32\choice.exe /c 12 /m "Please, enter an option: "
if %errorlevel% equ 2 (
    echo Byte order mirror disabled
    set mirror=
    goto subMenuSelection
) 
echo Byte order mirror enabled
set mirror= -mirror
goto :subMenuSelection

rem Set path to ddtcmd
:setPaths
set /p diamondPath=<%pathTxtPath%
if not exist "%diamondPath%" goto :modifyPath

rem set diamondPath=%diamondPath:/=\%
rem Remaining address to ddtcmd is static, might need to be changed in the future if ddtcmd.exe moves somewhere else
set ddtcmdPath="bin\nt64"

rem Combine two Diamond + ddtcmdPath for ddmcmd.exe complete path and set complete path to directory
set COMBINED=%diamondPath:"=%\%ddtcmdPath:"=%
set ddtcmdExe=%COMBINED%\ddtcmd.exe

set ddtcmdExe=%ddtcmdExe:/=\%
echo Path to ddtcmd.exe: %ddtcmdExe%
rem echo ;%PATH%; | %SystemRoot%\System32\find /C /I ";%COMBINED%;"
goto :checkDdt

:checkDdt
if not exist "%ddtcmdExe%" goto :ddtcmdMissing
goto :validateBitInput

:runScript
echo ----------------------------------------------------------
echo ddtcmd.exe found
set mcsFullPath=%hexPath%\%hexName%.mcs
set hexFullPath=%hexPath%\%hexName%.hex
set binFullPath=%hexPath%\%hexName%.bin
rem ddtcmd -oft -rbt%device% -if %bitstreamPath%%frequency% -compress %compress% -of %mcsFullPath%
if %convType% equ BIN (
    
    echo Start BIT to BIN conversion...
    %ddtcmdExe% -oft -int%device% -if "%bitstreamPath%"%frequency% -compress %compress% -address %address%%mirror% -of "%mcsFullPath%"
    if not exist "%binFullPath%" goto :mcs2Bin
    goto :delOldBin

) else (

    if %convType% equ HEX (
    
        echo Start BIT to HEX conversion...
        %ddtcmdExe% -oft -int%device% -if "%bitstreamPath%"%frequency% -compress %compress% -address %address%%mirror% -of "%mcsFullPath%"
        if not exist "%hexFullPath%" goto :mcs2Hex
        goto :delOldHex
    
    ) else (

        if %convType% equ MCS2BIN (
        
            echo Start MCS to BIN conversion...
            set mcsFullPath=%bitstreamPath%
            if not exist "%binFullPath%" goto :mcs2Bin
            goto :delOldBin
        
        ) else (
    
    
    
    
        echo ----------------------------------------------------------
        echo ERROR: INVALID CONVERSION TYPE!
        echo ----------------------------------------------------------
        goto :eof
    )
)

:validateBitInput
echo Please, provide full path to bitstream ".bit" or ".mcs" (e.g. c:\PROG_DEV\CA20-2331\CA20-2331.bit)
rem Open application that lets user select file
set bitstreamPath=

rem Run FileChooser.bat
call %dependenciesPath%\FileChooser.bat
    
echo Selected file %fileName%
set bitstreamPath=%fileName%
set fileName=
echo Chosen input file %bitstreamPath%

rem set /p bitstreamPath=
rem Check if user input path to bitstream is empty
if "%bitstreamPath%" equ "" (
    echo ------------------------------------------------------------------------
    echo WARNING:
    echo Equals null
    echo Path can't be empty
    echo ------------------------------------------------------------------------
    goto :validateBitInput
)
if "%convType%" equ "MCS2BIN" (
    rem Check if user input path does not include .mcs at the end
    echo %bitstreamPath:~-4%
    if "%bitstreamPath:~-4%" neq ".mcs" (
        echo ------------------------------------------------------------------------
        echo WARNING:
        echo .MCS not included
        echo Path does not include .mcs file
        echo Please include filename with .mcs at the end of the path
        echo ------------------------------------------------------------------------
        goto :validateBitInput
    )
)
if "%convType%" equ "BIN" (
    rem Check if user input path does not include .bit at the end
    if "%bitstreamPath:~-4%" neq ".bit" (
        echo ------------------------------------------------------------------------
        echo WARNING:
        echo Path does not include .bit file
        echo Please include filename with .bit at the end of the path
        goto :validateBitInput
        echo ------------------------------------------------------------------------
    )
)
rem Correct path if slash is used instead of backslashes
set bitstreamPath=%bitstreamPath:/=\%
rem Verify that .bit file actually exists
if not exist "%bitstreamPath%" (
    echo ------------------------------------------------------------------------
    echo WARNING:
    echo Specified bitstream could not be found . . .
    echo Please verify that path is correct
    echo ------------------------------------------------------------------------
    goto :validateBitInput
)

goto :validateHexName

:validateHexName
echo What would you like the output file to be called? (e.g. CA20-2331)
set /p hexName=
if "%hexName%" equ "" (
    echo ------------------------------------------------------------------------
    echo INFO:
    echo Filename will be set as unnamed
    echo ------------------------------------------------------------------------
    set hexName=unnamed
    goto :validateHexPath
)
goto :validateHexPath

:validateHexPath
echo ------------------------------------------------------------------------
echo Please, provide path to output HEX/BIN file to be generated 
echo Do not add backslash "\" at the end of desired path! (e.g. c:\PROG_DEV\CA20-2331)
echo ------------------------------------------------------------------------
rem Opens file chooser
set hexPath=

rem Call FolderChooser.bat
call %dependenciesPath%\FolderChooser.bat
    
echo Selected folder: %folderName%
set hexPath=%folderName%

echo Chosen path for output HEX/BIN file %hexPath%

rem set /p hexPath=
if "%hexPath%" equ "" (
    echo ------------------------------------------------------------------------
    echo -- WARNING:
    echo -- HEX/BIN output path can't be empty, assigning default path to script folder
    echo ------------------------------------------------------------------------
    echo Script path: %scriptPath%
    set hexPath=%scriptPath%
    rem goto :validateHexPath
)
set hexPath=%hexPath:/=\%
rem check if last character is a \ or / and remove it
SET pathLastChar=%hexPath:~-1%
FOR %%a in (\ /) do if %pathLastChar%==%%a (
    set hexPath=%hexPath:~0,-1%
)
rem if not exist "%hexPath%" mkdir "%hexPath%"
goto :runScript

rem This function just renames MCS file to HEX
:mcs2Hex
ren "%mcsFullPath%" "%hexName%.hex"
rem Check if HEX file has been generated successfully
if not exist %hexFullPath% goto :genError 
rem %hexPath% goto :genError
echo ------------------------------------------------------------------------
echo BIT to HEX converter has generated HEX file successfully in:
echo %hexPath%
%SystemRoot%\explorer.exe /select, %hexFullPath%
echo ------------------------------------------------------------------------
pause
goto :eof

rem This function will run promgen to convert MCS to BIN
:mcs2Bin
echo ------------------------------------------------------------------------
echo Converting BIN from MCS . . .
echo ------------------------------------------------------------------------
echo %promgenPath% -p bin -r "%mcsFullPath%" -o "%binFullPath%"
%promgenPath% -p bin -r "%mcsFullPath%" -o "%binFullPath%"
rem Check if BIN file has been generated successfully
if not exist "%binFullPath%" goto :genError 
rem %hexPath% goto :genError
echo ------------------------------------------------------------------------
echo BIT to BIN converter has generated BIN file successfully in:
echo %hexPath%
%SystemRoot%\explorer.exe /select, %binFullPath%
echo ------------------------------------------------------------------------
pause
goto :eof

:delOldHex
echo ------------------------------------------------------------------------
echo Deleting existing HEX file with same name in %hexPath%
echo ------------------------------------------------------------------------
del "%hexFullPath%"
if exist %hexFullPath% goto :genError
goto :mcs2Hex


:delOldBin
echo ------------------------------------------------------------------------
echo INFO:
echo Deleting existing BIN file with same name in %hexPath%
echo ------------------------------------------------------------------------
del "%binFullPath%"
if exist %binFullPath% goto :genError
goto :mcs2Bin

rem Generate an error message if HEX file generated was unsuccessful
:genError
echo ------------------------------------------------------------------------
echo ERROR: 
echo Could not generate HEX/BIN file:
echo Possible reasons for the error:
echo    . Files are write protected (read-only)
echo    . A BIN file already exists (promgen will not automatically override
echo        files if they already exist, delete if needed!
echo ------------------------------------------------------------------------
pause
if "%convType%" neq "HEX" (

    echo ------------------------------------------------------------------------
    echo WARNING:
    echo LatticeBITConverter expects the machine running the script to have
    echo Xilinx ISE installed and promgen to be an "Environment variable" within
    echo Windows.
    echo LatticeBITConverter will try to run promgen from inside script .\Dependencies
    echo and this might have unintended consequences
    echo ------------------------------------------------------------------------
    echo Press to continue . . .
    pause
    cd %scriptPath%
    for /r %%a in (*promgen.exe) do (
        set promgenPath=%%a
        echo promgen.exe found in: %promgenPath%
        goto :mcs2Bin
    )
)
pause
goto :eof

:ddtcmdMissing
echo ----------------------------------------------------------
echo WARNING:
echo ddtcmd.exe not found, please point to correct Lattice Diamond installation folder, including version number folder (e.g. 3.12)
echo Current Lattice Diamond installation path: %diamondPath%
echo ------------------------------------------------------------------------
%SystemRoot%\System32\choice.exe /c yn /m "Press Y to modify path to Diamond installation folder now, N to exit"
if %errorlevel% equ 2 goto goto :eof
echo ----------------------------------------------------------
goto :modifyPath

:modifyPath
echo ------------------------------------------------------------------------
echo What is the path to Diamond installation, including version number? (e.g. C:\lscc\diamond\3.12)
@echo Do not add backslash "\" at the end of desired path!
echo ------------------------------------------------------------------------
rem Run FolderChooser.bat
call %dependenciesPath%\FolderChooser.bat
echo Selected folder name %folderName%
set modifiedPath=%folderName%
echo Chosen path for Diamond installation %modifiedPath%

echo ------------------------------------------------------------------------
echo INFO:
%SystemRoot%\System32\choice.exe /c yn /m "Is %modifiedPath% correct?"
if %errorlevel% equ 2 goto modifyPath 
set modifiedPath=%modifiedPath:/=\%
break>%pathTxtPath%
(echo %modifiedPath%)>>%pathTxtPath%
cls
goto :pathTxtCheck 

rem This function is not used anymore
:pathTxtMissing
echo diamondInstallationPath.txt does not exist inside .\Dependencies folder
echo Creating diamondInstallationPath.txt
break>%pathTxtPath%
goto :modifyPath

:eof
