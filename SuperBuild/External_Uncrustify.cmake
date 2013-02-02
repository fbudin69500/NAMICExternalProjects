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
set(extProjName Uncrustify) #The find_package known name
set(proj        Uncrustify) #This local name
set(${extProjName}_REQUIRED_VERSION "")  #If a required version is necessary, then set this, else leave blank

#if(${USE_SYSTEM_${extProjName}})
#  unset(${extProjName}_EXE CACHE)
#endif()

# Sanity checks
if(DEFINED ${extProjName}_EXE AND NOT EXISTS ${${extProjName}_EXE})
  message(FATAL_ERROR "${extProjName}_EXE variable is defined but corresponds to non-existing file")
endif()

# Set dependency list
set(${proj}_DEPENDENCIES "")

# Include dependent projects if any
SlicerMacroCheckExternalProjectDependency(${proj})

if(NOT ( DEFINED "${extProjName}_EXE" OR ( DEFINED "${USE_SYSTEM_${extProjName}}" AND NOT "${USE_SYSTEM_${extProjName}}" ) ) )
  #message(STATUS "${__indent}Adding project ${proj}")

  # Set CMake OSX variable to pass down the external project
  set(CMAKE_OSX_EXTERNAL_PROJECT_ARGS)
  if(APPLE)
    list(APPEND CMAKE_OSX_EXTERNAL_PROJECT_ARGS
      -DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}
      -DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}
      -DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET})
  endif()

  ### --- Project specific additions here
  set(${proj}_CMAKE_OPTIONS
  )

  ### --- End Project specific additions
  if(NOT DEFINED git_protocol)
      set(git_protocol "git")
  endif()
  set(${proj}_REPOSITORY ${git_protocol}://uncrustify.git.sourceforge.net/gitroot/uncrustify/uncrustify)
  set(${proj}_GIT_TAG 60f3681da60462eda539b78e0c6c3eea823481e5)
  ExternalProject_Add(${proj}
    GIT_REPOSITORY ${${proj}_REPOSITORY}
    GIT_TAG ${${proj}_GIT_TAG}
    SOURCE_EXE ${proj}
    BINARY_EXE ${proj}-build
    LOG_UPDATE 1
    CONFIGURE_COMMAND <SOURCE_EXE>/configure --prefix=${CMAKE_BINARY_EXE}/Utils
    DEPENDS
      ${${proj}_DEPENDENCIES}
  )
  set(${extProjName}_EXE ${CMAKE_BINARY_EXE}/Utils/bin/uncrustify)
else()
  if(${USE_SYSTEM_${extProjName}})
    find_package(${extProjName} ${${extProjName}_REQUIRED_VERSION} REQUIRED)
    if(NOT ${extProjName}_EXE)
      message(FATAL_ERROR "To use the system ${extProjName}, set ${extProjName}_EXE")
    endif()
    message("USING the system ${extProjName}, set ${extProjName}_EXE=${${extProjName}_EXE}")
  endif()
  # The project is provided using ${extProjName}_EXE, nevertheless since other
  # project may depend on ${extProjName}, let's add an 'empty' one
  SlicerMacroEmptyExternalProject(${proj} "${${proj}_DEPENDENCIES}")
endif()

list(APPEND ${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARS ${extProjName}_EXE:PATH)

ProjectDependancyPop(CACHED_extProjName extProjName)
ProjectDependancyPop(CACHED_proj proj)