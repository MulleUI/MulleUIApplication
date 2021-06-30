//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#define _GNU_SOURCE

#import "UIWindow.h"

#import "import-private.h"

#import "UIWindow+UIEvent.h"
#import "UIView+Layout.h"
#import "UIWindow+RenderQueue.h"
#import "UIEvent.h"


// #define PRINTF_PROFILE_RENDER
// #define PRINTF_PROFILE_EVENTS
// #define PRINTF_PROFILE_LAYOUT
// #define LAYOUT_ANIMATIONS
// #define SWAP_DEBUG

@implementation UIWindow ( RenderingAddAllLayoutsToRenderQueue)

- (CGContext *) context
{
   assert( _context);
   return( _context);
}


// can only be called from main thread :()
- (void) getFrameInfo:(struct CGFrameInfo *) info
{
   float      scale_x, scale_y;

   assert( info);

   // glfwGetWindowContentScale( _window, &scale_x, &scale_y);
   scale_x = 1.0;
   scale_y = 1.0;

   //
   // assumption is, the optimizing compiler will inline this with -O3
   // and then combine with settings
   //
   memset( info, 0, sizeof( *info));

   info->size                 = _frame.size;
   info->viewportFrame.size   = _frame.size;
   info->framebufferSize      = [self framebufferSize];

   info->UIScale              = CGVectorMake( scale_x, scale_y);
	info->pixelRatio           = info->framebufferSize.width / _frame.size.width;
   info->frameNumber          = _didRender;
   info->renderStart          = CAAbsoluteTimeNow();
   // should check the monitor where the window is on really
   info->monitorRefreshRate   = _primaryMonitorRefreshRate;

   // does not do refreshRate yet, the renderloop does this
}


- (void) waitForEndOfResize
{
   double   waitEnd;

   //
   // keep viewport as is, so that resize scales the window
   // hopefully
   //
   for(;;)
   {
      waitEnd = glfwGetTime() + 1.0 / 5.0;
      glfwWaitEventsTimeout( 1.0 / 5.0);
      if( waitEnd >= glfwGetTime())
      {
         glViewport( 0.0, 0.0, _resizeSize.width, _resizeSize.height);
         _resizing = NO;
         break;
      }
   }
}


- (NSUInteger) processEvents:(CAAbsoluteTime) now
{
   CARelativeTime   timeout;

   // Four cases:
   // UIWindowFrameRateUnsynced (0.0), UIWindowFrameRateAsync (INFINITE)
   // UIWindowFrameRateSynced (which is the primary monitor refresh rate)
   // or a framerate like 1/60.0 for 60 Hz
   //
   // UIWindowFrameRateUnsynced: timout == INFINITE, returnsEarly: YES
   // UIWindowFrameRateAsync: timout == 0.0  returnsEarly: YES
   // Else timeout: returnsEarly: NO
   assert( _frameRate == UIWindowFrameRateUnsynced ||
           _frameRate == UIWindowFrameRateAsync ||
           _frameRate == UIWindowFrameRateSynced ||
           _frameRate <= 1.0);  // why lower than 1fps ??

   return( [self waitForEvents:_frameRate == UIWindowFrameRateSynced
                                 ? 1.0 / _primaryMonitorRefreshRate
                                 : _frameRate
                           now:now
                  returnsEarly:_frameRate == UIWindowFrameRateUnsynced||
                               _frameRate == UIWindowFrameRateAsync]);

}


- (void) willRender:(struct CGFrameInfo *) info
{
   struct mulle_pointerarrayenumerator   rover;
   UIView                                *view;

#ifdef RENDER_VERBOSE_DEBUG
   fprintf( stderr, "%s %s\n", __PRETTY_FUNCTION__, [self cStringDescription]);
#endif

   rover = mulle_pointerarray_enumerate( &_delegateViews);
   while(  mulle_pointerarrayenumerator_next( &rover, (void **) &view))
      [view willRenderWithAbsoluteTime:info->renderStart];
   mulle_pointerarrayenumerator_done( &rover);
}

