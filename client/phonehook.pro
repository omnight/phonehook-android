TEMPLATE = app
TARGET = phonehook

QT += qml xml sql xmlpatterns quick widgets quickcontrols2

android {
    QT += androidextras
    DEFINES += ANDROID
}

CONFIG += c++11

SOURCES += src\main.cpp \
        src\native.cpp \
    src/handler_format.cpp \
    src/handler_regexp.cpp \
    src/handler_url.cpp \
    src/entities.cpp \
    src/process_data.cpp \
    src/robot_base.cpp \
    src/compression.cpp \
    src/db.cpp \
    src/bots.cpp \
    src/countries.cpp \
    src/lookup_thread.cpp \
    src/phonenumber.cpp \
    src/setting.cpp \
    src/blocking.cpp \
    src/blocks.cpp \
    src/auto_update.cpp \
    src/util.cpp

HEADERS += \
    src\native.h \
    src/handler_format.h \
    src/handler_regexp.h \
    src/handler_url.h \
    src/entities.h \
    src/process_data.h \
    src/robot_base.h \
    src/compression.h \
    src/db.h \
    src/bots.h \
    src/db_model.h \
    src/countries.h \
    src/lookup_thread.h \
    src/phonenumber.h \
    src/setting.h \
    src/blocking.h \
    src/blocks.h \
    src/auto_update.h \
    src/macros.h \
    src/util.h

RESOURCES += qml.qrc \
    ph.qrc

lupdate_only {
SOURCES += qml/*.qml \
               qml/setting/*.qml \
               qml/control/*.qml
}

OTHER_FILES += qml/*.qml \
               qml/setting/*.qml \
               qml/control/*.qml

TRANSLATIONS = translations/phonehook.ts

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Default rules for deployment.
include(deployment.pri)

DISTFILES += \
    android/AndroidManifest.xml \
    android/gradle/wrapper/gradle-wrapper.jar \
    android/gradlew \
    android/res/values/libs.xml \
    android/build.gradle \
    android/gradle/wrapper/gradle-wrapper.properties \
    android/gradlew.bat \
    android/src/com/omnight/phonehook/Native.java \
    android/src/com/omnight/phonehook/MyService.java \
    android/src/com/omnight/phonehook/HUDView.java \
    android/res/values/strings.xml \
    android/src/org/qtproject/qt5/android/QtServiceDelegateX.java \
    android/res/layout/popup_layout.xml \
    android/res/layout/result_item.xml \
    qml/PageServerBotList.qml \
    qml/PageBotDownloadForm.ui.qml \
    qml/PageBotDownload.qml \
    qml/PageDownloadWaitForm.ui.qml \
    qml/PageDownloadWait.qml \
    android/src/com/omnight/phonehook/Login.java \
    android/res/layout/activity_login.xml \
    android/src/org/qtproject/qt5/android/addons/qtserviceapp/QtService.java \
    android/src/org/qtproject/qt5/android/addons/qtserviceapp/QtServiceActivity.java \
    android/src/org/qtproject/qt5/android/addons/qtserviceapp/QtServiceBroadcastReceiver.java \
    android/src/com/omnight/phonehook/ServiceStarter.java \
    android/aidl/PhonehookDaemonInterface.aidl \
    android/aidl/com/omnight/phonehook/PhonehookDaemonInterface.aidl \
    android/src/com/omnight/phonehook/StuntScrollView.java \
    android/src/com/android/internal/telephony/ITelephony.java \
    android/res/drawable/splash.xml \
    qml/control/BigButton.qml

ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android

contains(ANDROID_TARGET_ARCH,armeabi-v7a) {
    ANDROID_EXTRA_LIBS = \
        $$PWD/android/libs/armeabi-v7a/libcrypto.so \
        $$PWD/android/libs/armeabi-v7a/libssl.so
}

contains(ANDROID_TARGET_ARCH,x86) {
    ANDROID_EXTRA_LIBS = \
        $$PWD/android/libs/x86/libcrypto.so \
        $$PWD/android/libs/x86/libssl.so
}



