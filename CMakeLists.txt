cmake_minimum_required( VERSION 3.1)

project( MulleUI C)


### mulle-sde environment

# add cmake module paths to search path
list( INSERT CMAKE_MODULE_PATH 0 "${PROJECT_SOURCE_DIR}/cmake/share")
list( INSERT CMAKE_MODULE_PATH 0 "${PROJECT_SOURCE_DIR}/cmake/reflect")
list( INSERT CMAKE_MODULE_PATH 0 "${PROJECT_SOURCE_DIR}/cmake/reflect")
list( INSERT CMAKE_MODULE_PATH 0 "${PROJECT_SOURCE_DIR}/cmake")

include( Environment)

include( Files)
include( Dependencies)

### Executables

add_library( MulleUI OBJECT ${SOURCES})

#
# Overwrite rule generated MAIN_SOURCES, because we don't want all the
# demos built all the time
# When porting, try to get NON_GRAPHIC_MAIN_SOURCES,
# BAREBONES_SOURCES, VIEW_SUBCLASS_SOURCES working in that order first
# before the others
set( NON_GRAPHIC_MAIN_SOURCES
src/main-animate-object.m
src/main-freetype.m
src/main-textstorage.m
src/main-transform.m
src/main-viewconversion.m
)

# barebones drawing using UIView and CALayer only
set( BAREBONES_SOURCES
src/main-autoresizingmask.m
src/main-canvas-bounds-frame.m
src/main-clip.m
src/main-layer.m
src/main-layer-clip.m
src/main-layer-bounds.m
src/main-layout.m
src/main-draw.m
src/main-photoshop.m
src/main-resize.m
src/main-svg.m
src/main-subview.m
src/main-translate-scale.m
)

# simple demos of a single view subclass
set( VIEW_SUBCLASS_SOURCES
src/main-buttons.m
#src/main-collectionview.m
src/main-imageview.m
src/main-label.m
src/main-stackview.m
src/main-rowcolumn.m
src/main-animate-scrollview.m
src/main-scrollview.m
#src/main-slider.m
#src/main-popupbutton.m
#src/main-textfield.m
)

# more sophistated using subclasse like menus or buttons
set( MAIN_SOURCES
#${NON_GRAPHIC_MAIN_SOURCES}
${BAREBONES_SOURCES}
${VIEW_SUBCLASS_SOURCES}
#src/main-animate-circles.m
src/main-calculator.m
src/main-event-queue.m
src/main-fbo.m
src/main-jspiechart.m
src/main-many-rectangles.m
src/main-path.m
src/main-remove-from-area.m
src/main-render-png.m
src/main-springs-and-struts.m
src/main-contentmode.m
src/main-text.m
src/main-textlayout.m
src/main-textview.m
src/main-tiger.m
src/main-windows.m
)

foreach( MAIN_SOURCE ${MAIN_SOURCES})
   # get rid off src/main- prefix and .m suffix
   #             offset 9  length -9 - 2
   string( LENGTH "${MAIN_SOURCE}" MAIN_SOURCE_LENGTH)
   math( EXPR MAIN_SOURCE_LENGTH "${MAIN_SOURCE_LENGTH} - 11")
   string( SUBSTRING "${MAIN_SOURCE}" 9 ${MAIN_SOURCE_LENGTH} EXECUTABLE_NAME)

   set( SOURCES ${MAIN_SOURCE})
   set( OTHER_EXECUTABLE_OBJECT_FILES $<TARGET_OBJECTS:MulleUI>)

   include( Executable)
   include( InstallExecutable)
   include( FinalOutput OPTIONAL)
# only for Executable
   include( Motd OPTIONAL)
endforeach()

