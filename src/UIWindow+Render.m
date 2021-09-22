//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#define _GNU_SOURCE

#import "UIWindow.h"

#import "import-private.h"

#import "UIWindow+UIEvent.h"
#import "UIView+Layout.h"
#import "UIView+RenderQueue.h"
#import "UIEvent.h"
#import "GLFWWindow.h"


// #define LAYOUT_ANIMATIONS
//#define SWAP_DEBUG



@implementation CGContext( UIWindow)

- (void) setActive:(BOOL) flag
{
   _isActive = flag;
}

@end


@implementation UIWindow ( RenderingAddAllLayoutsToRenderQueue)

// can only be called from main thread :()
- (void) getFrameInfo:(struct CGFrameInfo *) info
{
   float      scale_x, scale_y;
   CGRect     rect;

   assert( info);

   // glfwGetWindowContentScale( _window, &scale_x, &scale_y);
   scale_x = 1.0;
   scale_y = 1.0;

   //
   // assumption is, the optimizing compiler will inline this with -O3
   // and then combine with settings
   //
   memset( info, 0, sizeof( *info));

   rect = CGRectIntegral( _frame);

   info->size               = _frame.size;
   info->framebufferSize    = _framebufferSize;
   info->viewportFrame.size = info->framebufferSize;

   info->UIScale            = CGVectorMake( scale_x, scale_y);
	info->pixelRatio         = info->framebufferSize.width / _frame.size.width;
}


- (void) syncFrameAndFramebufferSizeWithOSWindow
{
   _frame           = [_os_window os_windowFrame];
   _framebufferSize = [_os_window os_framebufferSize];
}



// unused...
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
         _isResizing = NO;
         break;
      }
   }
}


- (NSUInteger) processEvents:(CAAbsoluteTime) now
                   frameRate:(CGFloat) frameRate
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
   assert( frameRate == UIWindowFrameRateUnsynced ||
           frameRate == UIWindowFrameRateAsync ||
           frameRate == UIWindowFrameRateSynced ||
           frameRate <= 1.0);  // why lower than 1fps ??

   return( [self waitForEvents:frameRate == UIWindowFrameRateSynced
                                 ? 1.0 / _primaryMonitorRefreshRate
                                 : frameRate
                           now:now
                  returnsEarly:frameRate == UIWindowFrameRateUnsynced||
                               frameRate == UIWindowFrameRateAsync]);

}


- (void) willRender:(CAAbsoluteTime) renderStart
{
   struct mulle_pointerarrayenumerator   rover;
   UIView                                *view;

#ifdef RENDER_VERBOSE_DEBUG
   fprintf( stderr, "%s %s\n", __PRETTY_FUNCTION__, [self UTF8String]);
#endif

   rover = mulle_pointerarray_enumerate( &_delegateViews);
   while(  mulle_pointerarrayenumerator_next( &rover, (void **) &view))
      [view willRenderWithAbsoluteTime:renderStart];
   mulle_pointerarrayenumerator_done( &rover);
}


- (CGContext *) activateWindowContext
{
   CGContext   *context;

   [_os_window os_startRender];

   context = [_os_window context];
   [context setActive:YES];
   [context setBackgroundColor:_backgroundColor];

   return( context);
}


- (void) deactivateWindowContext:(CGContext *) context
{
   assert( context);
   assert( [context os_window] == _os_window);

   [context setActive:NO];
   [_os_window os_endRender];
}


- (id) draw_os_window
{
   if( _backingStore == UIWindowBackingStoreNonRetained)
      return( _os_window);
   return( _os_offscreen_window);
}


// TODO: memo, maybe the context triggers os_startRender ?
- (CGContext *) activateRenderContext
{
   CGContext   *context;
   id          os_render_window;

   // take renderlock here, relinquish later when wating for events
   // or when someone closes the window
   os_render_window = [self draw_os_window];
   assert( os_render_window);
   [os_render_window os_startRender];

   context = [os_render_window context];
   [context setActive:YES];                        // just a flag
   [context setBackgroundColor:_backgroundColor];  // just a value

   return( context);
}


