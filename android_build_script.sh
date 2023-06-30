#!/bin/bash -i
###############################################################################
#
#                      TCC805x Android Toolchain Downloader
#
###############################################################################

###############################################################################
#                      Please Select the options
###############################################################################
#Select android_12_version=1 or =2
android_12_version=1

#Select Platform 
#bit=64 (default) or bit=32
bit=64

#Select SoC family 
#chip=tcc8050 (default) or chip=tcc8053 or chip=tcc8059
chip=tcc8050

#Select Board
#board=evb_sv1.0 (default) or board=evb_sv0.1
board=evb_sv1.0

#Select Core Number for build
#core_numbers=8
core_numbers=8

#Select envsetup
#48. car_tcc803xp_arm64-eng
#49. car_tcc8050_arm64-eng (default)
#50. car_tcc8059_arm64-eng 
envsetup=49

#Select gpuvz (GPU Virtualization)
#gpuvz=0 (default) or gpuvz=1
gpuvz=0

#Select subcore image
#subcore_image=0 (from own build)
#subcore_image=1 (subcore cluster, it will enable gpuvz)
#subcore_image=2 (default)
subcore_image=2

#eMMC or UFS
#eMMC=1 (default) or eMMC=0 (=UFS)
eMMC=1
###############################################################################
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

export CMD_V_BUILD_OPTION=

function FUNC_get_filename() {
    url="$1"
    filename=$(basename "$url")
    echo "$filename"
}

function FUNC_get_filename_without_extension() {
    filename="$1"
    filename_without_extension="${filename%.*.*}"
    echo "$filename_without_extension"
}

function FUNC_Install_Toolchain() {
    filename=$(FUNC_get_filename $1)
    dir_name=$(FUNC_get_filename_without_extension $filename)
    bin_name=$dir_name/bin    

    #If there is no tzr.xz -> download
    if [ ! -f $filename ];
    then
        echo Start download $filename
        wget $1
    fi

    #If there is no dir_name -> decompress tar.xz
    if [ ! -d $dir_name ];
    then
        echo Start decompress $filename
        tar -xvf $filename
    fi

    #IF param1 is not exist in PATH -> add it to PATH
    if [[ ! "$PATH" == *$bin_name* ]]
    then
        echo Start add $bin_name to PATH
        export PATH=$PATH:$PWD/$bin_name
        #remove the duplicated PATH
        export PATH="$(perl -e 'print join(":", grep { not $seen{$_}++ } split(/:/, $ENV{PATH}))')"
        echo $PATH
        echo 'export PATH=$PATH':$PWD/$bin_name >> ~/.bashrc
    fi
}

function FUNC_Bootloader_Toolchain()
{
    echo start FUNC_Bootloader_Toolchain
    FUNC_Install_Toolchain https://developer.arm.com/-/media/Files/downloads/gnu-a/9.2-2019.12/binrel/gcc-arm-9.2-2019.12-x86_64-arm-none-linux-gnueabihf.tar.xz
    FUNC_Install_Toolchain https://developer.arm.com/-/media/Files/downloads/gnu-a/9.2-2019.12/binrel/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu.tar.xz
    echo end FUNC_Bootloader_Toolchain
}

function FUNC_Kernel_Toolchain()
{
    echo start FUNC_Kernel_Toolchain
    #Check Android12 SDK version
    if [[ $android_12_version == 1 ]]; then
        FUNC_Install_Toolchain https://releases.linaro.org/archive/14.09/components/toolchain/binaries/gcc-linaro-aarch64-linux-gnu-4.9-2014.09_linux.tar.xz
        android_12_version=1
    elif [[ $android_12_version == 2 ]]; then
        FUNC_Install_Toolchain https://releases.linaro.org/components/toolchain/binaries/7.2-2017.11/aarch64-linux-gnu/gcc-linaro-7.2.1-2017.11-x86_64_aarch64-linux-gnu.tar.xz
    else
        echo -e "\n                                Unknown Android12 SDK version"
        exit
    fi
    echo end FUNC_Kernel_Toolchain
}

function FUNC_check_default_revision()
{
    #echo start FUNC_check_default_revision
    local file=../.repo/manifest.xml
    local content=$(cat "$file")

    #extract default revision from XML file
    local revision=$(echo "$content" | grep -oP '(?<=<default revision=")[^"]+')

    #Check the version
    if [[ $revision == *"Android12_IVI_v1.0.0"* ]]; then
        echo -e "\n                                TCC805x Android12 IVI SDK version is ${green}V1.0.0${reset}"
        android_12_version=1
    elif [[ $revision == *"Android12_IVI_v2.0.0"* ]]; then
        echo -e "\n                                TCC805x Android12 IVI SDK version is ${green}V2.0.0${reset}"
        android_12_version=2
    else
        echo -e "\n                                Unknown SDK version"
        exit
    fi
    #echo end FUNC_check_default_revision
}

