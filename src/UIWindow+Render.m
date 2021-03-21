//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#define _GNU_SOURCE

#import "UIWindow.h"

#import "import-private.h"

#import "UIWindow+UIEvent.h"
#import "UIView+Layout.h"
#import "CGContext.h"
#import "CATime.h"
#import "UIEvent.h"
#include <time.h>
#include "mulle-timespec.h"


// #define PRINTF_PROFILE_RENDER
// #define PRINTF_PROFILE_EVENTS
// #define PRINTF_PROFILE_LAYOUT
// #define LAYOUT_ANIMATIONS


@implementation UIWindow ( Rendering)

- (CGContext *) createContext
{
   CGContext  *context;

   [self os_startRender];
   context = [CGContext object];
   [self os_endRender];

   return( context);
}

// can only be called from main thread :()
- (void) getFrameInfo:(struct MulleFrameInfo *) info
{
   float   scale_x, scale_y;

   assert( info);

   // glfwGetWindowContentScale( _window, &scale_x, &scale_y);
   scale_x = 1.0;
   scale_y = 1.0;

   info->frame           = _frame;
   info->windowSize      = _windowSize;
   info->framebufferSize = _framebufferSize;
   info->UIScale         = CGVectorMake( scale_x, scale_y);
	info->pixelRatio      = info->framebufferSize.width / info->windowSize.width;
   info->isPerfEnabled   = NO;
   info->renderFrame     = _didRender;

   // does not do refreshRate yet, the renderloop does this
}


- (void) requestClose
{
   [self os_requestClose];
}


// glitch hunt:
//
// a) we sometimes overflow the current frame
// b) we are doublebuffering
// c) the glitch occurs when there is already drawing on the screen
// d) the glitch looks like the buffer is cleared and then not swapped
//
- (void) renderFrameWithContext:(CGContext *) context
                      frameInfo:(struct MulleFrameInfo *) info
{
   struct timespec   diff;
   struct timespec   start;
   struct timespec   end;
   struct timespec   sleep;
   long              nsperframe;

   clock_gettime( CLOCK_REALTIME, &start);

#ifdef PRINTF_PROFILE_LAYOUT
      printf( "@%ld:%09ld layout start\n", start.tv_sec, start.tv_nsec);
#endif
   /*
    * Layout and animate
    */
   @autoreleasepool
   {
      CAAbsoluteTime   renderTime;

      renderTime = CAAbsoluteTimeWithTimespec( start);

      if( _willAnimateCallback)
         (*_willAnimateCallback)( self, context, info, renderTime);

      // this must run before layouting
      [self willAnimateWithAbsoluteTime:renderTime];

      if( _willLayoutCallback)
         (*_willLayoutCallback)( self, context, info, renderTime);

      // do layout before the animation step, as this will generate animations
#if LAYOUT_ANIMATIONS
      [self startLayoutWithFrameInfo:info];
#endif
      [self layoutIfNeeded];

#if LAYOUT_ANIMATIONS
      [self endLayout];
#endif

      if( _didLayoutCallback)
         (*_didLayoutCallback)( self, context, info, renderTime);

      [self animateWithAbsoluteTime:renderTime];

      if( _didAnimateCallback)
         (*_didAnimateCallback)( self, context, info, renderTime);
   }

#ifdef PRINTF_PROFILE_LAYOUT
   clock_gettime( CLOCK_REALTIME, &end);
   diff = timespec_sub( end, start);
   printf( "@%ld:%09ld lavout end, elapsed : %09ld\n", end.tv_sec, end.tv_nsec,
                                                  diff.tv_sec ? 999999999 : diff.tv_nsec);
#endif

#ifdef PRINTF_PROFILE_RENDER
   clock_gettime( CLOCK_REALTIME, &start);
   printf( "@%ld:%09ld render start\n", start.tv_sec, start.tv_nsec);
#endif

   /*
    * Render
    */
   @autoreleasepool
   {
      // nvgGlobalCompositeOperation( ctxt->vg, NVG_ATOP);

      [self updateRenderCachesWithContext:context
                                frameInfo:info];

      [context clearFramebuffer];
      [context startRenderWithFrameInfo:info];
      [self renderWithContext:context];

      if( _didRenderCallback)
         (*_didRenderCallback)( self, context, info);

      [context endRender];
   }
#ifdef PRINTF_PROFILE_RENDER
   clock_gettime( CLOCK_REALTIME, &end);
   diff = timespec_diff( start, end);
   nsperframe = (1000000000L + (info.refreshRate - 1)) / info.refreshRate;
   if( diff.tv_sec > 0 || diff.tv_nsec >= nsperframe)
      fprintf( stderr, "frame #%ld: @%ld:%09ld render end, OVERFLW %.4f frames\n",
                           _didRender,
                           end.tv_sec,
                           end.tv_nsec,
                           diff.tv_sec ? 9999.9999 : (diff.tv_nsec / (double) nsperframe) - 1);
#endif
}


