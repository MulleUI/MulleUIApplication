#import "UIView.h"

#import "UIView+CAAnimation.h"
#import "UIWindow.h"
#import "UIWindow+UIEvent.h"
#import "mulle-pointerarray+ObjC.h"


#import "import-private.h"

//#define RENDER_DEBUG
//#define RENDER_VERBOSE_DEBUG
//#define HAVE_RENDER_CACHE

@implementation UIView

+ (Class) layerClass
{
   return( [CALayer class]);
}


+ (instancetype) viewWithFrame:(CGRect) frame
{
   return( [[[self alloc] initWithFrame:frame] autorelease]);
}


+ (instancetype) viewWithLayer:(CALayer *) layer
{
   return( [[[self alloc] initWithLayer:layer] autorelease]);
}


// designated initializer
- (instancetype) initWithLayer:(CALayer *) layer
                         frame:(CGRect) frame
{
   CGRect     frame;

   assert( ! layer || [layer isKindOfClass:[CALayer class]]);

   if( ! layer)
   {
      [self release];
      return( nil);
   }

   _mainLayer              = [layer retain];
   _clipsToBounds          = YES;  // default
   _userInteractionEnabled = YES;  // default
   _alpha                  = 1.0;
   _bounds.size.width      = INFINITY; // once we change the bounds size
                                       // we disconnect from frame.size
   _frame                  = frame;

//   _needsDisplay           = YES;

   return( self);
}


- (instancetype) initWithFrame:(CGRect) frame
{
   CALayer   *layer;
   Class     cls;
   CGRect    rect;

   rect  = CGRectMake( 0.0f, 0.0f, frame.size.width, frame.size.height);
   cls   = [[self class] layerClass];
   layer = [[[cls alloc] initWithFrame:rect] autorelease];
   self  = [self initWithLayer:layer
                         frame:frame];
   return( self);
}

//
// What's the expectation here with regard to frame ?
// Assume layer is already relative to UIView ?
// I don't think so... Assume its in screen/windows space
//
- (instancetype) initWithLayer:(CALayer *) layer
{
   CGRect   frame;

   frame = [layer frame];
   [layer setFrame:CGRectMake( 0.0f, 0.0f, frame.size.width, frame.size.height)];

   return( [self initWithLayer:layer
                         frame:frame]);
}


- (void) dealloc
{
   UITrackingAreaArrayDone( &_trackingAreas);

   mulle_pointerarray_release_all( _subviews);
   mulle_pointerarray_destroy( _subviews);

   mulle_pointerarray_release_all( _layers);
   mulle_pointerarray_destroy( _layers);

   [_cacheLayer release];
   [_mainLayer release];

   [super dealloc];
}


- (struct CAAnimationStorage *) animationStorage
{
   return( &_animationStorage);
}


- (CALayer *) layer
{
   return( _mainLayer);
}


static inline CGRect   getBounds( UIView *self)
{
   CGRect  bounds;

   bounds.origin = self->_bounds.origin;
   bounds.size   = self->_bounds.size.width == INFINITY
                     ? self->_frame.size
                     : self->_bounds.size;
   return( bounds);
}


//
// for layers bounds are inherited directly, so the layer "sticks"
// (and need to be panned by its bounds)
//
- (CGRect) bounds
{
   return( getBounds( self));
}


- (void) setBounds:(CGRect) bounds
{
   [self willChange];

   _bounds.origin = bounds.origin;
   if( CGSizeEqualToSize( _frame.size, bounds.size))
      _bounds.size.width = INFINITY;
   else
      _bounds.size = bounds.size;
}


- (CGRect) contentRect
{
   CGRect  rect;

   rect.origin = CGPointMake( 0.0f, 0.0f);
   rect.size   = getBounds( self).size;
   return( rect);
}


- (CGRect) layoutRect
{
   CGRect   bounds;

   bounds = [self contentRect];
   bounds = UIEdgeInsetsInsetRect( bounds, _padding);
   return( bounds);
}