// UIWindow render chain
//
//    Creates a queue of CALayers from the UIView hierarchy. Layers are
//    setup so they draw themselves into the window coordinate space.
//
//                                                  UIWindow Delegate Views
//  .----------------------------------------.      .---.---.
//  | UIWindow willRenderWithAbsoluteTime:   |      | B | C |
//  '----------------------------------------'      '---'---'
//                       |
//                       |
//                       v                          UIView hierarchy tree
//  .-----------------------------------------.           .---.
//  | UIView layout                           |           | A |-.
//  '-----------------------------------------'           '---' |
//                       |                                |     |
//                       |                          .---. |     |
//                       v                          | B |<'     v
//  .-----------------------------------------.     '---'     .---.
//  | UIView createRenderQueue:               |               | C |
//  '-----------------------------------------'               '---'
//                       |                                  |
//    From here on the   |                                  |
//    only hierarchy     |                                  |
//    is the order       |                                  |
//    of the layers in   |                                  v
//    the queue.         |
//                       v                          CALayer Render Queue
//  .------------------------------------------.    .---.---.---.---.---.----.
//  | CGAnimation animateObjects:absoluteTime: |    | A1| B1| B2| C1| C2| C3 |
//  '------------------------------------------'    '---'---'---'---'---'----'
//                       |
//                       |
//                       v
//  .-----------------------------------------.
//  | CGContext renderObjects:                |
//  '-----------------------------------------'
//
// glitch hunt:
//
// a) we sometimes overflow the current frame
// b) we are doublebuffering
// c) the glitch occurs when there is already drawing on the screen
// d) the glitch looks like the buffer is cleared and then not swapped
//
- (void) renderFrame:(struct CGFrameInfo *) info
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

   [_renderDelegate windowWillBeginRender:self];

   if( _willRenderCallback)
      (*_willRenderCallback)( self, info);

   /*
    * Layout
    */
   @autoreleasepool
   {
      [self willRender:info];

      [_preLayoutAnimator animateWithAbsoluteTime:info->renderStart];

      if( _didAnimateCallback)
         (*_didAnimateCallback)( self, info, 0);

      if( _willLayoutCallback)
         (*_willLayoutCallback)( self, info);

      //
      // do layout before the animation step, as this may generate animations
      //
#if LAYOUT_ANIMATIONS
      [self beginLayout:info];
#endif


      [self layoutIfNeeded];

#if LAYOUT_ANIMATIONS
      [self endLayout];
#endif
      if( _didLayoutCallback)
         (*_didLayoutCallback)( self, info);

      [_postLayoutAnimator animateWithAbsoluteTime:info->renderStart];

   }

   if( _didAnimateCallback)
      (*_didAnimateCallback)( self, info, 1);

   /*
    * Animate
    */
   @autoreleasepool
   {
      //
      // create the renderQueue. This will set the transforms for all
      // the layer and calculate the actual opacity, which is then stored
      // in layer transform and layer alpha.
      //
      _mulle_pointerarray_reset( &_renderQueue);
      [self createRenderQueue:&_renderQueue];
      if( _didCreateRenderQueueCallback)
         (*_didCreateRenderQueueCallback)( self, info);

      [CAAnimation animateObjects:&_renderQueue
                     absoluteTime:info->renderStart];

      //
      // can animations add and subtract layers and views ?
      // they may, but they won't show up this render
      //
      // have no didAnimate callback, because we would like to pipeline
      // with rendering, or but the animation step into the render part ?
      //
   }
   if( _didAnimateCallback)
      (*_didAnimateCallback)( self, info, 2);

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
      [_context clearFramebuffer];
      [_context beginRender:info];
      {
         [_context renderObjects:&_renderQueue];
      }

      [_renderDelegate windowWillEndRender:self];

      if( _willEndRenderCallback)
         (*_willEndRenderCallback)( self, info);

      [_context endRender];
   }

   [_renderDelegate windowDidEndRender:self];

   if( _didEndRenderCallback)
      (*_didEndRenderCallback)( self, info);

   //
   // just don't want to keep dangling stuff here
   // It's nice to see the renderQueue wthe F11 though
   //mulle_pointerarray_reset( &_renderQueue);

#ifdef PRINTF_PROFILE_RENDER
   clock_gettime( CLOCK_REALTIME, &end);
   diff = timespec_diff( start, end);
   nsperframe = (1000000000L + (info.monitorRefreshRate - 1)) / info.monitorRefreshRate;
   if( diff.tv_sec > 0 || diff.tv_nsec >= nsperframe)
      fprintf( stderr, "frame #%ld: @%ld:%09ld render end, OVERFLW %.4f frames\n",
                           _didRender,
                           end.tv_sec,
                           end.tv_nsec,
                           diff.tv_sec ? 9999.9999 : (diff.tv_nsec / (double) nsperframe) - 1);
