::If you use Android12 V2.0.0 = 1, V1.0.0 = 0 
set V2=0

::If you are using TeraTerm
set TERATERM=1

::Set your COM port number for serial port. For example should be same as TeraTerm
::PC to EVB maincore serial port should be connected
set COM_PORT_NUMBER=COM4

::Maincore Images
set SDK_PATH=Z:\TCC805x\A12

::need to set ANDROID_PRODUCT_OUT to use fastboot
set ANDROID_PRODUCT_OUT=%SDK_PATH%\maincore\out\target\product\car_tcc8050_arm64

::change the EVB to fastboot mode

IF %TERATERM%==1 (
    ::please close the serial port related program.
    taskkill /im ttermpro.exe /t /f
)
echo su > %COM_PORT_NUMBER%
echo setprop sys.usb.config host,adb > %COM_PORT_NUMBER%
echo reboot bootloader > %COM_PORT_NUMBER%

IF %TERATERM%==1 (
    start /max /d "C:\Program Files (x86)\teraterm\" ttermpro.exe 
)

::please refer to ./bootloader/u-boot/boot-firmware/tools/mktcimg/gpt_partition.list
fastboot flash boot_a %ANDROID_PRODUCT_OUT%\boot.img
fastboot flash vbmeta_a %ANDROID_PRODUCT_OUT%\vbmeta.img
fastboot reboot

::in case of V2.0.0, need to fastboot reboot twice
IF %V2%==1 (
    timeout /t 5
    fastboot reboot
)
pause