######################################
# 
# date              author             what 
# 2014.5.18       96juelian    add better resign method.
# 
###################################

FILE = ${PORT_DEVICE}/custom_resign_app.mk

include ${PORT_BUILD}/apps.conf
-include ${FILE}

${shell mkdir -p ${PORT_DEVICE}/apps}
${shell mkdir -p ${PORT_DEVICE}/update/system}
define APK_template
SIGNAPKS += $(1)
$(1):
	@echo "resign apk: $1"
	@cp ${PORT_BUILD}/ColorSystem/app/$1 ${PORT_DEVICE}/apps
endef

ifeq ($(FILE), $(wildcard $(FILE)))
define APK_CUSTOMAPP_template
APKS_CUSTOM += $(1)
$(1):
	@echo "resign custom origin apk: $1"
	@cp ${PORT_DEVICE}/custom-update/system/app/$1 ${PORT_DEVICE}/apps
endef
endif

$(foreach apk, $(APPS_NEED_RESIGN) $(APPS_EXTRA) ${APPS_MTK_ONLY}, \
	$(eval $(call APK_template,$(apk))))

ifeq ($(FILE), $(wildcard $(FILE)))
$(foreach apk, $(APPS_CUSTOM_ORIGIN), \
	$(eval $(call APK_CUSTOMAPP_template,$(apk))))
endif

ifeq ($(FILE), $(wildcard $(FILE)))
sign : ${SIGNAPKS} ${APKS_CUSTOM}
	@echo "Sign all needed apks!, had custom sign apps!"
	${PORT_TOOLS}/resign.sh dir ${PORT_DEVICE}/apps
else
sign : ${SIGNAPKS}
	@echo "Sign all needed apks!"
	${PORT_TOOLS}/resign.sh dir ${PORT_DEVICE}/apps
endif

.PHONY: update
update:
	@echo "Update new code"
	cat ${PORT_ROOT}/smali/sourcechange.txt ${PORT_ROOT}/last_smali/sourcechange.txt | sort | uniq > ${PORT_ROOT}/device/sourcechange.txt
	${PORT_TOOLS}/patch_color_framework.sh ${PORT_ROOT}/last_smali/color ${PORT_ROOT}/smali/color ${PWD}/smali/ ${PORT_ROOT}/device/sourcechange.txt

firstpatch : getsmali resource
	@echo "First patch, We will autopatch changed smali files, you should modify files in dir temp/reject"
	${PORT_TOOLS}/patch_color_framework.sh ${PORT_ROOT}/smali/android ${PORT_ROOT}/smali/color ${PWD}/smali/ ${PORT_ROOT}/smali/sourcechange.txt

basepackage :
	@echo "Compile base package from phone"
	@echo "But firstly you should be sure you can use adb in linux"
	${PORT_TOOLS}/releasetools/ota_target_from_phone -n

otapackage : OTA_ID := 

fullota : ${DST_JAR_OUT} sign
	@echo "Build the full update package"
	rm -rf new-update/
	${PORT_TOOLS}/copy_fold.sh update/ new-update/
	echo "ro.build.author=${AUTHOR_NAME}" >> new-update/system/build.prop
	echo "ro.build.channel=${FROM_CHANNEL}" >> new-update/system/build.prop
	rm -rf new-update/system/app/*
	@echo "${PORT_BUILD}/ColorSystem/*"
	${PORT_TOOLS}/copy_fold.sh ${PORT_BUILD}/ColorSystem new-update/system
	${PORT_TOOLS}/copy_fold.sh apps/ new-update/system/app
	${PORT_TOOLS}/copy_fold.sh out/framework new-update/system/framework
	${PORT_TOOLS}/copy_fold.sh out/framework-res.apk new-update/system/framework/
	${PORT_TOOLS}/copy_fold.sh out/oppo-framework-res.apk new-update/system/framework/

#we will use $(CUSTOM_UPDATE) to cover, so you need put your change file or some apk can't be deleted
	${PORT_TOOLS}/copy_fold.sh ${CUSTOM_UPDATE} new-update/

#	${PORT_TOOLS}/resign.sh dir new-update
#	${PORT_TOOLS}/oppo_sign.sh new-update
	rm -f color-update.zip
	cd new-update/; zip -q -r -y color-update.zip .; mv color-update.zip ..
	
	