//
//
//
- (void) mulleAddRetainedLayer:(CALayer *) layer
{
   assert( layer);
   assert( [layer isKindOfClass:[CALayer class]]);

   if( ! _mainLayer)
   {
      _mainLayer = layer;
      return;
   }
   assert(_mainLayer != layer);

   if( ! _layers)
      _layers = mulle_pointerarray_create( NULL);

   assert( _mulle_pointerarray_find( _layers, layer) == mulle_not_found_e);
   _mulle_pointerarray_add( _layers, layer);
}


- (void) addLayer:(CALayer *) layer
{
   [self mulleAddRetainedLayer:[layer retain]];
}


- (struct mulle_pointerarray *) _layers
{
   struct mulle_allocator   *allocator;

   if( ! _layers)
   {
      allocator = MulleObjCInstanceGetAllocator( self);
      _layers = mulle_pointerarray_alloc( allocator);
      _mulle_pointerarray_init( _layers, 4, allocator);
   }
   return( _layers);
}


- (struct mulle_pointerarray *) _subviews
{
   struct mulle_allocator   *allocator;

   if( ! _subviews)
   {
      allocator = MulleObjCInstanceGetAllocator( self);
      _subviews = mulle_pointerarray_alloc( allocator);
      _mulle_pointerarray_init( _subviews, 4, allocator);
   }
   return( _subviews);
}


- (void) mulleAddRetainedSubview:(UIView *) view
{
   struct mulle_pointerarray  *subviews;
   uintptr_t                  index;

   assert( view);
   assert( view != self);
   assert( ! [view superview]);
   assert( [view isKindOfClass:[UIView class]]);

   subviews = [self _subviews];
   index    = _mulle_pointerarray_find( subviews, view);
//   fprintf( stderr, "index of existing view: %llx\n", (long long) index);

   assert( _mulle_pointerarray_find( subviews, view) == mulle_not_found_e);
   _mulle_pointerarray_add( subviews, view);

   view->_superview = self;
}


- (void) addSubview:(UIView *) view
{
   [self mulleAddRetainedSubview:[view retain]];
}


- (NSUInteger) subviewCount
{
   return( _subviews ? mulle_pointerarray_get_count( _subviews) : 0);
}


- (NSInteger) getLayers:(CALayer **) buf
                  range:(NSRange) range
{
   NSUInteger   n;

   if( ! buf)
      return( -1);

   if( ! _mainLayer)
      return( 0);

   n  = 1;
   n += mulle_pointerarray_get_count( _layers);

   if( range.location + range.length > n)
      return( -1);

   mulle_pointerarray_copy_range( _layers, buf, range);

   buf[ n - 1] = _mainLayer; // why last ?

   return( n);
}


- (NSInteger) getSubviews:(UIView **) buf
                    range:(NSRange) range
{
   NSUInteger   n;

   if( ! buf)
      return( -1);

   n = mulle_pointerarray_get_count( _subviews);
   if( range.location + range.length > n)
      return( -1);

   mulle_pointerarray_copy_range( _subviews, buf, range);

   return( n);
}

//
// TODO: use some other data structure, not pointerarray ?
//
- (void) setSubviews:(struct mulle_pointerarray *) array
{
   struct mulle_allocator   *allocator;

   if( array == self->_subviews)
      return;

   if( ! array)
   {
      mulle_pointerarray_release_all( _subviews);
      mulle_pointerarray_destroy( _subviews);
      _subviews = NULL;
      return;
   }

   allocator = MulleObjCInstanceGetAllocator( self);
   assert( _mulle_pointerarray_get_allocator( array) == allocator);

   /* retain/release */
   mulle_pointerarray_retain_all( array);

   if( ! _subviews)
      _subviews = mulle_pointerarray_alloc( allocator);
   else
   {
      mulle_pointerarray_release_all( _subviews);
      _mulle_pointerarray_done( _subviews);   // but don't free
   }

   // transfer objects
   memcpy( _subviews, array, sizeof( struct mulle_pointerarray));
   // make sure these aren't reused by array anymore
   _mulle_pointerarray_init( array, 0, allocator);
}


