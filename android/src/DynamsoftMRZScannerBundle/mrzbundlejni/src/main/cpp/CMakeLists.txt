cmake_minimum_required(VERSION 3.22.1)

project("DynamsoftMRZScannerBundleJni")

file(GLOB SRC_FILES  "*.cpp" "*/*.cpp")

add_library(${CMAKE_PROJECT_NAME} SHARED ${SRC_FILES})

file(GLOB DYNAMSOFT_LIBS "${CMAKE_SOURCE_DIR}/libs/dynamsoft/${ANDROID_ABI}/*.so")

target_link_libraries(${CMAKE_PROJECT_NAME}
        ${DYNAMSOFT_LIBS}
        android
        log)


target_link_options(${CMAKE_PROJECT_NAME} PRIVATE "-Wl,-z,max-page-size=16384")
