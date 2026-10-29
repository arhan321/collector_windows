cmake_minimum_required(VERSION 3.16)
project(RMS_Yaskawa_Collector LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
option(RMS_ENABLE_YMCONNECT "Enable YMConnect YRC1000/SP210 hardware reader" OFF)

find_package(Threads REQUIRED)
find_package(Iconv REQUIRED)

if(WIN32)
    # vcpkg provides CURLConfig.cmake and its transitive dependencies on Windows.
    find_package(CURL CONFIG REQUIRED)
    set(RMS_CURL_TARGET CURL::libcurl)
else()
    # Preserve the existing Ubuntu/pkg-config build; allow a native CMake fallback.
    find_package(PkgConfig QUIET)
    if(PkgConfig_FOUND)
        pkg_check_modules(CURL REQUIRED IMPORTED_TARGET libcurl)
        set(RMS_CURL_TARGET PkgConfig::CURL)
    else()
        find_package(CURL REQUIRED)
        set(RMS_CURL_TARGET CURL::libcurl)
    endif()
endif()

add_executable(rms_collector src/HelloYMConnect.cpp)
target_link_libraries(rms_collector PRIVATE Threads::Threads ${RMS_CURL_TARGET} Iconv::Iconv)
if(MSVC)
    target_compile_options(rms_collector PRIVATE /W4 /utf-8)
    target_compile_definitions(rms_collector PRIVATE NOMINMAX WIN32_LEAN_AND_MEAN)
else()
    target_compile_options(rms_collector PRIVATE -Wall -Wextra -Wpedantic)
endif()

if(RMS_ENABLE_YMCONNECT)
    if(WIN32)
        if(NOT MSVC OR NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
            message(FATAL_ERROR "Use an MSVC-compatible x64 compiler for the official YMConnect Windows SDK.")
        endif()
        set(YMCONNECT_SDK_DIR "${PROJECT_SOURCE_DIR}/sdk" CACHE PATH "Extracted official YMConnect Windows package")
        set(YMCONNECT_INCLUDE "${YMCONNECT_SDK_DIR}" CACHE PATH "Folder containing YMConnect.h")
        set(YMCONNECT_LIBRARY "${YMCONNECT_SDK_DIR}/Release/YMConnect.lib" CACHE FILEPATH "YMConnect Release import library")
        set(YMCONNECT_RUNTIME "${YMCONNECT_SDK_DIR}/Release/YMConnect.dll" CACHE FILEPATH "YMConnect Release runtime")
        set(YMCONNECT_LIBRARY_DEBUG "${YMCONNECT_SDK_DIR}/Debug/YMConnect_D.lib" CACHE FILEPATH "YMConnect Debug import library")
        set(YMCONNECT_RUNTIME_DEBUG "${YMCONNECT_SDK_DIR}/Debug/YMConnect_D.dll" CACHE FILEPATH "YMConnect Debug runtime")
    else()
        set(YMCONNECT_INCLUDE "${PROJECT_SOURCE_DIR}/sdk/include" CACHE PATH "Folder containing YMConnect.h")
        set(YMCONNECT_LIBRARY "${PROJECT_SOURCE_DIR}/sdk/lib/libYMConnect.so" CACHE FILEPATH "Matching Linux .so SDK")
    endif()
    if(NOT EXISTS "${YMCONNECT_INCLUDE}/YMConnect.h")
        message(FATAL_ERROR "YMConnect.h not found: ${YMCONNECT_INCLUDE}/YMConnect.h")
    endif()
    if(NOT EXISTS "${YMCONNECT_LIBRARY}")
        message(FATAL_ERROR "YMConnect library not found: ${YMCONNECT_LIBRARY}")
    endif()
    target_include_directories(rms_collector PRIVATE "${YMCONNECT_INCLUDE}")
    target_compile_definitions(rms_collector PRIVATE RMS_WITH_YMCONNECT=1)
    if(WIN32)
        foreach(RMS_SDK_FILE IN ITEMS YMCONNECT_RUNTIME YMCONNECT_LIBRARY_DEBUG YMCONNECT_RUNTIME_DEBUG)
            if(NOT EXISTS "${${RMS_SDK_FILE}}")
                message(FATAL_ERROR "Missing ${RMS_SDK_FILE}: ${${RMS_SDK_FILE}}. Extract the complete matching Windows SDK.")
            endif()
        endforeach()
        add_library(YMConnect::YMConnect SHARED IMPORTED)
        set_target_properties(YMConnect::YMConnect PROPERTIES
            IMPORTED_CONFIGURATIONS "RELEASE;DEBUG"
            IMPORTED_IMPLIB "${YMCONNECT_LIBRARY}"
            IMPORTED_LOCATION "${YMCONNECT_RUNTIME}"
            IMPORTED_IMPLIB_RELEASE "${YMCONNECT_LIBRARY}"
            IMPORTED_LOCATION_RELEASE "${YMCONNECT_RUNTIME}"
            IMPORTED_IMPLIB_DEBUG "${YMCONNECT_LIBRARY_DEBUG}"
            IMPORTED_LOCATION_DEBUG "${YMCONNECT_RUNTIME_DEBUG}"
            MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
            MAP_IMPORTED_CONFIG_MINSIZEREL Release)
        target_link_libraries(rms_collector PRIVATE YMConnect::YMConnect)
        # Make the vendor DLL available before vcpkg scans runtime dependencies.
        add_custom_command(TARGET rms_collector PRE_LINK
            COMMAND "${CMAKE_COMMAND}" -E copy_if_different
                "$<TARGET_FILE:YMConnect::YMConnect>" "$<TARGET_FILE_DIR:rms_collector>"
            COMMENT "Copying the matching YMConnect runtime beside rms_collector.exe"
            VERBATIM)
    else()
        target_link_libraries(rms_collector PRIVATE "${YMCONNECT_LIBRARY}")
        get_filename_component(YMCONNECT_LIBDIR "${YMCONNECT_LIBRARY}" DIRECTORY)
        set_target_properties(rms_collector PROPERTIES BUILD_RPATH "${YMCONNECT_LIBDIR}" INSTALL_RPATH "${YMCONNECT_LIBDIR}")
    endif()
endif()

include(CTest)
if(BUILD_TESTING)
    add_test(NAME mock_json_dry_run COMMAND rms_collector
        --config "${PROJECT_SOURCE_DIR}/config/collector.conf"
        --mock --once --dry-run)
endif()