- (void) addSubviewsIntersectingRect:(CGRect) rect
                      toPointerArray:(struct mulle_pointerarray *) array
              invertIntersectionTest:(BOOL) flag
{
   struct mulle_pointerarrayenumerator   rover;
   UIView                                *view;

   flag = ! flag;
   rover = mulle_pointerarray_enumerate( _subviews);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &view))
      if( CGRectIntersectsRect( [view frame], rect) == flag)
         mulle_pointerarray_add( array, view);
   mulle_pointerarrayenumerator_done( &rover);
}


- (UIView *) subviewWithTag:(NSInteger) tag
{
   struct mulle_pointerarrayenumerator   rover;
   UIView                                *view;

   rover = mulle_pointerarray_enumerate( _subviews);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &view))
      if( [view tag] == tag)
         break;
   mulle_pointerarrayenumerator_done( &rover);

   return( view);
}


- (CALayer *) mainLayer
{
   assert( _mainLayer);
   return( _mainLayer);
}


- (BOOL) isMultiLayer
{
   return( _layers != NULL);
}


- (CGRect) clipRect
{
   return( [_mainLayer clipRect]);
}


//- (void) setNeedsDisplay
//{
//   _needsDisplay = YES;
//}


- (void *) forward:(void *) param
{
   assert( _mainLayer); // window should not forward...
   return( mulle_objc_object_call_variablemethodid_inline( _mainLayer,
                                                          (mulle_objc_methodid_t) _cmd,
                                                          param));
}


- (BOOL) respondsToSelector:(SEL) sel
{
   if( [super respondsToSelector:sel])
      return( YES);
   return( [_mainLayer respondsToSelector:sel]);
}


- (CGFloat) pixelsPerInchOfPrimaryMonitor
{
   CGFloat     ppi;
   UIWindow   *window;

   window = [self window];
   if( window)
      ppi = [window primaryMonitorPPI];
   else
      ppi = [UIWindow primaryMonitorPPI];
   if( ! ppi)
      ppi = 100.0f;
   return( ppi);
}


//// conveniences
//- (void) setBackgroundColor:(CGColorRef) color
//{
//   [_mainLayer setBackgroundColor:color];
//}
//
//- (void) setBorderColor:(CGColorRef) color
//{
//   return( [_mainLayer setBorderColor:color]);
//}
//
//- (void) setBorderWidth:(CGFloat) value
//{
//   [_mainLayer setBorderWidth:value];
//}
//
//- (void) setCornerRadius:(CGFloat) value
//{
//   return( [_mainLayer setCornerRadius:value]);
//}
//
//
//- (CGColorRef) backgroundColor
//{
//   return( [_mainLayer backgroundColor]);
//}
//
//- (CGColorRef) borderColor
//{
//   return( [_mainLayer borderColor]);
//}
//
//- (CGFloat) borderWidth
//{
//   return( [_mainLayer borderWidth]);
//}
//
//- (CGFloat) cornerRadius
//{
//   return( [_mainLayer cornerRadius]);
//}
//

// Done by Yoga
// - (void) setNeedsLayout
// {
//    _needsLayout = YES;
// }

// maybe wrong name ?
- (void) setNeedsCaching  // wipes the _backinglayer and asks for a new one to be drawn
{
#ifdef HAVE_RENDER_CACHE
   // might have to do this atomically later on
   _needsCaching = YES;
   [_cacheLayer autorelease];
   _cacheLayer = nil;
#endif
}