#endif
}


// 0 is forever
- (BOOL) renderUpToNumberOfFrames:(NSUInteger) maxFrames
{
   struct CGFrameInfo   info;
   struct timespec         diff;
   struct timespec         start;
   struct timespec         end;
   struct timespec         sleep;
   long                    nsperframe;
   CGRect                  oldFrame;
   NSUInteger              frames;
   BOOL                    rval;

#ifdef PRINTF_PROFILE_RENDER
      clock_gettime( CLOCK_REALTIME, &start);
      nsperframe = (1000000000L + (info.monitorRefreshRate - 1)) / info.monitorRefreshRate;
      fprintf( stderr, "Refresh: %d (%09ld ns/frame)\n", info.monitorRefreshRate, nsperframe);
#endif

   // take renderlock here, relinquish later when wating for events
   // or when someone closes the window
   [self os_startRender];

   // put elsewhere
   [UIWindow os_setSwapInterval:_swapInterval];  // need 0 for smooth pointer/control sync


   oldFrame = _frame;
   frames   = 0;
   rval     = NO;
   for(;;)
   {
      if( _shouldClose)
      {
         rval = YES;
         break;
      }

      if( maxFrames && frames == maxFrames)
         break;
      ++frames;

      [self getFrameInfo:&info];  // retrieve newest geometry
      [self renderFrame:&info];

#ifdef SWAP_DEBUG
      fprintf( stderr, "%s %s swaps framebuffer (frame: %s, buffer: %s)\n",
                     __PRETTY_FUNCTION__,
                     [self cStringDescription],
                     CGRectCStringDescription( info.frame),
                     CGSizeCStringDescription( info.framebufferSize));
#endif
      [self os_swapBuffers];
      _lastDidFramebufferSwapTimestamp = CAAbsoluteTimeNow();
      if( _didSwapCallback)
         (_didSwapCallback)( self, &info);
      _didRender++;
      [self os_endRender];

#ifdef PRINTF_PROFILE_RENDER
      clock_gettime( CLOCK_REALTIME, &end);
      diff = timespec_sub( end, start);
      printf( "@%ld:%09ld render end, elapsed : %09ld\n", end.tv_sec, end.tv_nsec,
                                                  diff.tv_sec ? 999999999 : diff.tv_nsec);
#endif

#ifdef ADD_RANDOM_LAG
      sleep.tv_sec  = 0.0;
      sleep.tv_nsec = nsperframe / 10 * (rand() % 100);
      nanosleep( &sleep, NULL);
#endif

#if 0 && defined( DEBUG)
      if( ! CGRectEqualToRect( _frame, oldFrame))
      {
         [self dump];
         oldFrame = _frame;
      }
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
         //
         // TODO: More useful to this when a mouse event hits on demand ?
         //       But then how can we be sure, that the tree is 100%
         //       identical to what is shown and that no changes have been
         //       done inbetween ?
         //
         [self setupQuadtree];
      }

      if( maxFrames == 1)
         return( NO);  // don't break!

      @autoreleasepool
      {
         // we can get to 29.98 fps when we feed it the last timestamp
         // but is it desirable ?
         [self processEvents:_lastDidProcessEventsTimestamp ? _lastDidProcessEventsTimestamp : info.renderStart];
         _lastDidProcessEventsTimestamp = CAAbsoluteTimeNow();
      }

#ifdef PRINTF_PROFILE_EVENTS
      clock_gettime( CLOCK_REALTIME, &end);
      diff = timespec_sub( end, start);
      printf( "@%ld:%09ld events end, elapsed : %09ld\n", end.tv_sec, end.tv_nsec,
                                                  diff.tv_sec ? 999999999 : diff.tv_nsec);
#endif
#ifdef PRINTF_PROFILE_START
      clock_gettime( CLOCK_REALTIME, &start);
#endif
      [self os_startRender];

   }
   [self os_endRender];
   return( rval);
}


- (void) renderLoop
{
   [self renderUpToNumberOfFrames:0];   // FOREVER (or until close :))
}


- (BOOL) renderFrameWaitForNeedsDisplay
{
   BOOL    flag;

   [_needsDisplayLock lockWhenCondition:1];
   flag = [self renderUpToNumberOfFrames:1];
   [_needsDisplayLock unlockWithCondition:0];
   return( flag);
}

@end
