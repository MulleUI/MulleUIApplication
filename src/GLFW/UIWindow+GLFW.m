//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#ifdef __has_include
# if __has_include( "UIWindow.h")
#  import "UIWindow.h"
# endif
#endif

#import "import-private.h"

#import "UIWindow+UIEvent.h"


// Due to the way GLFW is setup,
@implementation UIWindow ( GLFW)

static void   keyCallback( GLFWwindow* window,
                           int key,
                           int scancode,
                           int action,
                           int mods)
{
   UIWindow   *self;

   assert( [NSThread mulleIsMainThread]);

   self = glfwGetWindowUserPointer( window);
   [self _keyCallback:key
             scancode:scancode
               action:action
            modifiers:mods];
}


void   charCallback(GLFWwindow* window, unsigned int codepoint)
{
   UIWindow   *self;

   assert( [NSThread mulleIsMainThread]);

   self = glfwGetWindowUserPointer( window);
   [self _charCallback:codepoint];
}


static void   mouseButtonCallback( GLFWwindow* window,
                                   int button,
                                   int action,
                                   int mods)
{
   UIWindow   *self;

   assert( [NSThread mulleIsMainThread]);

   self  = glfwGetWindowUserPointer( window);
   [self _mouseButtonCallback:button
                       action:action
                    modifiers:mods];
}


static void   mouseMotionCallback( GLFWwindow* window,
                                 double xpos,
                                 double ypos)
{
   UIWindow   *self;

   assert( [NSThread mulleIsMainThread]);

   self = glfwGetWindowUserPointer( window);
   [self _mouseMotionCallback:CGPointMake( xpos, ypos)];
}


static void   mouseScrollCallback( GLFWwindow *window,
                                   double xoffset,
                                   double yoffset)
{
   UIWindow   *self;

   assert( [NSThread mulleIsMainThread]);

   self  = glfwGetWindowUserPointer( window);
   [self _mouseScrollCallback:CGPointMake( xoffset, yoffset)];
}


static void   windowMoveCallback( GLFWwindow* window, int xpos, int ypos)
{
   UIWindow   *self;

   assert( [NSThread mulleIsMainThread]);

   self = glfwGetWindowUserPointer( window);
   [self _windowMoveCallback:CGPointMake( xpos, ypos)];
}


static void   windowRefreshCallback( GLFWwindow* window)
{
   UIWindow   *self;

   assert( [NSThread mulleIsMainThread]);

   self = glfwGetWindowUserPointer( window);
   [self _windowRefreshCallback];
}


static void   windowCloseCallback( GLFWwindow* window)
{
   UIWindow   *self;

   assert( [NSThread mulleIsMainThread]);

   self = glfwGetWindowUserPointer( window);
   [self _windowCloseCallback];
}

// framebufferResize is more interesting though
static void   windowResizeCallback( GLFWwindow* window, int width, int height)
{
   UIWindow   *self;

   assert( [NSThread mulleIsMainThread]);

   self = glfwGetWindowUserPointer( window);
   [self _windowResizeCallback:CGSizeMake( width, height)];
}


static void   framebufferResizeCallback( GLFWwindow* window, int width, int height)
{
   UIWindow   *self;
   CGRect     frame;

   assert( [NSThread mulleIsMainThread]);

   self = glfwGetWindowUserPointer( window);
   [self _framebufferResizeCallback:CGSizeMake( width, height)];
}


- (void) os_initEvents
{
   assert( _window);

   assert( [NSThread mulleIsMainThread]);

   // input device events
   glfwSetMouseButtonCallback( _window, mouseButtonCallback);
   glfwSetCursorPosCallback( _window, mouseMotionCallback);
   glfwSetKeyCallback( _window, keyCallback);
   glfwSetCharCallback( _window, charCallback);
   glfwSetScrollCallback( _window, mouseScrollCallback);

   // window events
   glfwSetWindowSizeCallback( _window, windowResizeCallback);
   glfwSetWindowPosCallback( _window, windowMoveCallback);
   glfwSetFramebufferSizeCallback( _window, framebufferResizeCallback);
   glfwSetWindowRefreshCallback( _window, windowRefreshCallback);
   glfwSetWindowCloseCallback( _window, windowCloseCallback);
}

- (void *) os_createWindowWithFrame:(CGRect) frame
                       titleCString:(char *) title
                          styleMask:(NSUInteger) styleMask
{
   void   *window;

   assert( [NSThread mulleIsMainThread]);

#if MULLE_UI_GLVERSION == MULLE_GLES2
   glfwWindowHint( GLFW_CONTEXT_VERSION_MAJOR, 2);
	glfwWindowHint( GLFW_CONTEXT_VERSION_MINOR, 0);
#endif
#if MULLE_UI_GLVERSION == MULLE_GLES3
   glfwWindowHint( GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint( GLFW_CONTEXT_VERSION_MINOR, 2);
   glfwWindowHint( GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#endif
#if MULLE_UI_GLVERSION == MULLE_GL
   glfwWindowHint( GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint( GLFW_CONTEXT_VERSION_MINOR, 0);
   glfwWindowHint( GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#endif

   if( styleMask & MulleWindowStyleMaskResizable)
   	glfwWindowHint( GLFW_RESIZABLE, GL_TRUE);
   if( styleMask & MulleWindowStyleMaskInvisible)
   	glfwWindowHint( GLFW_VISIBLE, GL_FALSE);

   // not super sure about this, but lets try to avoid "old" OpenGL
   // calls. alas, we are doing OpenGLES 2.0 minimum, so I don't know
   // if this is useful.

   // TODO: create windows invisible always, but make visible after first
   //       render call. pro: window won't show up empty for an unknown
   //       amount of time. con: window won't show up at all for an unknown
   //       amount of time.
   window = glfwCreateWindow( (int) frame.size.width,
                              (int) frame.size.height,
                              title ? title : "",
                              0,
                              0);
   if( ! window)
   {
      fprintf( stderr, "glfwCreateWindow failed us\n");
      return( NULL);
   }

   // this is basically the "rendezvous" point where nanoVG latches unto
   // its also the receiver for OpenGL calls. That's why we need a window
   // to draw stuff
   //
   glfwSetWindowUserPointer( window, self);

   return( window);
}


- (void) os_destroyWindow
{
   glfwDestroyWindow( _window);
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


- (void) os_syncFrameWithWindow
{
   int   xpos;
   int   ypos;
   int   width;
   int   height;

   assert( [NSThread mulleIsMainThread]);
   assert( _window);

   glfwGetWindowPos( _window, &xpos, &ypos);
   glfwGetWindowSize( _window, &width, &height);  // just to be sure...

   _frame.origin = CGPointMake( xpos, ypos);
   _frame.size   = CGSizeMake( width, height);
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


- (CGSize) os_windowSize
{
   int   winWidth;
   int   winHeight;

   assert( [NSThread mulleIsMainThread]);
   assert( _window);

   glfwGetWindowSize( _window, &winWidth, &winHeight);
   return( CGSizeMake( winWidth, winHeight));
}


- (CGSize) os_framebufferSize
{
   int   fbWidth;
   int   fbHeight;

   assert( [NSThread mulleIsMainThread]);
   assert( _window);

   glfwGetFramebufferSize( _window, &fbWidth, &fbHeight);
   return( CGSizeMake( fbWidth, fbHeight));
}


- (void) os_swapBuffers
{
   // can be called from any thread
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
