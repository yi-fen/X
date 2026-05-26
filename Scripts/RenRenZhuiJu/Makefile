ARCHS = arm64 arm64e
TARGET = iphone:clang:15.0:14.0
INSTALL_TARGET_PROCESSES = VePleTV

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RenRenZhuiJu

RenRenZhuiJu_FILES = Tweak.xm
RenRenZhuiJu_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
