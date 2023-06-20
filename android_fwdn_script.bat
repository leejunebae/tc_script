::Tested TCC805x Android12 V1.0.0
@echo on
::Location of TCC805x SDK 
set SDK_PATH=Z:\TCC805x\A12
set FWDN=%SDK_PATH%\FWDN

IF NOT EXIST %FWDN% (
    mkdir FWDN
    copy %SDK_PATH%\maincore\vendor\telechips\tools\FWDN\out\fwdn.exe FWDN
    copy %SDK_PATH%\maincore\vendor\telechips\tools\FWDN\out\VtcUsbPort.dll FWDN
)

::BOOT_FIRMWARE directoy have .json files for fwdn
set BOOT_FIRMWARE=%SDK_PATH%\maincore\bootable\bootloader\u-boot\boot-firmware

::Please make SD_Data.fai first. Please refer to the Android Getting Started first.
set SD_DATA=%SDK_PATH%\maincore\bootable\bootloader\u-boot\boot-firmware\tools\mktcimg

::PREBUILT directoy have "tcc8050_snor.cs.rom" for SNOR, MICOM R5.
set PREBUILT=%SDK_PATH%\maincore\bootable\bootloader\u-boot\boot-firmware\tools\tcc805x_snor_mkimage

cd FWDN
fwdn.exe --fwdn %BOOT_FIRMWARE%\tcc805x_fwdn.cs.json
fwdn.exe --storage emmc --low-format 
fwdn.exe --storage snor --low-format 
fwdn.exe --write %BOOT_FIRMWARE%\tcc805x_boot.cs.json
fwdn.exe --write %SD_DATA%\SD_Data.fai --storage emmc --area user 
fwdn.exe --write %PREBUILT%\tcc805x_snor.cs.rom --storage snor --area die1
cd ..
@pause