- (char *) cStringDescription
{
   char        *result;
   char        *s;
   auto char   buf[ 64];
   size_t      len;
   char        *format;
   char        *name;

   s = MulleObjCClassGetNameCString( NSClassFromObject( self));
   sprintf( buf, "%p",  self);

   format = "<%s %s>";
   name   = [_mainLayer debugNameCString];
   len    = name ? strlen( name) : 0;
   if( len)
   {
      format = "<%s %s \"%s\">";
      len   += 3; // < "">\0"
   }
   len    += strlen( s) + strlen( buf) + 4; // < "">\0"
   result  = mulle_malloc( len);
   sprintf( result, format, s, buf, name);
   MulleObjCAutoreleaseAllocation( result, NULL);

   return( result);
}

#if 0
- (CGLayer *) cachedLayerWithFrameInfo:(struct CGFrameInfo *) info
{
   if( _needsCaching)
   {
#ifdef HAVE_RENDER_CACHE
      CGLayer   *layer;

      assert( _cacheLayer == nil);
      _needsCaching = NO;
      layer = [self textureImageWithContext:[[self window] context]
                                 frameInfo:info
                                    options:0];
      if( layer)
         _cacheLayer = [[CABitmapLayer alloc] initWithImage:image];
#endif
   }
   return( _cacheLayer);
}
#endif


- (void) willRenderWithAbsoluteTime:(CAAbsoluteTime) time
{
}


- (UIView *) superview
{
   return( _superview);
}


- (UIWindow *) window
{
   UIView   *view;
   UIView   *parent;

   view = self;
   while( (parent = [view superview]))
      view = parent;

   if( [view isKindOfClass:[UIWindow class]])
   {
      //fprintf( stderr, "window found\n");
      return( (UIWindow *) view);
   }
   return( nil);
}

//
// look for the plance, the view is part of (if any)
// a plane will say nil
//
- (UIView *) mulleWindowPlane
{
   UIView   *view;
   UIView   *plane;
   UIView   *parent;

   plane = nil;
   view  = self;
   while( (parent = [view superview]))
   {
      plane = view;
      view  = parent;
   }

   if( [view isKindOfClass:[UIWindow class]])
   {
      //fprintf( stderr, "window found\n");
      return( plane);
   }
   return( nil);
}



# pragma mark - tracking rectangles

- (struct UITrackingArea *) addTrackingAreaWithRect:(CGRect) rect
                                              toWindow:(UIWindow *) window
                                              userInfo:(id) userInfo
{
   struct UITrackingArea   *tracking;
   UIWindow                  *window;

   if( ! window)
      window = [self window];

   assert( window);

   if( UITrackingAreaArrayGetCount( &_trackingAreas) == 0)
   {
      // if window does not exist, then a late add would not be noticed
      // and tracking fails...
      [window addTrackingView:self];
   }

   tracking = UITrackingAreaArrayNewItem( &_trackingAreas);
   UITrackingAreaInit( tracking, rect, userInfo);
   return( tracking);
}

- (void) removeTrackingArea:(struct UITrackingArea *) item
{
   UIWindow   *window;

   UITrackingAreaArrayRemoveItem( &_trackingAreas, item);
   if( UITrackingAreaArrayGetCount( &_trackingAreas) == 0)
   {
      window = [self window];
      assert( window);
      [window removeTrackingView:self];
   }
}

- (NSUInteger) numberOfTrackingAreas
{
   return( UITrackingAreaArrayGetCount( &_trackingAreas));
}


- (struct UITrackingArea *) trackingAreaAtIndex:(NSUInteger) i
{
   struct UITrackingArea   *item;

   item = UITrackingAreaArrayGetItemAtIndex( &_trackingAreas, i);
   return( item);
}


- (BOOL) mulleIsEffectivelyHidden  // recursive test the hierarchy up
{
   UIView   *p;

   p = self;
   for(;;)
   {
      if( p->_hidden)
         return( YES);
      p = p->_superview;
      if( ! p)
         return( NO);
   }
}

@end
