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
set(extProjName SPHARM-PDM) #The find_package known name
set(proj        ${extProjName}) #This local name

#if(${USE_SYSTEM_${extProjName}})
#  unset(${extProjName}_DIR CACHE)
#endif()

# Sanity checks
if(DEFINED ${extProjName}_DIR AND NOT EXISTS ${${extProjName}_DIR})
  message(FATAL_ERROR "${extProjName}_DIR variable is defined but corresponds to non-existing directory (${${extProjName}_DIR})")
endif()

# Set dependency list
if( ${PRIMARY_PROJECT_NAME}_BUILD_DICOM_SUPPORT )
  set(${proj}_DEPENDENCIES VTK)
else()
  set(${proj}_DEPENDENCIES ITKv4 VTK SlicerExecutionModel BatchMake CLAPACK)
endif()
#if(${PROJECT_NAME}_BUILD_DICOM_SUPPORT)
#  list(APPEND ${proj}_DEPENDENCIES DCMTK)
#endif()

# Include dependent projects if any
SlicerMacroCheckExternalProjectDependency(${proj})

if(NOT ( DEFINED "USE_SYSTEM_${extProjName}" AND "${USE_SYSTEM_${extProjName}}" ) )
  #message(STATUS "${__indent}Adding project ${proj}")

  # Set CMake OSX variable to pass down the external project
  set(CMAKE_OSX_EXTERNAL_PROJECT_ARGS)
  if(APPLE)
    list(APPEND CMAKE_OSX_EXTERNAL_PROJECT_ARGS
      -DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}
      -DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}
      -DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET})
  endif()

  if( ${PRIMARY_PROJECT_NAME}_BUILD_DICOM_SUPPORT )
    set(${proj}_CMAKE_OPTIONS
    -DUSE_SYSTEM_SlicerExecutionModel:BOOL=OFF
    -DUSE_SYSTEM_ITK:BOOL=OFF
    -DITK_VERSION_MAJOR:STRING=${ITK_VERSION_MAJOR}
    -DCLAPACK_DIR:PATH=${CLAPACK_DIR}
    -DSPHARM-PDM_SUPERBUILD:BOOL=ON
    -DUSE_SYSTEM_BatchMake:BOOL=OFF
    -DUSE_SYSTEM_CLAPACK:BOOL=OFF
    )
  else()
    set(${proj}_CMAKE_OPTIONS
    -DUSE_SYSTEM_SlicerExecutionModel:BOOL=ON
    -DUSE_SYSTEM_ITK:BOOL=ON
    -DITK_VERSION_MAJOR:STRING=${ITK_VERSION_MAJOR}
    -DITK_DIR:PATH=${ITK_DIR}
    -DSlicerExecutionModel_DIR:PATH=${SlicerExecutionModel_DIR}
    -DBatchMake_DIR:PATH=${BatchMake_DIR}
    -DCLAPACK_DIR:PATH=${CLAPACK_DIR}
    -DUSE_SYSTEM_CLAPACK:BOOL=ON
    -DUSE_SYSTEM_BatchMake:BOOL=ON
    -DSPHARM-PDM_SUPERBUILD:BOOL=OFF
    )
  endif()

  ### --- Project specific additions here
  set(${proj}_CMAKE_OPTIONS
    -DUSE_SYSTEM_VTK:BOOL=ON
    -DVTK_DIR:PATH=${VTK_DIR}
    -DCOMPILE_ImageMath:BOOL=OFF
    )

  ### --- End Project specific additions
  set(${proj}_REPOSITORY "https://www.nitrc.org/svn/spharm-pdm")
  set(${proj}_SVN_REVISION -r "216")
  ExternalProject_Add(${proj}
    SVN_REPOSITORY ${${proj}_REPOSITORY}
    SVN_REVISION ${${proj}_SVN_REVISION}
    SVN_USERNAME slicerbot
    SVN_PASSWORD slicer
    SOURCE_DIR ${EXTERNAL_SOURCE_DIRECTORY}/${proj}
    BINARY_DIR ${EXTERNAL_BINARY_DIRECTORY}/${proj}-build
    LOG_CONFIGURE 0  # Wrap configure in script to ignore log output from dashboards
    LOG_BUILD     0  # Wrap build in script to to ignore log output from dashboards
    LOG_TEST      0  # Wrap test in script to to ignore log output from dashboards
    LOG_INSTALL   0  # Wrap install in script to to ignore log output from dashboards
    ${cmakeversion_external_update} "${cmakeversion_external_update_value}"
    CMAKE_GENERATOR ${gen}
    CMAKE_ARGS
      ${CMAKE_OSX_EXTERNAL_PROJECT_ARGS}
#      ${COMMON_EXTERNAL_PROJECT_ARGS}
      ${${proj}_CMAKE_OPTIONS}
      -DCMAKE_INSTALL_PREFIX:PATH=${EXTERNAL_BINARY_DIRECTORY}/${proj}-install
## We really do want to install in order to limit # of include paths INSTALL_COMMAND ""
    INSTALL_COMMAND ""
    DEPENDS
      ${${proj}_DEPENDENCIES}
  )
  set(${extProjName}_DIR ${EXTERNAL_BINARY_DIRECTORY}/${proj}-build)
else()
  if(${USE_SYSTEM_${extProjName}})
    find_package(${extProjName} REQUIRED)
    message("USING the system ${extProjName}, set ${extProjName}_DIR=${${extProjName}_DIR}")
  endif()
  # The project is provided using ${extProjName}_DIR, nevertheless since other
  # project may depend on ${extProjName}, let's add an 'empty' one
  SlicerMacroEmptyExternalProject(${proj} "${${proj}_DEPENDENCIES}")
endif()

list(APPEND ${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARS ${extProjName}_DIR:PATH)

ProjectDependancyPop(CACHED_extProjName extProjName)
ProjectDependancyPop(CACHED_proj proj)