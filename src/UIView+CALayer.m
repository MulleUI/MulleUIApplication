//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "UIView+CALayer.h"

#import "import-private.h"

#import "UIView+CGGeometry.h"


@implementation CALayer ( UIView)

- (void) updateTransform:(float *) transform
{
   CGRect          frame;
   CGRect          bounds;
   CGPoint         scale;
   _NVGtransform   tmp;

   frame  = [self frame];
   bounds = [self bounds];

   nvgTransformTranslate( tmp, bounds.origin.x, bounds.origin.y);
   nvgTransformPremultiply( transform, tmp);

   scale.x = bounds.size.width / frame.size.width;
   scale.y = bounds.size.height / frame.size.height;

   nvgTransformScale( tmp, scale.x, scale.y);
   nvgTransformPremultiply( transform, tmp);

   nvgTransformTranslate( tmp, -frame.origin.x, -frame.origin.y);
   nvgTransformPremultiply( transform, tmp);
}

- (void) updateReverseTransform:(float *) transform
{
   CGRect          frame;
   CGRect          bounds;
   CGPoint         scale;
   _NVGtransform   tmp;

   frame  = [self frame];
   bounds = [self bounds];

   nvgTransformTranslate( tmp, frame.origin.x, frame.origin.y);
   nvgTransformMultiply( transform, tmp);

   scale.x = frame.size.width / bounds.size.width;
   scale.y = frame.size.height / bounds.size.height;

   nvgTransformScale( tmp, scale.x, scale.y);
   nvgTransformMultiply( transform, tmp);

   nvgTransformTranslate( tmp, bounds.origin.x, bounds.origin.y);
   nvgTransformMultiply( transform, tmp);
}

@end


@implementation UIView( CALayer)

- (CALayer *) layerHitTest:(CGPoint) point
{
   struct mulle_pointerarrayenumerator   rover;
   CALayer                               *layer;
   CGRect                                rect;
   CGPoint                               converted;

   rover = mulle_pointerarray_enumerate( _layers);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &layer))
   {
      rect = [layer frame];
      if( CGRectContainsPoint( rect, point))
         break;
   }
   mulle_pointerarrayenumerator_done( &rover);

   return( layer ? layer : _mainLayer);
}


//
// We want to translate a point that is in the bounds of the UIView
// to the canvas of the layer.
// The bounds of the UIView are the bounds of the mainLayer. So is there
// anything to do ?
//
// For other layers we translate the point into their canvas.
//
- (CGPoint) convertPoint:(CGPoint) point
                 toLayer:(CALayer *) layer
{
   CGPoint             translated;
   _NVGtransform       transform;
   CGRect              frame;
   CGRect              bounds;
   CGPoint             converted;
   CGAffineTransform   xform;

   if( ! layer)
      return( point);

   xform = MulleAffineTransformMakeInverseProjection( [layer frame],
                                                      [layer bounds]);
//   nvgTransformIdentity( transform);
//   [layer updateTransform:transform];

   translated = CGPointApplyAffineTransform( point, xform);
   return( translated);
}


//- (CGPoint) convertPoint:(CGPoint) point
//               fromLayer:(CALayer *) layer
//{
//   CGPoint         translated;
//   _NVGtransform   transform;
//
//   if( ! layer || layer == _mainLayer)
//      return( point);
//
//
//   nvgTransformIdentity( transform);
//   [layer updateReverseTransform:transform];
//   nvgTransformPoint( &translated.x, &translated.y, transform, point.x, point.y);
//   return( translated);
//}

@end