- (void) deactivateRenderContext:(CGContext *) context
{
   id   os_render_window;

   assert( context);
   os_render_window = [context os_window];
   assert( os_render_window);
   [context setActive:NO];
   [os_render_window os_endRender];
}


//
// Can only swap buffers if we have rendered at least once
// An early incoming windows refresh request needs to be discarded
// 
- (void) swapBuffers
{
   CGImage                      *image;
   struct CGFramebufferBitmap   fb;
   CGContext                    *context;
   CGDrawableOptions            options;
   struct CGFrameInfo           info;
   CGRect                       rect;

   if( _backingStore == UIWindowBackingStoreBuffered)
   {
      context = [self activateRenderContext];
      {
        // need to blit from offscreen window to onscreen here
        // get image of offscreen framebuffer
        // can do this only, if we have rendered something last frame
         fb = [context grabLastRenderedOffscreenFramebuffer:NULL];
      }
      [self deactivateRenderContext:context];

      // if there has nothing been rendered yet, we decline the swap
      if( fb.data.length == 0)
         return;

      // mulle_rgba_dump( fb.data.bytes, fb.info.size.width, fb.info.size.height);
 
      //
      // draw the image we got from the framebuffer into the window
      // 
      context = [self activateWindowContext];
      {
         [self syncFrameAndFramebufferSizeWithOSWindow];
         [self getFrameInfo:&info]; 

         [context beginRender:&info];
         [context clearFramebuffer];  //?? useful

         //
         // here we keep the orignal size during resize
         //
         rect = CGRectMake( 0, 0, fb.info.size.width, fb.info.size.height);
         
         options = CGDrawableOptionsMake( 0.0, 1.0, 0.0, YES);
         // image has to live until when ? can't delete too soon
         // but it's not 100% clear then the right time is
         image = [[[CGImage alloc] initWithRGBABytes:fb.data.bytes
                                          bitmapSize:fb.info.size
                                          imageFlags:CGBitmapEncodingIsFlipped( fb.info.encoding) 
                                                      ? NVG_IMAGE_FLIPY 
                                                      : 0
                                             context:context] autorelease];
         [image drawRect:rect
                 options:&options
                 context:context];

         // just for debugging, draws a frame somewhere
         {
            struct NVGcontext   *vg;

            vg = CGContextGetNVGContext( context);

            // gray rectangle so we know something is drawn...
            nvgBeginPath( vg);
            {
               rect = CGRectInset( rect, 20, 20);
               nvgRect( vg, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
               nvgStrokeWidth( vg, 8);
               nvgStrokeColor( vg, MulleColorMake( 0x8020A0FF));
            }
            nvgStroke( vg);
         }

         [context endRender];      
      }
      [self deactivateWindowContext:context];

      CGFramebufferBitmapDone( &fb);
   }

   if( _willSwapCallback)
      (*_willSwapCallback)( self);

   // context needs to be set here
   if( _swapInterval != _oldSwapInterval)
   {
      context = [self activateWindowContext];
      {
         [GLFWWindow os_setSwapInterval:_swapInterval];  // need 0 for smooth pointer/control sync
      }
      [self deactivateWindowContext:context];

      _oldSwapInterval = _swapInterval;
   }

   [_os_window os_swapBuffers];
   _lastDidFramebufferSwapTimestamp = CAAbsoluteTimeNow();
   if( _didSwapCallback)
      (_didSwapCallback)( self);       
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
// With the parameters, you should be able to render into a different
// context from the window context, with all the delegate calls intact.
//
// A window must not run two renderFrames concurrently!
// A view calling [[self window] context] could get the wrong context
// though. Maybe need a -renderContext ?
// Or should
- (void) renderFrame:(struct CGFrameInfo *) info
             context:(CGContext *) context
{
   long              nsperframe;
   CAAbsoluteTime    renderStart;

   renderStart = CAAbsoluteTimeNow();

   if( _willRenderCallback)
      (*_willRenderCallback)( self, context, info);

   [_renderDelegate windowWillBeginRender:self
                                  context:context];

   /*
    * Layout
    */
   @autoreleasepool
   {
      [self willRender:renderStart];

      [_preLayoutAnimator animateWithAbsoluteTime:renderStart];

      if( _didAnimateCallback)
         (*_didAnimateCallback)( self, context, info, 0);

      if( _willLayoutCallback)
         (*_willLayoutCallback)( self, context, info);

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
         (*_didLayoutCallback)( self, context, info);

      [_postLayoutAnimator animateWithAbsoluteTime:renderStart];

      if( _didAnimateCallback)
         (*_didAnimateCallback)( self, context, info, 1);
   }


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
         (*_didCreateRenderQueueCallback)( self, context, info);

      [CAAnimation animateObjects:&_renderQueue
                     absoluteTime:renderStart];

      //
      // can animations add and subtract layers and views ?
      // they may, but they won't show up this render
      //
      // have no didAnimate callback, because we would like to pipeline
      // with rendering, or but the animation step into the render part ?
      //
      if( _didAnimateCallback)
         (*_didAnimateCallback)( self, context, info, 2);
   }

   /*
    * Render
    */
   @autoreleasepool
   {
      [context beginRender:info];
      [context clearFramebuffer];
      {
         [context renderObjects:&_renderQueue];
      }

      [_renderDelegate windowWillEndRender:self
                                   context:context];

      if( _didRenderCallback)
         (*_didRenderCallback)( self, context, info);

      [context endRender];
   }

   [_renderDelegate windowDidEndRender:self];

   //
   // just don't want to keep dangling stuff here
   // It's nice to see the renderQueue wthe F11 though
   //mulle_pointerarray_reset( &_renderQueue);
}


// 0 is forever
- (BOOL) renderUpToNumberOfFrames:(NSUInteger) maxFrames
{
   struct CGFrameInfo          info;
   struct timespec             diff;
   struct timespec             start;
   struct timespec             end;
   struct timespec             sleep;
   CAAbsoluteTime              timestamp;
   CGContext                   *context;
   CGDrawableOptions           options;
   CGFloat                     frameRate;
   CGImage                     *image;
   NSUInteger                  eventTypes;
   NSUInteger                  frames;
   struct CGFramebufferBitmap  fb;
   BOOL                        rval;

   frames      = 0;
   image       = nil;
   rval        = NO;
   context     = nil;

   for( frames = 0; ! maxFrames || frames != maxFrames; frames++)
   {
      if( _shouldClose)
      {
         rval = YES;
         break;
      }

      /*
       * Rendering
       */
      @autoreleasepool
      {
         context = [self activateRenderContext];
         {
            [self getFrameInfo:&info];  // retrieve newest geometry
            [self renderFrame:&info
                      context:context];
         }
         [self deactivateRenderContext:context];
         context = nil;         // idiot protection
      }
   
      /* 
       * swap 
       */
#ifdef SWAP_DEBUG
      fprintf( stderr, "%s %s swaps framebuffer (frame: %s, buffer: %ld, %ld)\n",
                     __PRETTY_FUNCTION__,
                     [self UTF8String],
                     CGSizeUTF8String( info.size),
                     info.framebufferSize.width, info.framebufferSize.height);
#endif
      [self swapBuffers];

      // now no openGL or CGContext calls should happen
      // as the context has been detached from this thread

      /*
       * Event handling.
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

         // we can get to 29.98 fps when we feed it the last timestamp
         // but is it desirable ?
         timestamp = _lastDidProcessEventsTimestamp
                        ? _lastDidProcessEventsTimestamp
                        : _lastDidFramebufferSwapTimestamp;
         frameRate = _frameRate;

         // just push next one through ASAP or ?
         if( _isResizing)
         {
            _isResizing = NO;
            frameRate   = UIWindowFrameRateUnsynced;
         }

         eventTypes = [self processEvents:timestamp
                                frameRate:frameRate];
         _lastDidProcessEventsTimestamp = CAAbsoluteTimeNow();
      }
   }

   [image release];

   return( rval);
}


- (void) renderLoop
{
   [self renderUpToNumberOfFrames:0];   // FOREVER (or until close :))
}


- (BOOL) renderFrameWaitForNeedsDisplay
{
   BOOL flag;

   [_needsDisplayLock lockWhenCondition:1];
   flag = [self renderUpToNumberOfFrames:1];
   [_needsDisplayLock unlockWithCondition:0];
   return( flag);
}

@end
