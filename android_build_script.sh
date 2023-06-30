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
#Value will be changed automatically after read .repo/manifest.xml
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
#Value will be changed automatically if you choose subcore=1 (subcore cluster)
gpuvz=0

#Select subcore image
#subcore_image=0 (from own build)
#subcore_image=1 (subcore cluster, will enable gpuvz)
#subcore_image=2 (default, subcore, non-cluster)
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
maincore_dir=$PWD/../maincore
subcore_dir=$PWD/../subcore
script_dir=$PWD
kernel_dir=

echo $maincore_dir
echo $subcore_dir
echo $script_dir

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

function FUNC_Install_Toolchain() 
{
    filename=$(FUNC_get_filename $1)
    dir_name=$(FUNC_get_filename_without_extension $filename)
    bin_name=$dir_name/bin    

    #If there is no tzr.xz -> download
    if [ ! -f $filename ];  then
        echo Start download $filename
        wget $1
    fi

    #If there is no dir_name -> decompress tar.xz
    if [ ! -d $dir_name ];  then
        echo Start decompress $filename
        tar -xvf $filename
    fi

    #IF param1 is not exist in PATH -> add it to PATH
    if [[ ! "$PATH" == *$bin_name* ]];   then
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
    cd $script_dir
    FUNC_Install_Toolchain https://developer.arm.com/-/media/Files/downloads/gnu-a/9.2-2019.12/binrel/gcc-arm-9.2-2019.12-x86_64-arm-none-linux-gnueabihf.tar.xz
    FUNC_Install_Toolchain https://developer.arm.com/-/media/Files/downloads/gnu-a/9.2-2019.12/binrel/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu.tar.xz
}

function FUNC_Kernel_Toolchain()
{
    cd $script_dir

    #Check Android12 SDK version
    case $android_12_version in
        1)  
        FUNC_Install_Toolchain https://releases.linaro.org/archive/14.09/components/toolchain/binaries/gcc-linaro-aarch64-linux-gnu-4.9-2014.09_linux.tar.xz
        ;;
        2)  
        FUNC_Install_Toolchain https://releases.linaro.org/components/toolchain/binaries/7.2-2017.11/aarch64-linux-gnu/gcc-linaro-7.2.1-2017.11-x86_64_aarch64-linux-gnu.tar.xz
        ;;
        *)  echo -e "\nUnknown Android12 SDK version" && exit   ;;
    esac    
}

function FUNC_check_default_revision()
{
    local file=$script_dir/../.repo/manifest.xml
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
}

function FUNC_print_current_setting()
{
	echo android_12_version = ${android_12_version}
    echo bit = ${bit}
    echo chip = ${chip}
    echo board = ${board}
    echo -e "core_numbers = ${core_numbers} (make -j${core_numbers})"
    echo -e "envsetip = ${envsetup} (lunch ${envsetup})"
    echo
}

function FUNC_Env_Setup()
{
    cd $maincore_dir
    source build/envsetup.sh
    lunch ${envsetup}
}
function FUNC_Build_Bootloader()
{
    cd $maincore_dir/bootable/bootloader/u-boot/

    case $bit in
        32) export ARCH=arm     CROSS_COMPILE=arm-none-linux-gnueabihf- ;;
        64) export ARCH=arm64   CROSS_COMPILE=aarch64-none-linux-gnu-   ;;
        *)  echo -e "Unknown bit" && exit ;;
    esac
    
    export DEVICE_TREE=${chip}-${board}
    make tcc805x_android_12_defconfig
    make -j${core_numbers}
}

function FUNC_set_gpuvz() 
{
    #Check subcore_image type
    case $subcore_image in
        1) gpuvz=1  ;;     #to use prebuilt subcore_cluster, gpuvz should be enabled
        *) echo "subcore_image=${subcore_image}";;
    esac

    file_path="$maincore_dir/device/telechips/car_tcc8050_arm64/device.mk"
    
    if [ "$gpuvz" -eq 0 ]; then
        sed -i 's/TCC_GPU_VZ  ?=  true/TCC_GPU_VZ  ?=  false/' "$file_path"
        echo "Modified TCC_GPU_VZ value to false."
    elif [ "$gpuvz" -eq 1 ]; then
        sed -i 's/TCC_GPU_VZ  ?=  false/TCC_GPU_VZ  ?=  true/' "$file_path"
        echo "Modified TCC_GPU_VZ value to true."
    else
        echo "Invalid gpuvz value. Must be 0 or 1."
        exit
    fi
    
    config_file=
    
    case $android_12_version in
        1)  config_file="$kernel_dir/arch/arm64/configs/tcc805x_android_12_ivi_defconfig"    ;;
        2)  config_file="$kernel_dir/common/arch/arm64/configs/telechips_gki_tcc805x.fragment"  ;;
        *)  echo -e "\nUnknown Android12 SDK version" && exit   ;;
    esac

    echo "$config_file"

    

    # Check and modify the CONFIG_POWERVR_VZ entry in the file
    if grep -q "CONFIG_POWERVR_VZ" "$config_file"; then
        if [ "$gpuvz" -eq 0 ]; then
            # Delete the line if gpuvz is 0 and the entry exists
            sed -i '/CONFIG_POWERVR_VZ/d' "$config_file"
            echo "Deleted the CONFIG_POWERVR_VZ entry."
        else
            echo "The CONFIG_POWERVR_VZ entry already exists."
        fi
    else
        if [ "$gpuvz" -eq 1 ]; then
            # Add CONFIG_POWERVR_VZ=y if gpuvz is 1 and the entry does not exist
            echo "CONFIG_POWERVR_VZ=y" >> "$config_file"
            echo "Added the CONFIG_POWERVR_VZ entry."
        else
            echo "The CONFIG_POWERVR_VZ entry does not exist."
        fi
    fi
}


