if( NOT EXTERNAL_SOURCE_DIRECTORY )
  set( EXTERNAL_SOURCE_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/ExternalSources )
endif()
if( NOT EXTERNAL_BINARY_DIRECTORY )
  set( EXTERNAL_BINARY_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} )
endif()

# Make sure this file is included only once by creating globally unique varibles
# based on the name of this included file.
get_filename_component(CMAKE_CURRENT_LIST_FILENAME ${CMAKE_CURRENT_LIST_FILE} NAME_WE)
if(${CMAKE_CURRENT_LIST_FILENAME}_FILE_INCLUDED)
  return()
endif()
set(${CMAKE_CURRENT_LIST_FILENAME}_FILE_INCLUDED 1)

## External_${extProjName}.cmake files can be recurisvely included,
## and cmake variables are global, so when including sub projects it
## is important make the extProjName and proj variables
## appear to stay constant in one of these files.
## Store global variables before overwriting (then restore at end of this file.)
ProjectDependancyPush(CACHED_extProjName ${extProjName})
ProjectDependancyPush(CACHED_proj ${proj})

# Make sure that the ExtProjName/IntProjName variables are unique globally
# even if other External_${ExtProjName}.cmake files are sourced by
# SlicerMacroCheckExternalProjectDependency
set(extProjName Swig) #The find_package known name
set(proj        Swig) #This local name

#if(${USE_SYSTEM_${extProjName}})
#  unset(${extProjName}_DIR CACHE)
#endif()

# Sanity checks
if(DEFINED ${extProjName}_DIR AND NOT EXISTS ${${extProjName}_DIR})
  message(FATAL_ERROR "${extProjName}_DIR variable is defined but corresponds to non-existing directory (${${extProjName}_DIR})")
endif()


if(NOT SWIG_DIR AND NOT ${CMAKE_PROJECT_NAME}_USE_SYSTEM_${proj})
  set(SWIG_TARGET_VERSION 2.0.12)
  set(SWIG_DOWNLOAD_SOURCE_HASH "c3fb0b2d710cc82ed0154b91e43085a4")
  set(SWIG_DOWNLOAD_WIN_HASH "3cc7dd131a87972f70fca1490b9e6e6b")
  if(WIN32)
    # swig.exe available as pre-built binary on Windows:
    ExternalProject_Add(${proj}
      URL http://midas3.kitware.com/midas/api/rest?method=midas.bitstream.download&checksum=${SWIG_DOWNLOAD_WIN_HASH}&name=swigwin-${SWIG_TARGET_VERSION}.zip
      URL_MD5 ${SWIG_DOWNLOAD_WIN_HASH}
      SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/swigwin-${SWIG_TARGET_VERSION}"
      CONFIGURE_COMMAND ""
      BUILD_COMMAND ""
      INSTALL_COMMAND ""
      UPDATE_COMMAND ""
      )

    set(SWIG_DIR ${EXTERNAL_BINARY_DIRECTORY}/swigwin-${TARGET_SWIG_VERSION}) # ??
    set(SWIG_EXECUTABLE ${EXTERNAL_BINARY_DIRECTORY}/swigwin-${TARGET_SWIG_VERSION}/swig.exe)
    set(Swig_DEPEND Swig)
  else()
    # not windows
    # Set dependency list
    set(${proj}_DEPENDENCIES PCRE python)

    # Include dependent projects if any
    SlicerMacroCheckExternalProjectDependency(${proj})
    #
    # SWIG
    #

    # swig uses bison find it by cmake and pass it down
    find_package(BISON)
    set(BISON_FLAGS "" CACHE STRING "Flags used by bison")
    mark_as_advanced(BISON_FLAGS)

    # follow the standard EP_PREFIX locations
    set(swig_binary_dir ${EXTERNAL_BINARY_DIRECTORY}/Swig-prefix/src/Swig-build)
    set(swig_source_dir ${EXTERNAL_BINARY_DIRECTORY}/Swig-prefix/src/Swig)
    set(swig_install_dir ${EXTERNAL_BINARY_DIRECTORY}/Swig/install)
    #octave is not necessary and configuration generates an error if octave if found but mkoctfile is not (part of octave development package)
    set(swig_config_extra_options --without-octave --with-python=${slicer_PYTHON_REAL_EXECUTABLE})

    configure_file(
      ${CMAKE_CURRENT_LIST_DIR}/External_Swig_configure_step.cmake.in
      ${EXTERNAL_BINARY_DIRECTORY}/External_Swig_configure_step.cmake
      @ONLY)
    set ( swig_CONFIGURE_COMMAND ${CMAKE_COMMAND} -P ${EXTERNAL_BINARY_DIRECTORY}/External_Swig_configure_step.cmake )

    ExternalProject_Add(${proj}
      URL http://midas3.kitware.com/midas/api/rest?method=midas.bitstream.download&checksum=${SWIG_DOWNLOAD_SOURCE_HASH}&name=swig-${SWIG_TARGET_VERSION}.tar.gz
      URL_MD5 ${SWIG_DOWNLOAD_SOURCE_HASH}
      CONFIGURE_COMMAND ${swig_CONFIGURE_COMMAND}
      DEPENDS ${${proj}_DEPENDENCIES}
      )

    set(${extProjName}_DIR ${swig_install_dir}/share/swig/${TARGET_SWIG_VERSION})
    set(SWIG_EXECUTABLE ${swig_install_dir}/bin/swig)
    set(Swig_DEPEND Swig)
  endif()
endif()
list(APPEND ${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARS ${extProjName}_DIR:PATH SWIG_EXECUTABLE:STRING )
_expand_external_project_vars()
set(COMMON_EXTERNAL_PROJECT_ARGS ${${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_ARGS})

ProjectDependancyPop(CACHED_extProjName extProjName)
ProjectDependancyPop(CACHED_proj proj)
