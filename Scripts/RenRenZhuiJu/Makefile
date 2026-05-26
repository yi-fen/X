ARCHS = arm64 arm64e
TARGET = iphone:clang:14.0
INSTALL_TARGET_PROCESSES = VePleTV

THEOS_IGNORE_PARALLEL_BUILDING_NOTICE = yes
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RenRenZhuiJu
# 关键：加上quickjs.c
RenRenZhuiJu_FILES = Tweak.xm quickjs.c
RenRenZhuiJu_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
RenRenZhuiJu_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
