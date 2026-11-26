cmake_minimum_required(VERSION 3.20)
project(luxinaios LANGUAGES C CXX OBJC OBJCXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Source files
set(SOURCES
    src/entry.mm
    src/ui/LuxinaUI.mm
    src/core/LuxinaCore.cpp
    src/env/LuxinaEnv.mm
)

set(HEADERS
    src/ui/LuxinaUI.h
    src/core/LuxinaCore.h
    src/env/LuxinaEnv.h
    src/config/LuxinaConfig.h
)

# Output shared library
add_library(luxinaios SHARED ${SOURCES} ${HEADERS})

target_include_directories(luxinaios PRIVATE
    src
    src/ui
    src/core
    src/env
    src/config
)

if (APPLE)
    target_link_libraries(luxinaios PRIVATE
        "-framework UIKit"
        "-framework Foundation"
        "-framework QuartzCore"
        "-framework WebKit"
    )
    set_target_properties(luxinaios PROPERTIES
        FRAMEWORK FALSE
        OUTPUT_NAME "luxinaios"
        SUFFIX ".dylib"
    )
endif()
