//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "UIView+Layout.h"

#import "UIWindow.h"
#import "UIView+CAAnimation.h"
#import "UIEdgeInsets+CString.h"

#import "import-private.h"


@implementation UIView ( Layout)

// https://developer.apple.com/documentation/uikit/uiview/1622625-sizethatfits?language=objc
- (CGSize) sizeThatFits:(CGSize) size
                context:(CGContext *) context;
{
   // TODO: should use inverse transform on size
   return( [_mainLayer sizeThatFits:size
                            context:context]);
}

- (CGSize) sizeThatFits:(CGSize) size
{
   return( [self sizeThatFits:size
                      context:nil]);
}


# pragma mark -

- (void) beginLayout:(struct CGFrameInfo *) info
{
   [UIView beginAnimations:NULL
                   context:NULL];

   // linear is better for animations that are restarted often,
   // like during a resize
   [UIView setAnimationCurve:UIViewAnimationCurveLinear];

   // if this is too small, it looks more like a glitch than a wanted effect
   // e.g. 0.05 too small
   [UIView setAnimationDuration:0.20];
}


- (void) endLayout
{
   [UIView commitAnimations];
}

#pragma mark - layout


//
// propagate up, but stop if already marked
//
- (void) _setNeedsLayout
{
   UIView   *view;

   view = self;
   do
   {
      if( view->_needsLayout)
         break;
      view->_needsLayout = YES;
   }
   while( (view = view->_superview));
}


- (void) setNeedsLayout
{
   [self _setNeedsLayout]; // patch point
}


//
// by default, the mainLayer fills the contentRect of
// its owning UIView.
//
- (void) layoutLayer:(CALayer *) layer
              inRect:(CGRect) rect
{
   if( layer == _mainLayer)
   {
      [layer setFrame:rect];
    //  [layer setBounds:[self bounds]]; ??
   }
}


//
// restore "builtin" size for layout
// therefore multiple resizes don't accumulate FP errors
// Method is only used if there is autoresizing enabled!
//
- (CGRect) originalFrame
{
   CGRect   frame;

   if( _originalFrame.size.width == 0.0)
      _originalFrame = _frame;

   frame = _originalFrame;
   return( frame);
}


- (void) layoutSubview:(UIView *) view
                inRect:(CGRect) bounds
      autoresizingMask:(UIViewAutoresizing) autoresizingMask
{
   CGRect         frame;
   CGRect         newFrame;
   CGRect         marginalBounds;
   NSInteger      resizeMask;
   NSInteger      stickMask;
   CGSize         layoutSize;
   UIEdgeInsets   insets;

   if( ! autoresizingMask)
      return;

   frame      = [view frame];
   newFrame   = [view originalFrame];
   resizeMask = autoresizingMask & (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
   stickMask  = autoresizingMask & (UIViewAutoresizingStickToMiddle|UIViewAutoresizingStickToCenter);

   insets         = [view margins];
   marginalBounds = UIEdgeInsetsInsetRect( bounds, [view margins]);

   // if too small now, remove from drawing
   // as the drawing code does it too, what's really the point though ?
   // we can cull earlier...
   //
   if( resizeMask)
   {
      if( resizeMask & UIViewAutoresizingFlexibleWidth)
      {
         newFrame.origin.x   = 0.0; // will be added to later
         newFrame.size.width = marginalBounds.size.width;
         if( newFrame.size.width < 0.5)
            newFrame.size.width = 0.0;
      }

      if( resizeMask & UIViewAutoresizingFlexibleHeight)
      {
         newFrame.origin.y    = 0.0; // will be added to later
         newFrame.size.height = marginalBounds.size.height;
         if( newFrame.size.height < 0.5)
            newFrame.size.height = 0.0;
      }
   }

   if( stickMask & UIViewAutoresizingStickToTop)
   {
      if( stickMask & UIViewAutoresizingStickToBottom)
      {
         newFrame.origin.y = CGRectGetMidY( marginalBounds) - newFrame.size.height / 2.0;;
      }
      else
         newFrame.origin.y = marginalBounds.origin.y;
   }
   else
      if( stickMask & UIViewAutoresizingStickToBottom)
      {
         newFrame.origin.y = CGRectGetMaxY( marginalBounds) - newFrame.size.height;
      }
      else
         newFrame.origin.y += marginalBounds.origin.y;


   if( stickMask & UIViewAutoresizingStickToLeft)
   {
      if( stickMask & UIViewAutoresizingStickToRight)
      {
         newFrame.origin.x = CGRectGetMidX( marginalBounds) - newFrame.size.width / 2.0;
      }
      else
         newFrame.origin.x = marginalBounds.origin.x;
   }
   else
      if( stickMask & UIViewAutoresizingStickToRight)
      {
         newFrame.origin.x = CGRectGetMaxX( marginalBounds) - newFrame.size.width;
      }
      else
         newFrame.origin.x += marginalBounds.origin.x;

//   fprintf( stderr, "view: %s f=[%s] o=[%s] m=[%s]\n",
//               [view debugNameCString],
//               CGRectUTF8String( [view frame]),
//               CGRectUTF8String( [view originalFrame]),
//               UIEdgeInsetsUTF8String( [view margins]));
//
//   fprintf( stderr, "resizeMask     : 0x%x\n", resizeMask);
//   fprintf( stderr, "stickMask      : 0x%x\n", stickMask);
//   fprintf( stderr, "marginalBounds : %s\n", CGRectUTF8String( marginalBounds));
//   fprintf( stderr, "newFrame       : %s\n", CGRectUTF8String( newFrame));
//   fprintf( stderr, "bounds         : %s\n", CGRectUTF8String( bounds));

   //
   // if view doesn't fit into bounds, we do what ?
   // culling is done in the renderQueue step (if clipping is set)
   // If clipping is not set UIViewAutoresizingCullAtBounds will be useful
   // as well
   //
   if( ! CGRectContainsRect( marginalBounds, newFrame))
   {
      if( autoresizingMask & UIViewAutoresizingCullAtBounds)
         newFrame.size = CGSizeZero;
      if( autoresizingMask & UIViewAutoresizingClipToBounds)
         newFrame = CGRectIntersection( marginalBounds, newFrame);
   }

   if( ! CGRectEqualToRect( frame, newFrame))
      [view setFrame:newFrame];
}


- (enum UILayoutStrategy) layoutStrategy
{
   return( UILayoutStrategyDefault);
}

// non cached, if this is true, then we can't cache the layer hierarchy
//
- (BOOL) hasAnimatedCachableLayers
{
   struct mulle_pointerarrayenumerator   rover;
   CALayer                               *layer;
   BOOL                                  flag;

   if( [_mainLayer hasAnimations])
      return( YES);

   flag  = NO;
   rover = mulle_pointerarray_enumerate( _layers);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &layer))
   {
      flag = [layer hasAnimations];
      if( flag)
         break;
   }
   mulle_pointerarrayenumerator_done( &rover);
   return( flag);
}


