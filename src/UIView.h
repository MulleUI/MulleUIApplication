#import "import.h"

#import "UITrackingArea.h"
#import "UIEdgeInsets.h"


@class UIWindow;

struct CGFrameInfo;

// The "raison d^etre" of UIView
// =============================
// UIView is mainly there to handle UIEvents and to set up the transformation
// for its CALayers (position the layers on the framebuffer).
// UIViews are also there to provide a child/parent hierarchy to make it
// easier to create complex userinterfaces.
//
// If events didn't exist, one could get by with just layers.
//
// A UIView does no drawing, it merely layouts. It is completely independent
// from OpenGL or whatever the backend is.
//
// The "standard" UIView hierarchy.
// =================================
// frame.origin          UIView
//      .--------------------------------------.
//      |bounds.origin                         |
//      |               frame.origin           |
//      |                    .-----------.     |
//      |                    |           |     |
//      |                    | Subview 1 |     |
//      |                    |           |     |
//      | frame.origin       '-----------'     |
//      |      .---------------.    frame.size |
//      |      |               |               |
//      |      |   Subview 2   |               |
//      |      |               |               |
//      |      '---------------'               |
//      |                 frame.size           |
//      |                                      |
//      |                           bounds.size|
//      '--------------------------------------'
//                                        frame.size
// Subviews live in the bounds of the superview. In 99% of all cases the
// bounds are just like the frame, but the origin set to 0.0,0.0.
// As bounds.size is then equal to frame.size there is no scaling involved.
//
// Managing the bounds of a UIView for drawing purposes is the wrong idea,
// use the bounds of the CALayer for that. In fact the bounds of a UIView IMO
// should only be changed, if you are
// scrolling subviews within it (bounds.origin) but then you are better off
// with a UIScrollView.
//
// Changing the bounds.size is usually bad as this changes the size of the UI
// elements. (Which _could_ be good if you are implementing some
// sort of support for poor-sighted individuals... maybe)
//
// All layers (and subviews) live in the bounds of the view. The view
// inherits the transformation and adds its own frame/bounds transformation
// to it.
//
// the main layer is responsible for the "background" and the "border"
//
// Other layers are composited on top of it
// Then the subviews are drawn/composited on those.
//
struct MulleClickDragDifferentiator
{
   CARelativeTime   _mouseMotionSuppressionDelay;  // config value

   CAAbsoluteTime   _suppressUntilTimestamp;
};

//
// This is restricted to h/v resizing to indicate flexibility
// The UIViewAutoresizingStop preempts recursive autoresize by
// the layouter.
//
enum UIViewAutoresizing
{
   UIViewAutoresizingNone           = 0x00,
   UIViewAutoresizingFlexibleWidth  = 0x10,
   UIViewAutoresizingFlexibleHeight = 0x20,
   UIViewAutoresizingFlexible       = 0x30,
   UIViewAutoresizingStickToTop     = 0x100,
   UIViewAutoresizingStickToBottom  = 0x200,
   UIViewAutoresizingStickToMiddle  = 0x300,   // v center
   UIViewAutoresizingStickToLeft    = 0x400,
   UIViewAutoresizingStickToRight   = 0x800,
   UIViewAutoresizingStickToCenter  = 0xC00,   // h center

   // some special bits
   UIViewAutoresizingClipToBounds   = 0x1000,    // size to fit into bounds if smaller
   UIViewAutoresizingCullAtBounds   = 0x2000,    // set to size 0.0 if exceeds bounds
};

typedef NSUInteger   UIViewAutoresizing;


//
// There is only a fixed set of properties a UIView can animate. For all
// other animation purposes use CALayer. (Many properties that appeast as if
// they are animtable on UIView, are really forward to the mainLayer.
//
#define UI_VIEW_ANIMATABLE_PROPERTIES             \
   @property( observable) UIEdgeInsets   padding; \
   @property( observable) UIEdgeInsets   margins; \
   @property( observable) CGRect         frame;   \
   @property( observable) CGRect         bounds;  \
   @property( observable) CGFloat        alpha



@protocol UIAnimatableViewProperties

UI_VIEW_ANIMATABLE_PROPERTIES;

@end


@interface UIView : NSObject <UIAnimatableViewProperties, CAAnimationStorageObject>
{
   UIView                                *_superview;
   CALayer                               *_mainLayer;

   struct mulle_pointerarray             *_layers;     // todo why no inline ?
   struct mulle_pointerarray             *_subviews;

   struct UITrackingAreaArray            _trackingAreas;

   CGLayer                               *_cacheLayer;

   struct MulleClickDragDifferentiator   _clickOrDrag;

   NSObject <UIAnimatableViewProperties> *_snapshot;
   struct CAAnimationStorage             _animationStorage;
}

@property( getter=isHidden)                 BOOL   hidden;                  // default: NO
@property( getter=isUserInteractionEnabled) BOOL   userInteractionEnabled;  // default: YES

@property BOOL   clipsToBounds;   // default: YES
@property BOOL   needsLayout;     // use setNeedsLayout for marking
@property BOOL   needsCaching;

// user info, for finding views (subviewWithTag:)
@property NSInteger   tag;

// On UIView this does nothing
//@property BOOL   needsDisplay;  // used by UIWindow only currently


//
// This is used during layout of subviews to restrict the size of the bounds,
// where subviews can be placed. Use -layoutRect in layout code, which takes
// padding into account
//
@property( observable) UIEdgeInsets   padding;

//
// Margins are used during subview layout. Its the distance of the view to
// otherviews. What is conventionally though of as "padding" is really just a
//
@property( observable) UIEdgeInsets   margins;
// this gets inherited down to all layers and subviews