function FUNC_Build_Kernel() {
    case $android_12_version in
        1)
            unset ARCH
            unset CROSS_COMPILE
            export PATH="$maincore_dir/prebuilts/clang/host/linux-x86/clang-r416183b1/bin/:$PATH"
            export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
            kernel_dir="$maincore_dir/kernel"
            cd "$kernel_dir"

            FUNC_set_gpuvz

            make ARCH=arm64 LLVM=1 tcc805x_android_12_ivi_defconfig
            make ARCH=arm64 LLVM=1 -k CC=clang -j"$core_numbers"
            cd -
            ;;
        2)
            sdk_dir="$maincore_dir/device/telechips/car_tcc805x-kernel"
            kernel_dir="$script_dir/../kernel"
            cd "$kernel_dir"
            export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LLVM=1

            FUNC_set_gpuvz

            BUILD_CONFIG=common/build.config.gki.tcc805x_aarch64 DIST_DIR="$sdk_dir" build/build_abi.sh -j"$core_numbers"
            ;;
        *)
            echo -e "\nUnknown Android12 SDK version" && exit
            ;;
    esac
}


function FUNC_Build_Framework()
{
    cd $maincore_dir
    make -j${core_numbers}
}

function FUNC_use_mktcimg()
{
    uboot_dir=$maincore_dir/bootable/bootloader/u-boot
    car_tcc8050_arm64_dir=$maincore_dir/out/target/product/car_tcc8050_arm64
    echo ${uboot_dir}
    echo ${car_tcc8050_arm64_dir}

    #Check subcore_image type
    case $subcore_image in
        0) cd "$subcore_dir/build/tcc8050-sub/tmp/deploy/images/tcc8050-sub" ;;         #own build subcore
        1) cd "$maincore_dir/device/telechips/car_tcc8050_arm64/subcore_cluster" ;;     #prebuilt subcore_cluster
        2) cd "$maincore_dir/device/telechips/car_tcc8050_arm64/subcore" ;;             #prebuilt subcore (default)
        *) echo -e "\nUnknown subcore_image type" && exit ;;
    esac

    cp ca53_bl3.rom ${uboot_dir}
    cp tc-boot-tcc8050-sub.img telechips-subcore-image-tcc8050-sub.ext4 tcc8050-linux-subcore_sv1.0-tcc8050-sub.dtb ${car_tcc8050_arm64_dir}

    cd ${uboot_dir}/boot-firmware/tools/mktcimg 

    case $eMMC in
        0) ./mktcimg --parttype gpt --storage_size 31998345216 --fplist gpt_partition_for_arm64.list --outfile SD_Data.fai --area_name "SD Data" --gptfile SD_Data.gpt --sector_size 4096 ;;
        1) ./mktcimg --parttype gpt --storage_size 7818182656 --fplist gpt_partition_for_arm64.list --outfile SD_Data.fai --area_name "SD Data" --gptfile SD_Data.gpt -l 4096 ;;
        *) echo -e "\nUnknown memory type (eMMC or UFS)" && exit ;;
    esac
}

function FUNC_Make_SNOR_ROM_Image ()
{
    uboot_dir=$maincore_dir/bootable/bootloader/u-boot
    TCC8050_prebuilt_dir=${uboot_dir}/boot-firmware/tools/tcc805x_snor_mkimage/
        
    echo ${uboot_dir}
    echo ${TCC8050_prebuilt_dir}

    cd ${TCC8050_prebuilt_dir}
    ./tcc805x-snor-mkimage -i tcc8050.cs.cfg -o ./tcc805x_snor.cs.rom
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
    FUNC_Build_Kernel
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
    FUNC_Build_Kernel
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
    FUNC_set_gpuvz
    ;;
    esac
}

##############################
FUNC_main_menu
