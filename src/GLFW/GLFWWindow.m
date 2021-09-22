//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "GLFWWindow.h"

#import "import-private.h"

#include <MulleCG/_MulleCGBackend.h>


@implementation GLFWWindow


// hope for fractional positioning in future ?
- (instancetype) initWithFrame:(CGRect) frame
                  titleCString:(char *) title
                    styleMask:(NSUInteger) styleMask
{
   assert( [NSThread mulleIsMainThread]);

#ifndef MULLE_CG_GLVERSION
# error "MULLE_CG_GLVERSION" not defined
#endif

//
// These function can only be called from main thread (see above)
//
#if MULLE_CG_GLVERSION == MULLE_GLES2
   glfwWindowHint( GLFW_CONTEXT_VERSION_MAJOR, 2);
	glfwWindowHint( GLFW_CONTEXT_VERSION_MINOR, 0);
#endif
#if MULLE_CG_GLVERSION == MULLE_GLES3
   glfwWindowHint( GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint( GLFW_CONTEXT_VERSION_MINOR, 2);
   glfwWindowHint( GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#endif
#if MULLE_CG_GLVERSION == MULLE_GL
   glfwWindowHint( GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint( GLFW_CONTEXT_VERSION_MINOR, 0);
   glfwWindowHint( GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#endif

	glfwWindowHint( GLFW_RESIZABLE, (styleMask & UIWindowStyleResizable) ? GL_TRUE : GL_FALSE);
	glfwWindowHint( GLFW_VISIBLE,   (styleMask & UIWindowStyleInvisible) ? GL_FALSE : GL_TRUE);

   // not super sure about this, but lets try to avoid "old" OpenGL
   // calls. alas, we are doing OpenGLES 2.0 minimum, so I don't know
   // if this is useful.

   // TODO: create windows invisible always, but make visible after first
   //       render call. pro: window won't show up empty for an unknown
   //       amount of time. con: window won't show up at all for an unknown
   //       amount of time.
   _window = glfwCreateWindow( (int) frame.size.width,
                               (int) frame.size.height,
                               title ? title : "",
                               0,
                               0);
   if( ! _window)
   {
      fprintf( stderr, "glfwCreateWindow failed us\n");
      [self release];
      return( nil);
   }

   // this is basically the "rendezvous" point where nanoVG latches unto
   // its also the receiver for OpenGL calls. That's why we need a window
   // to draw stuff
   //
   glfwSetWindowUserPointer( _window, self);

   // zero origin, let window manager choose
   if( ! CGPointEqualToPoint( frame.origin, CGPointNull))
      glfwSetWindowPos( _window, (int) frame.origin.x, (int) frame.origin.y);

   _mouseLocation          = CGPointMake( -1.0, -1.0);
   _scrollWheelSensitivity = 20.0;

   [self os_startRender];
   _context = [[CGContext alloc] initWithEdgeAntialiasing:!(styleMask & UIWindowStyleNoEdgeAntialias)
                                        useStencilStrokes:!(styleMask & UIWindowStyleNoStencilStrokes)
                                                os_window:self];
   if( styleMask & UIWindowStyleInvisible)
      [_context setRendersOffScreen:YES];
   [self os_endRender];

   return( self);
}


- (void) finalize
{
   [self os_startRender];
   [_context mullePerformFinalize];
   [self os_endRender];

   [self os_destroyWindow];

   [super finalize];
}

- (void) dealloc
{
   [_renderContextLock release];
   [_context release];
   [super dealloc];
}


- (void) os_destroyWindow
{
   if( _window)
   {
      glfwDestroyWindow( _window);
      _window = NULL;
   }
}


+ (CGFloat) os_primaryMonitorPPI
{
   GLFWmonitor      *monitor;
   GLFWvidmode      *mode;
   int              h;
   CGFloat          ppi;

   assert( [NSThread mulleIsMainThread]);

   //
   monitor = glfwGetPrimaryMonitor();
   if( ! monitor)
      return( 0.0);

   h = 0; // for valgrind
   glfwGetMonitorPhysicalSize( monitor, NULL, &h);
   if( ! h)
       return( 0.0);

   mode = (GLFWvidmode *) glfwGetVideoMode( monitor);
   if( ! mode)
       return( 0.0);

   // need to convert h in mm to inches
   ppi = mode->height / (h * 0.03937007874);
   return( ppi);
}


- (CGRect) os_windowFrame
{
   int      xpos;
   int      ypos;
   int      width;
   int      height;
   CGRect   frame;

   assert( [NSThread mulleIsMainThread]);
   assert( _window);

   glfwGetWindowPos( _window, &xpos, &ypos);
   glfwGetWindowSize( _window, &width, &height);  // just to be sure...

   frame.origin = CGPointMake( xpos, ypos);
   frame.size   = CGSizeMake( width, height);
   return( frame);
}


- (CGSize) os_windowSize
{
   int   winWidth;
   int   winHeight;

   assert( [NSThread mulleIsMainThread]);
   assert( _window);

   glfwGetWindowSize( _window, &winWidth, &winHeight);
   return( CGSizeMake( winWidth, winHeight));
}


// bind GL context of the window to the current thread
- (void) os_startRender
{
   // can be called from any thread
   assert( _window);

   [_renderContextLock lock];
   glfwMakeContextCurrent( _window);
}


- (void) os_endRender
{
   // can be called from any thread
   assert( _window);

   glfwMakeContextCurrent( NULL);
   [_renderContextLock unlock];
}


- (struct CGBitmapSize) os_framebufferSize
{
   int   fbWidth;
   int   fbHeight;

   assert( [NSThread mulleIsMainThread]);
   assert( _window);

   glfwGetFramebufferSize( _window, &fbWidth, &fbHeight);
   return( CGBitmapSizeMake( fbWidth, fbHeight));
}


- (void) os_swapBuffers
{
   // can be called from any thread
   // it'as assume that context need not be active here, but is it true ?
   assert( _window);

   glfwSwapBuffers( _window);
}


+ (void) os_setSwapInterval:(NSUInteger) value
{
   glfwSwapInterval( (int) value);  // need for smooth pointer/control sync
}


+ (CGFloat) os_primaryMonitorRefreshRate
{
   GLFWmonitor   *monitor;
   GLFWvidmode   *mode;

   assert( [NSThread mulleIsMainThread]);

   monitor = glfwGetPrimaryMonitor();
   mode    = (GLFWvidmode *) glfwGetVideoMode( monitor);

   return( mode->refreshRate);
}


- (void) os_requestClose
{
   // can be called from any thread
   assert( _window);

   glfwSetWindowShouldClose( _window, GL_TRUE);
}


- (BOOL) os_windowShouldClose
{
   // can be called from any thread
   assert( _window);

   return( glfwWindowShouldClose( _window) ? YES : NO);
}


- (void) os_show
{
   assert( [NSThread mulleIsMainThread]);
   assert( _window);

   glfwShowWindow( _window);
}


- (void) os_hide
{
   assert( [NSThread mulleIsMainThread]);
   assert( _window);

   glfwHideWindow( _window);
}


//
// OS Pasteboard
// prefix with os ?
- (char *) pasteboardCString
{
   assert( [NSThread mulleIsMainThread]);
   assert( _window);

   return( (char *) glfwGetClipboardString( _window));
}


- (void) setPasteboardCString:(char *) s
{
   assert( [NSThread mulleIsMainThread]);
   assert( _window);

   glfwSetClipboardString( _window, s ? s : "");
}

@end
