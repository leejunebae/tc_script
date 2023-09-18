# tc_script
Telechips Singapore Branch's Scripts 

[Branches]
1. TCC805x_Android_IVI
- Tested: 

TCC805x Android 12 IVI V1.0.0 / V2.0.0
TCC805x Android 13 IVI V1.0.0

- How to download

git clone https://github.com/leejunebae/tc_script -b TCC805x_Android_IVI

- Include:
1) android_fwdn_script.bat
    * example for FWDN (firmware downloader)
    * can be executed in Windows OS
    * need to connect UART serial port to command
    * need to connect USB to flash

2) android_fastboot_script.bat 
    * Bootloader / Kernel / Framework / Partition update
    * can be executed in Windows OS
    * need to connect UART serial port to command
    * need to connect USB to flash

3) android_build_script.sh
    * can be executed in Linux Build Server
    * help to download compiler
    * help to build all in one
    * help to build separately

2. TCC805x_Linux_IVI_K5.4
- Tested:
    TCC805x Linux IVI K5.4 V1.0.0

- How to download
git clone https://github.com/leejunebae/tc_script -b TCC805x_Linux_IVI_K5.4

- Include:
1) linux_fastboot_script.bat
    * example for FWDN (firmware downloader)
    * can be executed in Windows OS
    * need to connect UART serial port to command
    * need to connect USB to flash

2) linux_fwdn_script.bat
    * Bootloader / Kernel / Framework / Partition update
    * can be executed in Windows OS
    * need to connect UART serial port to command
    * need to connect USB to flash

[How to use]
Please refer to the Goolge Docs for Android / Linux

- Tips for Telechips Android SDK

https://docs.google.com/document/d/1jI40JVIoNqPvg69y-HP6R0ec_gmCSVqBJDRB38RkXXI/edit?usp=sharing

- Tips for Telechips Linux SDK

https://docs.google.com/document/d/1SRh5nKXnifAhr3n4erQ5aldCf0P9OENO956mPA0F2zg/edit?usp=sharing

- Getting Started with Telechips FAE

https://docs.google.com/document/d/1iim-aTa__SQsdgVSiWM9uJdL3P0hd-4nkLU86tk2a0U/edit?usp=sharing
