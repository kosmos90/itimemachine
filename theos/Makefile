TARGET = iphone:clang:latest:6.1
ARCHS = armv7

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = iTimeMachine

iTimeMachine_FILES = \
  ../app/iTimeMachine/main.m \
  ../app/iTimeMachine/AppDelegate.m \
  ../app/iTimeMachine/CatalogViewController.m \
  ../app/iTimeMachine/DetailViewController.m \
  ../app/iTimeMachine/ITMAppItem.m \
  ../app/iTimeMachine/CatalogService.m

iTimeMachine_FRAMEWORKS = UIKit Foundation CoreGraphics

iTimeMachine_CFLAGS += -fobjc-arc

# Bundle resources (catalog)
iTimeMachine_RESOURCE_FILES = \
  ../app/iTimeMachine/catalog.json \
  ../app/iTimeMachine/icon.png \
  ../app/iTimeMachine/Default.png

# Use provided Info.plist
iTimeMachine_INFOPLIST = Info.plist

include $(THEOS_MAKE_PATH)/application.mk