// frame is the position and size relative to the superview
@property( observable) CGRect         frame;

//
// bounds is the used to place the layers and subviews in, their frames
// are relative to the bounds. If there is a size difference between bounds
// and frame then there will be scaling. Usually the bounds.origin is 0,0
// and the bounds.size is tied to the frame.size.
// Changing a UIView bounds origin can be useful for scrolling views. But
// changing the bounds.size is very rarely useful (as UI elements will become
// too small or too large to click). For zoomed drawing use the bounds of the
// layer.
// If the bounds are not set manually, the bounds.size tracks the frame.size.
//
// Use layoutRect if you are asking for bounds during layout
//
@property( observable) CGRect         bounds;

@property( observable) CGFloat        alpha;
//
// tyically, contentRect is { CGPointZero, bounds.size }. It's the playground
// for the subviews to be placed in (via subview frame). Padding is added by
// layoutRect
//
- (CGRect) contentRect;

// layoutRect take the contentRect and subtract the padding. Only used
// by UIView during layout
- (CGRect) layoutRect;

@property( assign) UIViewAutoresizing   autoresizingMask;
//
// When autoresizing is used the original frame is stored here on the first
// layout and then used as the frame to layout in subsequent layout steps
// this protects us from accumulated fp errors
//
@property( assign) CGRect   originalFrame;

// abused by UIStackView, will be moved away later
@property( assign) CGSize   mulleLayoutSize;

// return NO, if default layoutSubviews code should not run
@property BOOL  (*willLayoutSubviews)( UIView *view);

// called after layoutSubviews default code, not if willLayoutSubviews returns NO
@property void  (*didLayoutSubviews)( UIView *view);

// return NO, if default layoutLayers code should not run
@property BOOL  (*willLayoutLayers)( UIView *view);

// called after layoutLayers default code, not if willLayoutLayers returns NO
@property void  (*didLayoutLayers)( UIView *view);


- (void) setNeedsCaching;  // wipes the _cacheLayer and asks for a new one to be drawn

+ (Class) layerClass;

+ (instancetype) viewWithFrame:(CGRect) frame;
+ (instancetype) viewWithLayer:(CALayer *) layer;

//
// designated initializer, override this for defaults
//
- (instancetype) initWithLayer:(CALayer *) layer
                         frame:(CGRect) frame;

- (instancetype) initWithLayer:(CALayer *) layer;
- (instancetype) initWithFrame:(CGRect) frame;

- (void) mulleAddRetainedLayer:(CALayer *) layer;
- (void) mulleAddRetainedSubview:(UIView *) layer;

- (void) addLayer:(CALayer *) layer;
- (void) addSubview:(UIView *) layer;
- (void) setSubviews:(struct mulle_pointerarray *) array;

// this is the "main" layer. Each view has a bottom most layer that is
// supposed to fill out the UIView with background color and border. It
//
- (CALayer *) layer;

- (void) getSubviewsIntersectingRect:(CGRect) rect
                    intoPointerArray:(struct mulle_pointerarray *) views
              invertIntersectionTest:(BOOL) flag;

// called for each view, before layouting starts
// if a subclass overrides, it should call super
- (void) willRenderWithAbsoluteTime:(CAAbsoluteTime) renderTime;


- (NSInteger) getLayers:(CALayer **) buf
                  range:(NSRange) range;
- (NSInteger) getSubviews:(UIView **) buf
                    range:(NSRange) range;

// this isn't deep
- (UIView *) subviewWithTag:(NSInteger) tag;

// this is deep,
- (UIView *) findSubviewWithTag:(NSInteger) tag;

- (UIWindow *) window;
- (UIView *) UIWindowPlane; // window plane a view resides in
- (UIView *) superview;

- (CGFloat) pixelsPerInchOfPrimaryMonitor;

// UNUSED so far
- (CGRect) clipRect;

// - (CALayer *) mainLayer;  // mainlayer is an internal thing

// view must be part of window view hierarchy, for these function to work
// properly
- (struct UITrackingArea *) addTrackingAreaWithRect:(CGRect) rect
                                              toWindow:(UIWindow *) window
                                              userInfo:(id) userInfo;
- (void) removeTrackingArea:(struct UITrackingArea *) trackingRect;
- (NSUInteger) numberOfTrackingAreas;
- (struct UITrackingArea *) trackingAreaAtIndex:(NSUInteger) i;

- (BOOL) mulleIsEffectivelyHidden;  // recursive test the hierarchy up

- (struct CAAnimationStorage *) animationStorage;

@end


//
// these all get fowarded to the "main" layer
//
@interface UIView( CALayerForwarding)

/*
- (void) setBackgroundColor:(CGColor) color;
- (void) setBorderColor:(CGColor) color;
- (void) setBorderWidth:(CGFloat) value;
- (void) setCornerRadius:(CGFloat) color;
- (CGColor) backgroundColor;
- (CGColor) borderColor;
- (CGFloat) borderWidth;
- (CGFloat) cornerRadius;
*/
- (char *) debugNameUTF8String;
- (void) setDebugNameUTF8String:(char *) s;


@property void                      (*drawCallback)( CALayer *layer, CGContext *ctxt);
@property( observable) CGFloat      cornerRadius;
@property( observable) CGFloat      borderWidth;
@property( observable) CGFloat      opacity;
@property( observable) CGColor   borderColor;
@property( observable) CGColor   backgroundColor;
@property( observable) CGPoint      pixelCenter;
@property( observable) BOOL         masksToBounds;

@end


// didn't want those exposed I guess.
@interface UIView( Internals)

- (struct mulle_pointerarray *) _layers;
- (struct mulle_pointerarray *) _subviews;

@end