function FUNC_print_current_setting()
{
    #echo start FUNC_print_current_setting
    echo bit = ${bit}
    echo chip = ${chip}
    echo board = ${board}
    echo -e "core_numbers = ${core_numbers} (make -j${core_numbers})"
    echo -e "envsetip = ${envsetup} (lunch ${envsetup})"
    echo
    #echo end FUNC_print_current_setting
}

function FUNC_Env_Setup()
{
    echo start FUNC_Env_Setup
    pushd $PWD
    cd ../maincore/
    source build/envsetup.sh
    lunch ${envsetup}
    popd
    echo end FUNC_Env_Setup
}
function FUNC_Build_Bootloader()
{
    echo start FUNC_Build_Bootloader
    pushd $PWD
    cd ../maincore/bootable/bootloader/u-boot/

    if [[ $bit == 32 ]]; then
        export ARCH=arm
        CROSS_COMPILE=arm-none-linux-gnueabihf-
    elif [[ $bit == 64 ]]; then
        export ARCH=arm64
	    export CROSS_COMPILE=aarch64-none-linux-gnu-
    else
        echo -e "Unknown bit"
        exit
    fi
    
    export DEVICE_TREE=${chip}-${board}
    make tcc805x_android_12_defconfig
    make -j${core_numbers}
    cd -
    popd
    echo end FUNC_Build_Bootloader
}

function FUNC_Build_Kernel_V1()
{
    echo start FUNC_Build_Kernel_V1
    pushd $PWD

    #Check Android12 SDK version
    if [[ $android_12_version == 1 ]]; then
        cd ../maincore
        unset ARCH
        unset CROSS_COMPILE
        cd prebuilts/clang/host/linux-x86/clang-r416183b1/bin/
        export PATH=$PWD:$PATH
        clang --version
        export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
        cd -
        cd kernel
        make ARCH=arm64 LLVM=1 tcc805x_android_12_ivi_defconfig
        make ARCH=arm64 LLVM=1 -k CC=clang -j${core_numbers}
        cd -
    elif [[ $android_12_version == 2 ]]; then
        cd ../maincore/device/telechips/car_tcc805x-kernel
        sdk_dir=$PWD
        cd -
        cd ../kernel
        export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LLVM=1
        BUILD_CONFIG=common/build.config.gki.tcc805x_aarch64 DIST_DIR=$sdk_dir build/build_abi.sh -j8
        cd -
    else
        echo -e "\n                                Unknown Android12 SDK version"
        exit
    fi


    popd
    echo end FUNC_Build_Kernel_V1
}
function FUNC_Build_Framework()
{
    echo start FUNC_Build_Framework
    pushd $PWD
    cd ../maincore
    make -j${core_numbers}
    cd -
    popd
    echo end FUNC_Build_Framework
}

function FUNC_use_mktcimg()
{
    echo start FUNC_use_mktcimg
    pushd $PWD
    uboot_dir=$PWD/../maincore/bootable/bootloader/u-boot
    car_tcc8050_arm64_dir=$PWD/../maincore/out/target/product/car_tcc8050_arm64
    echo ${uboot_dir}
    echo ${car_tcc8050_arm64_dir}

    #Check subcore_image type
    if [[ $subcore_image == 0 ]]; then #own build subcore
        cd ../subcore/build/tcc8050-sub/tmp/deploy/images/tcc8050-sub
    elif [[ $subcore_image == 1 ]]; then #prebuilt subcore_cluster
        cd ../maincore/device/telechips/car_tcc8050_arm64/subcore_cluster
    elif [[ $subcore_image == 2 ]]; then #prebuilt subcore (default)
        cd ../maincore/device/telechips/car_tcc8050_arm64/subcore
    else
        echo -e "\n                                Unknown subcore_image type"
        exit
    fi

    cp ca53_bl3.rom ${uboot_dir}
    cp tc-boot-tcc8050-sub.img telechips-subcore-image-tcc8050-sub.ext4 tcc8050-linux-subcore_sv1.0-tcc8050-sub.dtb ${car_tcc8050_arm64_dir}
    
    if [[ $eMMC == 1 ]]; then #In case of eMMC
        cd ${uboot_dir}/boot-firmware/tools/mktcimg 
        ./mktcimg --parttype gpt --storage_size 7818182656  --fplist gpt_partition_for_arm64.list --outfile SD_Data.fai --area_name "SD Data" --gptfile SD_Data.gpt -l 4096 
    elif [[ $eMMC == 0 ]]; then #In case of UFS
        cd ${uboot_dir}/boot-firmware/tools/mktcimg 
        ./mktcimg --parttype gpt --storage_size 31998345216 --fplist gpt_partition_for_arm64.list --outfile SD_Data.fai --area_name "SD Data" --gptfile SD_Data.gpt --sector_size 4096 
    else
        echo -e "\n                                Unknown memory type (eMMC or UFS)"
        exit
    fi

    popd
    echo end FUNC_use_mktcimg
}

