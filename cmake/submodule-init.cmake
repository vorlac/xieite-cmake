if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/extern/xieite-fork/include")
    message(NOTICE "xieite sources not found")
    message(NOTICE "initializing/updating the xieite submodule...")
    execute_process(
        COMMAND git submodule update --init extern/xieite-fork
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMAND_ERROR_IS_FATAL ANY
    )
endif()
