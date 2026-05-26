ARCHS = arm64 arm64e
# 去掉SDK版本指定，自动使用系统已有的SDK
TARGET = iphone:clang::14.0
INSTALL_TARGET_PROCESSES = VePleTV

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RenRenZhuiJu

RenRenZhuiJu_FILES = Tweak.xm
RenRenZhuiJu_CFLAGS = -fobjc-arc
RenRenZhuiJu_LDFLAGS = -framework Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
