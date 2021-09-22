//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
// prefer a local UIView over one in import.h
#import "UIView.h"




typedef enum
{
   UIViewContentModeScaleToFill     = CGContentModeScaleToFill,
   UIViewContentModeScaleAspectFit  = CGContentModeScaleAspectFit,
   UIViewContentModeScaleAspectFill = CGContentModeScaleAspectFill,

//   UIViewContentModeRedraw,  // not supported

   UIViewContentModeCenter      = CGContentModeCenterPoint,

   UIViewContentModeTop         = CGContentModeTop,
   UIViewContentModeBottom      = CGContentModeBottom,
   UIViewContentModeLeft        = CGContentModeLeft,
   UIViewContentModeRight       = CGContentModeRight,

   UIViewContentModeTopLeft     = CGContentModeTopLeft,
   UIViewContentModeTopRight    = CGContentModeTopRight,
   UIViewContentModeBottomLeft  = CGContentModeBottomLeft,
   UIViewContentModeBottomRight = CGContentModeBottomRight
} UIViewContentMode;
#define N_UIViewContentModes 12


#define UIViewContentModeNames      CGContentModeNames

static inline char   *UIViewContentModeUTF8String( UIViewContentMode mode)
{
   return( CGContentModeUTF8String( (CGContentMode) mode));
}


static inline UIViewContentMode  UIViewContentModeParseCString( char *s)
{
   return( (UIViewContentMode) CGContentModeParseCString( s));
}



enum UILayoutStrategy
{
   UILayoutStrategyDefault,
   UILayoutStrategyContinue,
   UILayoutStrategyStop
};



/*
 * The layout first calls layoutLayers and then calls layoutSubviews.
 *
 * A UIView has some properties that define its wishes how to be placed
 * into a superview. First of all is the frame. If the autoresizingMask of
 * the view is UIViewAutoresizingNone, then the frame is absolute and should
 * not be changed ever by the superview.
 *
 * Otherwise the UIView can indicate, if it wants to be stretched
 * in a horizontal or vertical fashion or both.
 *
 * A stretched view will cover the entire given bounds. The given bounds are
 * reduced by the margins though. That effectively creates some distance from
 * the bounds.
 *
 * The non stretchable dimension can indicate a preferred sticking point,
 * which could be top/left for example.
 */
typedef enum
{
   UILayoutConstraintAxisVertical   = CGVerticalAxis,
   UILayoutConstraintAxisHorizontal = CGHorizontalAxis
} UILayoutConstraintAxis;


@interface UIView( Layout)

- (void) setNeedsLayout;    // use this to touch up all hierarchy
- (void) _setNeedsLayout;


// calls sizeThatFits:context: with nil
- (CGSize) sizeThatFits:(CGSize) size;

// actual method
- (CGSize) sizeThatFits:(CGSize) size
                context:(CGContext *) context;

//
// You do not need not to call super in UIView subclasses, if you manually
// layout everything.
//

// layoutSubviews will call -layoutSubview:inRect:autoresizingMask: on all
// subviews. The bounds passed will be the -layoutRect.
- (void) layoutSubviews;

//
// layoutLayers will call -layoutSubview:inRect: on each layer. Bounds will
// be the -bounds. .
//
- (void) layoutLayers;

- (void) beginLayout:(struct CGFrameInfo *) info;
- (void) endLayout;

- (void) layout;
- (void) layoutIfNeeded;

// will layout the subview in the bounds according to the autoresizingMask
- (void) layoutSubview:(UIView *) view
                inRect:(CGRect) bounds
      autoresizingMask:(UIViewAutoresizing) autoresizingMask;

//
// will layout the all layers so that its frame equals the bounds, will leave
// all other layers untouched
//
- (void) layoutLayer:(CALayer *) layer
              inRect:(CGRect) bounds;

// yoga uses this to its layout
- (enum UILayoutStrategy) layoutStrategy;

// if layout can't fit it in, or subview is out of bounds
// its frame.size is set to zero. The original size is kept in -mulleLayoutSize
// it's better to check this method though as I might change by mind...
- (BOOL) isCulledByLayout;

// does not conside the cacheLayer because its used to figure out if we
// can use the cacheLayer.
- (BOOL) hasAnimatedCachableLayers;

@end
