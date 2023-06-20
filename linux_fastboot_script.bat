::Set your COM port number for serial port. For example should be same as TeraTerm
::PC to EVB maincore serial port should be connected
set COM_PORT_NUMBER=COM4

::If you are using TeraTerm
set TERATERM=1

::Maincore Images
cd ..
set LINUX_SDK_PATH=%cd%\build-autolinux
set MAINCORE_DEPLOY=%LINUX_SDK_PATH%\build\tcc8050-main\tmp\deploy
set BUILT_IMAGES_PATH_FWDN=%MAINCORE_DEPLOY%\fwdn\
set BUILT_IMAGES_PATH_MAIN=%MAINCORE_DEPLOY%\images\tcc8050-main

::Subcore Images
set BUILT_IMAGES_PATH_SUB=%LINUX_SDK_PATH%\build\tcc8050-sub\tmp\deploy\images\tcc8050-sub
set BOOT_FIRMWARE=%MAINCORE_DEPLOY%\images\tcc8050-main\boot-firmware

::PREBUILT directoy have "tcc8050_snor.cs.rom" for SNOR, MICOM R5.
set PREBUILT=%LINUX_SDK_PATH%\boot-firmware_tcc805x\prebuilt

::need to set ANDROID_PRODUCT_OUT to use fastboot, does not have to be correct directory.
set ANDROID_PRODUCT_OUT=Z:\

::change the EVB to fastboot mode
IF %TERATERM%==1 (
    ::please close the serial port related program.
    taskkill /im ttermpro.exe /t /f
)

::to input login and to input password (root) & (root)
echo root>%COM_PORT_NUMBER%
echo root>%COM_PORT_NUMBER%

::to change the EVB to fastboot mode
echo reboot bootloader>%COM_PORT_NUMBER%

IF %TERATERM%==1 (
    start /max /d "C:\Program Files (x86)\teraterm\" ttermpro.exe 
)

::please refer to build-autolinux\boot-firmware_tcc805x\tools\mktcimg\gpt_partition.list
fastboot flash boot_a %BUILT_IMAGES_PATH_MAIN%\tc-boot.img
fastboot reboot
pause
