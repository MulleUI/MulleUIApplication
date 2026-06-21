//
// UINullWindow - A minimal UIWindow implementation for testing
//
#import "UINullWindow.h"

#import "UINullOSWindow.h"

#import "UIWindowTypes.h"


@implementation UINullWindow

+ (Class) osGraphicsContextClass
{
   return( Nil);
}


- (instancetype) initWithOSWindow:(UINullOSWindow *) osWindow
{
   return( [self initWithOSWindow:osWindow styleMask:0]);
}


- (instancetype) initWithOSWindow:(UINullOSWindow *) osWindow
                         styleMask:(NSUInteger) styleMask
{
   Class                  cls;
   id <UIGraphicsContext> ctx = nil;

   if( self = [super init])
   {
      _OSWindow = [osWindow retain];

      // Reject unsupported retained styles early
      if( styleMask & (UIWindowStyleRetained|UIWindowStyleRetainedOnMainThread))
      {
         // ignore retained styles in null window
         styleMask &= ~(UIWindowStyleRetained|UIWindowStyleRetainedOnMainThread);
      }

      cls = [[self class] osGraphicsContextClass];
      if( cls)
      {
         NSUInteger   options;
         BOOL         aa;

         // Activate first to allow backend to prepare
         [_OSWindow os_activateGraphicsContext];

         options = 0;
         if( styleMask & UIWindowStyleAntiAlias)
         {
            aa = YES;
            if( [_OSWindow isAntiAliasing] == NO)
               aa = NO;
            if( [cls respondsToSelector:@selector( supportsAntiAliasing)])
               if( [cls supportsAntiAliasing] == NO)
                  aa = NO;
            if( aa)
               options |= UIGraphicsUseMSAA;
            else
               options |= UIGraphicsEdgeAntiAliasing;
         }
         if( styleMask & UIWindowStyleForceEdgeAntiAlias)
            options |= UIGraphicsEdgeAntiAliasing;
         if( styleMask & UIWindowStyleClearType)
            options |= UIGraphicsUseClearType;
         if( styleMask & UIWindowStyleStencilStrokes)
            options |= UIGraphicsUseStencilStrokes;
         if( styleMask & UIWindowStyleTraceDrawCalls)
            options |= UIGraphicsTraceDrawCalls;
         if( styleMask & UIWindowStyleNoDrawing)
            options |= UIGraphicsNoDrawing;

         ctx = [cls alloc];
         ctx = [ctx initWithOSGraphicsContext:_OSWindow
                                  nameUTF8String:"UINullWindow"
                                         shareID:[_OSWindow shareID]
                                         options:options];
         if( ctx)
         {
            _renderGraphicsContext = [ctx retain];
            [ctx setState:UIGraphicsContextAssociated|UIGraphicsContextActive];
            [ctx autorelease];
         }
      }
   }
   return( self);
}


- (void) dealloc
{
   [_OSWindow release];
   [super dealloc];
}


#pragma mark - UIWindow Protocol

- (id <UIOSWindow>) OSWindow
{
   return( _OSWindow);
}


- (id <UIGraphicsContext>) renderGraphicsContext
{
   return( _renderGraphicsContext);
}


- (char *) mulleNameUTF8String
{
   return( "UINullWindow");
}


#pragma mark - UIEventReceiver Protocol (Forward to OSWindow)

- (UIWindowEvent *) handleWindowEvent:(UIWindowEvent *) event
{
   return( [[_OSWindow windowEventsReceiver] handleWindowEvent:event]);
}


- (void) receiveRetainedEvent:(UIEvent *) event
{
   [[_OSWindow eventsReceiver] receiveRetainedEvent:event];
}


#pragma mark - UIWindow Protocol Required Methods

- (void *) os_window
{
   return( [_OSWindow os_window]);
}


- (void) renderWithFrameInfo:(struct CGFrameInfo *) info
                 displayBits:(UIWindowDisplayBits) displayBits
{
   UIWindowDisplayBits   (*cb)( UINullWindow *, id <UIGraphicsContext>, struct CGFrameInfo *, UIWindowDisplayBits);

   cb = _rawFrameCallback;
   if( cb)
      (*cb)( self, [self renderGraphicsContext], info, displayBits);
}


- (mulle_relativetime_t) displayFrameIfNeeded:(mulle_absolutetime_t) now
{
   struct UIOSWindowInfo         osInfo;
   UIWindowDisplayBits           displayBits;
   struct CGFrameInfo            frameInfo;
   mulle_relativetime_t          desiredFramerate;
   UIOSWindowFrameCallback_t     cb;
   id <UIOSWindow>               osw;

   (void) now;

   memset( &frameInfo, 0, sizeof( frameInfo));
   memset( &osInfo, 0, sizeof( osInfo));

   osw = [self OSWindow];
   [osw getOSWindowInfo:&osInfo];

   // compute display bits via optional frame callback; default filters mouse motion
   cb = [osw frameCallback];
   displayBits = cb ? (*cb)( osw) : 0;

   // call minimal renderer hook for future use
   [self renderWithFrameInfo:&frameInfo
                 displayBits:displayBits];

   // use normal framerate; if animating, use monitor refresh
   desiredFramerate = UIOSWindowInfoGetFastestFrameRate( &osInfo);
   if( displayBits & UIWindowDisplayNeedsAnimation)
      desiredFramerate = UIOSWindowInfoGetRefreshRate( &osInfo);

   return( desiredFramerate);
}


- (void) syncOSWindowPropertyChangesIfNeeded
{
}


- (void) setNeedsRefresh
{
}


- (BOOL) shouldClose
{
   return( [_OSWindow shouldClose]);
}


- (void) applicationDidAddWindow:(UIApplication *) app
{
}


- (void) applicationDidRemoveWindow:(UIApplication *) app
{
}


- (id) firstResponder
{
   return( nil);
}


- (char *) pasteboardCString
{
   return( NULL);
}


- (void) setPasteboardCString:(char *) s
{
}

@end
