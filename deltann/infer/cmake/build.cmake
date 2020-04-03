# ----------------------------------------------------------------------------
# section: compile flags
# ----------------------------------------------------------------------------
if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(CMAKE_MACOSX_RPATH 1)
endif()

if(BUILD_DEBUG)
    delta_add_compile(GCC FLAGS -std=c++11 -Wall -ldl -fPIC)
    delta_add_compile(GCC FLAGS -O0 -g)
else()
    delta_add_compile(GCC FLAGS -std=c++11 -Wall -ldl -fPIC)
    delta_add_compile(GCC FLAGS -O3)
endif()

delta_add_compile(GCC FLAG -Wno-sign-compare)
delta_add_compile(GCC FLAG -Wno-narrowing)
#delta_add_compile(GCC FLAG -Wno-unused-command-line-argument)
delta_add_compile(GCC FLAG -Wno-return-local-addr)
delta_add_compile(GCC FLAG -Wno-unused-variable)
delta_add_compile(GCC FLAG -Wno-reorder)

if(BUILD_X86)
    set(X86_ARCH "native")
    delta_get_cpu_arch(X86_ARCH) 
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
        #delta_add_compile(GCC FLAGS -fabi-version=6 -fabi-compat-version=2)
        delta_add_compile(GCC FLAG -march=${X86_ARCH})
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        set(X86_ARCH "clang_native")
        delta_add_compile(CLANG FLAG -march=clang_native)
    else()
        delta_msg(ERROR STR "Can't support compiler id ${CMAKE_CXX_COMPILER_ID}.")
    endif()
    # not support yet, be careful about this setting.
    #delta_add_compile(GCC FLAGS -mfma -mavx512f -mavx512cd -mavx512er -mavx512pf)
endif()

macro(find_openmp) 
    find_package(OpenMP REQUIRED) 
    if(OPENMP_FOUND OR OpenMP_CXX_FOUND) 
        delta_add_compile(GCC FLAG ${OpenMP_CXX_FLAGS})
    else() 
        delta_msg(ERROR STR "Could not found openmp !") 
    endif() 
endmacro()

# ----------------------------------------------------------------------------
# section: build shared or static library
# ----------------------------------------------------------------------------
function(cc_library TARGET_NAME)
  	set(options STATIC static SHARED shared)
  	set(oneValueArgs "")
    set(multiValueArgs SRCS DEPS LINK_LIBS)
  	cmake_parse_arguments(LIB "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  	if(LIB_SRCS)
        if(LIB_SHARED OR LIB_shared)
            add_library(${TARGET_NAME} SHARED ${LIB_SRCS})
        elseif(LIB_STATIC OR LIB_static)
            add_library(${TARGET_NAME} STATIC ${LIB_SRCS})
        else()
            delta_msg(ERROR STR "$cc_library's options must be set one of (STATIC static SHARED shared)")
        endif()
        if(LIB_DEPS OR LIB_LINK_LIBS) 
            foreach(dep ${LIB_DEPS})
                add_dependencies(${TARGET_NAME} ${dep})
                target_link_libraries(${TARGET_NAME} ${dep})
            endforeach()
            foreach(link_lib ${LIB_LINK_LIBS})
                target_link_libraries(${TARGET_NAME} ${link_lib})
            endforeach()
        endif()
    endif(LIB_SRCS)
endfunction()

function(cc_binary EXEC_NAME)
    set(options "")
  	set(oneValueArgs "")
    set(multiValueArgs SRCS DEPS LINK_LIBS)
    cmake_parse_arguments(BINARY "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    add_executable(${EXEC_NAME} ${BINARY_SRCS})
    if(BINARY_DEPS OR BINARY_LINK_LIBS)
        foreach(dep ${BINARY_DEPS})
            add_dependencies(${EXEC_NAME} ${dep})
            target_link_libraries(${EXEC_NAME} ${dep})
        endforeach()
        foreach(link_lib ${BINARY_LINK_LIBS})
            target_link_libraries(${EXEC_NAME} ${link_lib})
        endforeach()
    endif()
    get_property(os_dependency_modules GLOBAL PROPERTY OS_DEPENDENCY_MODULES)
    target_link_libraries(${EXEC_NAME} ${os_dependency_modules})
endfunction()