function FUNC_Make_SNOR_ROM_Image ()
{
    echo start FUNC_Make_SNOR_ROM_Image
    pushd $PWD
    uboot_dir=$PWD/../maincore/bootable/bootloader/u-boot
    TCC8050_prebuilt_dir=${uboot_dir}/boot-firmware/tools/tcc805x_snor_mkimage/
        
    echo ${uboot_dir}
    echo ${TCC8050_prebuilt_dir}

    cd ${TCC8050_prebuilt_dir}
    ./tcc805x-snor-mkimage -i tcc8050.cs.cfg -o ./tcc805x_snor.cs.rom
    popd
    echo end FUNC_Make_SNOR_ROM_Image
}

function FUNC_main_menu()
{
	while [ -z $CMD_V_BUILD_OPTION ]
    do    
		clear

        echo "******************************************************************************************************************"
        FUNC_check_default_revision
        FUNC_print_current_setting
        echo "******************************************************************************************************************"
        echo "|  1. Build All-in-one"
        echo "|   - Install Bootloader Toolchain"
        echo "|   - Install Kernel Toolchain for ${green}V${android_12_version}.0.0${reset}"
        echo "|   - Set Up Compiling Environment"
        echo "|   - Build Bootloader / Kernel / Framework"
        echo "|   - Make SD_Data.fai"
        echo "|   - Make SNOR ROM Image"
		echo "+----------------------------------------------------------------------------------------------------------------+"
        echo "|  2. Install Toolchain for TCC805x Android12 IVI ${green}V${android_12_version}.0.0${reset}"
        echo "|   - Bootloader Toolchain for TCC805x Android12"
        echo "|   - Kernel Toolchain for TCC805x Android12 ${green}V${android_12_version}.0.0${reset}"
        echo "+----------------------------------------------------------------------------------------------------------------+"
        echo "|  3. Set Up Compiling Environment"
        echo "|   - Env : lunch ${envsetup}"
        echo "+----------------------------------------------------------------------------------------------------------------+"
        echo "|  4. Build Bootloader only"
        echo "|   - bootloader build : default - 64 bit / TCC805x / TCC8050 EVB 1.0 / Maincore"
        echo "|   - make tcc805x_android_12_defconfig / make -j${core_numbers}"
		echo "+----------------------------------------------------------------------------------------------------------------+"
        echo "|  5. Build Kernel only"
        echo "|   - make ARCH=arm64 LLVM=1 tcc805x_android_12_ivi_defconfig"
		echo "+----------------------------------------------------------------------------------------------------------------+"
        echo "|  6. Build Framework only"
        echo "|   - default : make -j${core_numbers}"
		echo "+----------------------------------------------------------------------------------------------------------------+"
        echo "|  7. Make SD_Data.fai (+Copy the prebuilt SubCore images)"
        echo "+----------------------------------------------------------------------------------------------------------------+"
        echo "|  8. Make SNOR ROM Image"
        echo "+----------------------------------------------------------------------------------------------------------------+"
        echo "|  0. exit"
		echo "******************************************************************************************************************"
        echo -n -e "\n${green}Which command would you like ? [0]:${reset} "

	   	read CMD_V_BUILD_OPTION
    done

    echo
    echo "Option Number : $CMD_V_BUILD_OPTION"
    echo

    case $CMD_V_BUILD_OPTION in
    1) #Build All-in-one
    FUNC_Bootloader_Toolchain
    FUNC_Kernel_Toolchain
    FUNC_Env_Setup
    FUNC_Build_Bootloader
    FUNC_Build_Kernel_V1
    FUNC_Build_Framework
    FUNC_use_mktcimg
    FUNC_Make_SNOR_ROM_Image
    ;;
    2) #Install Toolchain for TCC805x Android12 IVI
    FUNC_Bootloader_Toolchain
    FUNC_Kernel_Toolchain
    ;;
    3) #Set Up Compiling Environment
    FUNC_Env_Setup
    ;;
    4) #Build Bootloader only
    FUNC_Env_Setup
    FUNC_Build_Bootloader
    ;;
    5) #5. Build Kernel only
    FUNC_Env_Setup
    FUNC_Build_Kernel_V1
    ;;
    6) #6. Build Framework only
    FUNC_Env_Setup
    FUNC_Build_Framework
    ;;
    7) #7. Make SD_Data.fai (+Copy the prebuilt SubCore images)
    FUNC_use_mktcimg
    ;;
    8) #8. Make SNOR ROM Image
    FUNC_Make_SNOR_ROM_Image
    ;;
    9) #
    echo
    ;;
    esac
}

##############################
FUNC_main_menu
