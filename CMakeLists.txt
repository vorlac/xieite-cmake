cmake_minimum_required(VERSION 3.28)
set(CMAKE_MESSAGE_LOG_LEVEL STATUS)

list(APPEND CMAKE_MODULE_PATH
  "${CMAKE_CURRENT_SOURCE_DIR}/cmake"
)

set(ENABLE_CCACHE
  OFF CACHE FORCE BOOL
    "Enables ccache"
)

set(ENABLE_ALL_WARNINGS
  OFF CACHE FORCE BOOL
    "Enable all warnings"
)

set(ENABLE_WARNINGS_AS_ERRORS
  ON CACHE FORCE BOOL
    "Treat all warnings as errors"
)

set(AUTOFORMAT_SRC_ON_CONFIGURE
  ON CACHE FORCE BOOL
    "Enables clang-format to autoformat all sources within src/"
)

include(submodule-init)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_EXTENSIONS ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_COLOR_DIAGNOSTICS ON)
set(CMAKE_DIRECTORY_LABELS ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_SCAN_FOR_MODULES ON)

project(xieite_example
  LANGUAGES
    CXX
  VERSION
    0.0.1
)

string(TOLOWER "${CMAKE_SYSTEM_NAME}" host_os)
string(TOLOWER "${CMAKE_BUILD_TYPE}" build_type)
string(TOLOWER "${CMAKE_CXX_COMPILER_ARCHITECTURE_ID}" architecture)
set(CMAKE_DEBUG_POSTFIX ".${build_type}.${architecture}")

set(compiler_is_msvc "$<CXX_COMPILER_ID:MSVC>")
set(compiler_is_gnu "$<CXX_COMPILER_ID:GNU>")
set(compiler_is_clang "$<OR:$<CXX_COMPILER_ID:AppleClang>,$<CXX_COMPILER_ID:Clang>>")

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/extern/xieite-fork)

file(GLOB_RECURSE project_sources
  CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/src/*.[hc]"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/*.[hc]pp"
)

add_executable(${PROJECT_NAME}
  ${project_sources}
)

include(compiler-warnings)

target_compile_features(${PROJECT_NAME}
  PRIVATE
    cxx_std_23
)

target_compile_definitions(${PROJECT_NAME}
  PRIVATE
    NOMINMAX
	UNICODE

    $<${compiler_is_msvc}:
        $<$<CONFIG:Debug>:
            _NO_DEBUG_HEAP=1
        >
    >

    $<${compiler_is_gnu}:
		$<$<CONFIG:Debug>:
			_GLIBCXX_DEBUG
		>
	>
)

target_compile_options(${PROJECT_NAME}
  PRIVATE
    $<${compiler_is_msvc}:
        /Zc:preprocessor
        /utf-8
        /nologo
        /std:c++latest
        /experimental:module

        $<$<CONFIG:Debug>:
			# /fsanitize=fuzzer
		    # /fsanitize=address
            # /Z7 # embed debug info into .o files instead of pdb (for ccache)
            # /Zi # enable edit and continue
        >

        $<$<CONFIG:RelWithDebInfo>:
            /O2 # maximize speed
            /Oi # generate intrinsics
            /Gw # optimize global data
            /GL # whole program optimization
        >

        $<$<CONFIG:Release>:
            /O2 # maximize speed
            /Oi # generate intrinsics
            # /Oy # frame pointer omission
            /Gw # optimize global data
            # /GS- # disable buffer security checks
            # /GA # optimize for windows application
            /GL # whole program optimization
            # /fp:fast # prefer fast over accurate floating point math
            # /favor:INTEL64
            # /Gy
            # /Ox # enable most speed optimizations
            # /Ot # favor fast code
            # /Ob2 # inline function expansion
            # /GR- # disable RTTI
            # /EHa- # disable exception handling
            # /Gr #/Gz # __vectorcall calling convention, Gr for __fastcall
            # /order # order functions for optimal paging
        >
    >

    $<${compiler_is_clang}:
        -fmodules
        -fbuiltin-module-map
        -march=native
        -flto
        -DNDEBUG
    >

    $<${compiler_is_gnu}:
        -fmodules-ts
    >
)

target_link_options(${PROJECT_NAME}
  PRIVATE
    $<${compiler_is_msvc}:
        # /verbose

        $<$<CONFIG:Release>:
            /machine:x64
            /ltcg # link time code gen
            /opt:ref # eliminate unreferenced functions/data
            # /FASTGENPROFILE # generate optimization profile
        >

        $<$<CONFIG:Debug>:
            /opt:ref # eliminate unreferenced functions/data
			# /INFERASANLIBS
            # /natvis:<path> # link natvis into pdb
            # /libpath:dir # additional lib paths
            # /wholearchive # include all library object files in binary
        >
    >

    $<$<NOT:${compiler_is_msvc}>:
        -MT

        $<$<CONFIG:Release>:
            #-fomit-frame-pointer
            -O2
        >
    >
)

target_include_directories(${PROJECT_NAME}
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src"
)

target_link_libraries(${PROJECT_NAME}
  PRIVATE xieite
)

if (AUTOFORMAT_SRC_ON_CONFIGURE MATCHES ON)
  include(clang-format)
endif()

# permissions fix to allow this on windows:
# 1. Enable "developer mode"
#         OR...
# 1. Open gpedit.msc
# 2. Computer Configuration
#      => Windows Settings
#      => Security Settings
#      => Local Policies
#      => User Rights Assignment
#      => Create symbolic links
# 3. Add username, then reboot machine
#
# Create symlink to compile_commands.json for IDE to pick it up
execute_process(
  COMMAND
    ${CMAKE_COMMAND} -E create_symlink
      ${CMAKE_BINARY_DIR}/compile_commands.json
      ${CMAKE_CURRENT_SOURCE_DIR}/compile_commands.json
)

include(cmake-utils)
