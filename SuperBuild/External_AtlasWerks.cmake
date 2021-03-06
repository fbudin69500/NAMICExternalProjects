if( NOT EXTERNAL_SOURCE_DIRECTORY )
  set( EXTERNAL_SOURCE_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/ExternalSources )
endif()
if( NOT EXTERNAL_BINARY_DIRECTORY )
  set( EXTERNAL_BINARY_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} )
endif()

if( WIN32 OR ( UNIX AND APPLE ) )
  message( FATAL_ERROR "AtlasWerks only compiles and work on linux" )
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
set(extProjName AtlasWerks) #The find_package known name
set(proj        AtlasWerks) #This local name
set(${extProjName}_REQUIRED_VERSION "")  #If a required version is necessary, then set this, else leave blank

#if(${USE_SYSTEM_${extProjName}})
#  unset(${extProjName}_DIR CACHE)
#endif()

# Sanity checks
if(DEFINED ${extProjName}_DIR AND NOT EXISTS ${${extProjName}_DIR})
  message(FATAL_ERROR "${extProjName}_DIR variable is defined but corresponds to non-existing directory (${${extProjName}_DIR})")
endif()

if(NOT ( DEFINED "USE_SYSTEM_${extProjName}" AND "${USE_SYSTEM_${extProjName}}" ) )
  #message(STATUS "${__indent}Adding project ${proj}")
  # Set dependency list
  set(${proj}_DEPENDENCIES ITKv4 VTK CLAPACK FFTW )

  # Include dependent projects if any
  SlicerMacroCheckExternalProjectDependency(${proj})

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
    -DCMAKE_LIBRARY_PATH:PATH=${FFTW_DIR}/lib
    -DLAPACK_DIR:PATH=${CLAPACK_DIR}
    -DAtlasWerks_COMPILE_TESTING:BOOL=OFF
    -DatlasWerks_COMPILE_APP_Affine:BOOL=OFF
    -DatlasWerks_COMPILE_APP_AffineAtlas:BOOL=OFF
    -DatlasWerks_COMPILE_APP_ATLAS_WERKS:BOOL=OFF
    -DatlasWerks_COMPILE_APP_VECTOR_ATLAS_WERKS:BOOL=OFF
    -DatlasWerks_COMPILE_APP_FGROWTH:BOOL=OFF
    -DatlasWerks_COMPILE_APP_FWARP:BOOL=OFF
    -DatlasWerks_COMPILE_APP_ImageConvert:BOOL=OFF
    -DatlasWerks_COMPILE_APP_IMMAP:BOOL=OFF
    -DatlasWerks_COMPILE_APP_LDMM:BOOL=OFF
    -DatlasWerks_COMPILE_APP_GREEDY:BOOL=ON # Compile Only GreedyAtlas
    -DatlasWerks_COMPILE_APP_TX_APPLY:BOOL=OFF
    -DatlasWerks_COMPILE_APP_TX_WERKS:BOOL=OFF
    -DatlasWerks_COMPILE_APP_UTILITIES:BOOL=OFF
    )

  ### --- End Project specific additions
  set(${proj}_REPOSITORY GIT_REPOSITORY ${git_protocol}://github.com/BRAINSia/AtlasWerks.git)
  set( ${proj}_GIT_TAG 3bd03912f1fab05b5c1f43cafbf9356ed1e13299 )

  ExternalProject_Add(${proj}
    GIT_REPOSITORY ${${proj}_REPOSITORY}
    GIT_TAG ${${proj}_GIT_TAG}
    SOURCE_DIR ${EXTERNAL_SOURCE_DIRECTORY}/${proj}
    BINARY_DIR ${EXTERNAL_BINARY_DIRECTORY}/${proj}-build
    LOG_CONFIGURE 0  # Wrap configure in script to ignore log output from dashboards
    LOG_BUILD     0  # Wrap build in script to to ignore log output from dashboards
    LOG_TEST      0  # Wrap test in script to to ignore log output from dashboards
    LOG_INSTALL   0  # Wrap install in script to to ignore log output from dashboards
    ${cmakeversion_external_update} "${cmakeversion_external_update_value}"
    CMAKE_GENERATOR ${gen}
    CMAKE_ARGS
      --no-warn-unused-cli # HACK Only expected variables should be passed down.
      ${CMAKE_OSX_EXTERNAL_PROJECT_ARGS}
      ${COMMON_EXTERNAL_PROJECT_ARGS}
      ${${proj}_CMAKE_OPTIONS}
      -DCMAKE_INSTALL_PREFIX:PATH=${EXTERNAL_BINARY_DIRECTORY}/${proj}-install
    #We only care about GreedyAtlas so we only build this target.
    #This works only on linux, but this tool only works on linux anyway
    BUILD_COMMAND ${CMAKE_MAKE_PROGRAM} GreedyAtlas
    DEPENDS ${${proj}_DEPENDENCIES}
    INSTALL_COMMAND ""
    )

  ## Force rebuilding of the main subproject every time building from super structure
  ExternalProject_Add_Step(AtlasWerks forcebuild
      COMMAND ${CMAKE_COMMAND} -E remove
      ${CMAKE_CURRENT_BUILD_DIR}/AtlasWerks-prefix/src/AtlasWerks-stamp/AtlasWerks-build
      DEPENDEES configure
      DEPENDERS build
      ALWAYS 1
    )
else()
  if(${USE_SYSTEM_${extProjName}})
    find_package(${extProjName} ${${extProjName}_REQUIRED_VERSION} REQUIRED)
    message("USING the system ${extProjName}, set ${extProjName}_DIR=${${extProjName}_DIR}")
  endif()
  # The project is provided using ${extProjName}_DIR, nevertheless since other
  # project may depend on ${extProjName}, let's add an 'empty' one
  SlicerMacroEmptyExternalProject(${proj} "${${proj}_DEPENDENCIES}")
endif()

list(APPEND ${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARS ${extProjName}_DIR:PATH)

ProjectDependancyPop(CACHED_extProjName extProjName)
ProjectDependancyPop(CACHED_proj proj)