// 0 is forever
- (BOOL) renderLoopWithContext:(CGContext *) context
             maxFramesToRender:(NSUInteger) maxFrames
{
   struct MulleFrameInfo   info;
   struct timespec         diff;
   struct timespec         start;
   struct timespec         end;
   struct timespec         sleep;
   long                    nsperframe;
   CGRect                  oldFrame;
   NSUInteger              frames;
   BOOL                    rval;

   assert( context);

   // take renderlock here, relinquish later when wating for events
   // or when someone closes the window

   [self os_startRender];
   // put elsewhere
   [UIWindow os_setSwapInterval:0];  // need for smooth pointer/control sync

   // should check the monitor where the window is on really
   info.refreshRate = _primaryMonitorRefreshRate;

#ifdef PRINTF_PROFILE_RENDER
   clock_gettime( CLOCK_REALTIME, &end);
   nsperframe = (1000000000L + (info.refreshRate - 1)) / info.refreshRate;
   fprintf( stderr, "Refresh: %d (%09ld ns/frame)\n", info.refreshRate, nsperframe);
#endif

   oldFrame = _frame;
   frames   = 0;
   rval     = NO;
   for(;;)
   {
      // TODO: fenster eigenes flag verwenden
      if( _shouldClose)
      {
         rval = YES;
         break;
      }
     
      if( maxFrames && frames == maxFrames)
         break;
      ++frames;

      [self getFrameInfo:&info];  // retrieve newest geometry
      // info.isPerfEnabled = YES;
      [self renderFrameWithContext:context
                         frameInfo:&info];

      [self os_swapBuffers];
      _didRender++;
      [self os_endRender];

#ifdef ADD_RANDOM_LAG
      sleep.tv_sec  = 0.0;
      sleep.tv_nsec = nsperframe / 10 * (rand() % 100);
      nanosleep( &sleep, NULL);
#endif

#ifdef DEBUG
      if( ! CGRectEqualToRect( _frame, oldFrame))
      {
         [self dump];
         oldFrame = _frame;
      }
#endif

#ifdef PRINTF_PROFILE_RENDER
      clock_gettime( CLOCK_REALTIME, &end);
      diff = timespec_sub( end, start);
      printf( "@%ld:%09ld render end, elapsed : %09ld\n", end.tv_sec, end.tv_nsec,
                                                  diff.tv_sec ? 999999999 : diff.tv_nsec);
#endif

#ifdef PRINTF_PROFILE_EVENTS
      clock_gettime( CLOCK_REALTIME, &start);
      printf( "@%ld:%09ld events start\n", start.tv_sec, start.tv_nsec);
#endif
      /*
       * Event handling
       */
      @autoreleasepool
      {
         [self setupQuadtree];
      }

      if( maxFrames == 1)
         return( NO);  // don't break!

      @autoreleasepool
      {
         // use at max 200 Hz refresh rate (0: polls)
         // use 0.001Hz for event debugging. The wait time is "max", events
         // will be processed if something comes in and then render will be
         // immediate anyway. Animations won't be processed though..

         // For multi-threaded apps this is a bug. Only the main thread 
         // may call this.If we only render one frame though, we don't wait
         // for events at all 

         [self waitForEvents:60.0]; // 0.001];
         if( _resizing)
         {
            // during resizing keep viewport as it was before resize until
            // the resize is done... how do we know the resize is done ?
            // dunno... Also ignore mouse events during resize
            CAAbsoluteTime   now;
            
            now = [context renderStartTimestamp];
            // end resize for now
            if( _lastResizeEventTimestamp + 0.2 >= now)
               _resizing = NO;
         }
      }

#ifdef PRINTF_PROFILE_EVENTS
      clock_gettime( CLOCK_REALTIME, &end);
      diff = timespec_sub( end, start);
      printf( "@%ld:%09ld events end, elapsed : %09ld\n", end.tv_sec, end.tv_nsec,
                                                  diff.tv_sec ? 999999999 : diff.tv_nsec);
#endif
      [self os_startRender];
   }
   [self os_endRender];
   return( rval);
}


- (void) renderLoopWithContext:(CGContext *) context
{
   [self renderLoopWithContext:context
             maxFramesToRender:0];   // FOREVER (or until close :))
}


- (BOOL) renderFrameWaitForNeedsDisplayWithContext:(CGContext *) context
{
   BOOL    flag;

   [_needsDisplayLock lockWhenCondition:1];   
   flag = [self renderLoopWithContext:context
                    maxFramesToRender:1];
   [_needsDisplayLock unlockWithCondition:0];   
   return( flag);
}

@end
