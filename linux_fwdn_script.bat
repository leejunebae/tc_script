@echo on
cd ..
set FWDN=%cd%\FWDN

IF NOT EXIST %FWDN% (
    mkdir FWDN
    copy build-autolinux\fwdn_v8\out\fwdn.exe FWDN
    copy build-autolinux\fwdn_v8\out\VtcUsbPort.dll FWDN
)
::Location of TCC805x Linux SDK 
set LINUX_SDK_PATH=%cd%\build-autolinux

::BOOT_FIRMWARE directoy have .json files for fwdn
set BOOT_FIRMWARE=%LINUX_SDK_PATH%\build\tcc8050-main\tmp\deploy\images\tcc8050-main\boot-firmware

::Please make SD_Data.fai first. Please refer to the Linux Getting Started first.
set SD_DATA=%LINUX_SDK_PATH%\build\tcc8050-main\tmp\deploy\fwdn\

::PREBUILT directoy have "tcc8050_snor.cs.rom" for SNOR, MICOM R5.
set PREBUILT=%LINUX_SDK_PATH%\boot-firmware_tcc805x\prebuilt

cd FWDN
fwdn.exe --fwdn %BOOT_FIRMWARE%\fwdn.json
fwdn.exe --storage emmc --low-format 
fwdn.exe --storage snor --low-format 
fwdn.exe --write %BOOT_FIRMWARE%\boot.json 
fwdn.exe --write %SD_DATA%\SD_Data.fai --storage emmc --area user 
fwdn.exe --write %PREBUILT%\tcc8050_snor.cs.rom --storage snor --area die1
cd ..
@pause