- (void) layoutLayers
{
   struct mulle_pointerarrayenumerator   rover;
   CALayer                               *layer;
   CGRect                                contentRect;

   contentRect = [self contentRect]; // not layoutRect

#ifdef HAVE_RENDER_CACHE
   if( _cacheLayer)
   {
      if( CGRectEqualToRect( contentRect, [_cacheLayer frame]))
         return;
      [_cacheLayer release];
      _cacheLayer = nil;
   }
#endif

   if( ! _willLayoutLayers || (*_willLayoutLayers)( self))
   {
      [self layoutLayer:_mainLayer
                 inRect:contentRect];

      rover = mulle_pointerarray_enumerate( _layers);
      while( _mulle_pointerarrayenumerator_next( &rover, (void **) &layer))
         [self layoutLayer:layer
                    inRect:contentRect];
      mulle_pointerarrayenumerator_done( &rover);

      if( _didLayoutLayers)
         (*_didLayoutLayers)( self);
   }
}


- (void) layoutSubviews
{
   struct mulle_pointerarrayenumerator   rover;
   UIView                                *view;
   CGRect                                bounds;

   if( ! _willLayoutSubviews || (*_willLayoutSubviews)( self))
   {
      bounds = [self layoutRect];
      rover = mulle_pointerarray_enumerate( _subviews);
      while( _mulle_pointerarrayenumerator_next( &rover, (void **) &view))
      {
         [self layoutSubview:view
                     inRect:bounds
            autoresizingMask:[view autoresizingMask]];
      }
      mulle_pointerarrayenumerator_done( &rover);

      if( _didLayoutSubviews)
         (*_didLayoutSubviews)( self);
   }
 
 }

//
// Layouting is strictly top/down. Space is distributed from the top to
// the button via bounds/frame and the code in "layoutSubviews" that
// distributes it.
//
- (void) layout
{
   struct mulle_pointerarrayenumerator   rover;
   UIView                                *view;


   /*
    * TOP/DOWN
    */
   [self setNeedsLayout:NO];

   // start Yoga
   switch( [self layoutStrategy])
   {
   case UILayoutStrategyDefault:
   case UILayoutStrategyContinue :
      break;

   case UILayoutStrategyStop:  // yoga says this because its doing it all
      return;
   }

   // this is the flat possibly hardcoded code, that layouts each layer
   [self layoutLayers];

   // this is the flat possibly hardcoded code, that layouts each subview
   [self layoutSubviews];

   //
   // this is recursive code, triggering possibly more autoresizes
   // or yogas..
   //
   rover = mulle_pointerarray_enumerate( _subviews);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &view))
      [view layout];
   mulle_pointerarrayenumerator_done( &rover);
}


- (void) layoutIfNeeded
{
   if( [self needsLayout])
      [self layout];
}


- (BOOL) isCulledByLayout
{
   return( _frame.size.width == 0.0);
}

@end
