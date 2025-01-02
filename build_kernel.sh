#!/bin/bash

# export CROSS_COMPILE=$(pwd)/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-androidkernel-
export CROSS_COMPILE=$(pwd)/toolchain/toolchains-gcc-10.3.0/bin/aarch64-buildroot-linux-gnu-
export CC=$(pwd)/toolchain/clang/host/linux-x86/clang-r383902/bin/clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export ARCH=arm64
#export ANDROID_MAJOR_VERSION=r

export KCFLAGS=-w
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y

make clean
make mrproper

make -C $(pwd) O=$(pwd)/out KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y sudo_defconfig
make -C $(pwd) O=$(pwd)/out KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y -j32

cp out/arch/arm64/boot/Image $(pwd)/arch/arm64/boot/Image

cp out/arch/arm64/boot/Image.gz $(pwd)/arch/arm64/boot/Image.gz

TOKEN=7777656115:AAFrFOMWANR1yE069wHK1czDrM1zzqUFC-k

# Push ZIP to Telegram. 1 is YES | 0 is NO(default)
PTTG=1
	if [ $PTTG = 1 ]
	then
		# Set Telegram Chat ID
		CHATID=7448911714
	fi

 FILES=Image.gz-dtb
 DATE=$(TZ=Asia/Kolkata date +"%Y-%m-%d")

tg_post_msg() {
	curl -s -X POST "$BOT_MSG_URL" -d chat_id="$CHATID" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"

}

##---------------------------------------------------------##

tg_post_build() {
	#Post MD5Checksum alongwith for easeness
	MD5CHECK=$(md5sum "$1" | cut -d' ' -f1)

	#Show the Checksum alongwith caption
	curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
	-F chat_id="$CHATID"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2 | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
}

##----------------------------------------------------------##

tg_send_sticker() {
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendSticker" \
        -d sticker="$1" \
        -d chat_id="$CHATID"
}

##----------------------------------------------------------------##

tg_send_files(){
    KernelFiles="$(pwd)/$KERNELNAME.zip"
	MD5CHECK=$(md5sum "$KernelFiles" | cut -d' ' -f1)
	SID="CAACAgUAAxkBAAIlv2DEzB-BSFWNyXkkz1NNNOp_pm2nAAIaAgACXGo4VcNVF3RY1YS8HwQ"
	STICK="CAACAgUAAxkBAAIlwGDEzB_igWdjj3WLj1IPro2ONbYUAAIrAgACHcUZVo23oC09VtdaHwQ"
    MSG="✅ <b>Build Done</b>
- <code>$((DIFF / 60)) minute(s) $((DIFF % 60)) second(s) </code>
<b>Build Type</b>
-<code>$BUILD_TYPE</code>
<b>MD5 Checksum</b>
- <code>$MD5CHECK</code>
<b>Zip Name</b>
- <code>$KERNELNAME.zip</code>
- Hello"

        curl --progress-bar -F document=@"$KernelFiles" "https://api.telegram.org/bot$TOKEN/sendDocument" \
        -F chat_id="$CHATID"  \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="$MSG"

}

if [ "$PTTG" = 1 ]
 	then
            tg_post_msg "<b>🔨 Redux Kernel Build Triggered</b>
<b>Host Core Count : </b><code>$PROCS</code>
<b>Device: </b><code>$MODEL</code>
<b>Codename: </b><code>$DEVICE</code>
<b>Build Date: </b><code>$DATE</code>
<b>Kernel Name: </b><code>Redux-$VARIANT-$DEVICE</code>
<b>Linux Tag Version: </b><code>$LINUXVER</code>"
       fi

if [ "$PTTG" = 1 ]
 			then
				tg_post_msg "<b>❌Error! Compilaton failed: Kernel Image missing</b>
<b>Build Date: </b><code>$DATE</code>
<b>Kernel Name: </b><code>Redux-$VARIANT-$DEVICE</code>
<b>Linux Tag Version: </b><code>$LINUXVER</code>
<b>Time Taken: </b><code>$((DIFF / 60)) minute(s) $((DIFF % 60)) second(s)</code>"

				exit -1
			fi

   cp out/arch/arm64/boot/Image $(pwd)/anykernel/
   cp -af anykernel/anykernel-real.sh anykernel.sh
 cd anykernel  zip -r9 "Test-a13ve.zip" * -x .git README.md anykernel-real.sh .gitignore zipsigner* *.zip
if [ "$PTTG" = 1 ]
 	then
		tg_send_files "$1"
	fi
# make anykernel zip
# cp $(pwd)/arch/arm64/boot/Image $(pwd)/anykernel/
# zip -0 $(pwd)/output/anykernel.zip $(pwd)/anykernel/*
