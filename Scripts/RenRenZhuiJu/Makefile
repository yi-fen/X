ARCHS = arm64 arm64e
TARGET = iphone:clang:17.5:15.0
INSTALL_TARGET_PROCESSES = TerraWave66  # 对应主可执行文件名

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RenRenZhuiJu

RenRenZhuiJu_FILES = Tweak.xm
RenRenZhuiJu_CFLAGS = -fobjc-arc
RenRenZhuiJu_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
