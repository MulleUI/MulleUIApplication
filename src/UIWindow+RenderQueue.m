//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "UIWindow+RenderQueue.h"

#import "UIView+CGGeometry.h"
#import "UIView+Layout.h"

#import "import-private.h"


@implementation UIView ( RenderQueue)

//
// the transform is the concatenation of the superviews transforms
// the clipRect is in window space (window bounds)
//
- (void) createRenderQueue:(struct mulle_pointerarray *) renderQueue
                 transform:(CGAffineTransform) inheritedXform
                  clipRect:(CGRect) clipRect
                     alpha:(CGFloat) inheritedAlpha
{
   struct mulle_pointerarrayenumerator   rover;
   UIView                                *view;
   CALayer                               *layer;
   CGAffineTransform                     xform;
   CGAffineTransform                     inverseXform;
   CGAffineTransform                     projection;
   CGFloat                               alpha;
   CGRect                                transformedClipRect;
   CGRect                                subClipRect;
   CGRect                                transformedRect;
   CGRect                                frame;
   CGRect                                screenRect;

   if( [self isCulledByLayout])
      return;

   alpha = _alpha * inheritedAlpha;
   if( MulleAlphaIsTransparent( alpha))
      return;

   projection = CGAffineTransformMakeProjection( _frame, [self bounds]);
   xform      = CGAffineTransformConcat( inheritedXform, projection);

   subClipRect = clipRect;
   if( _clipsToBounds)
   {
      // actually clips to frame... sorta...
      transformedRect = CGRectApplyAffineTransform( [self frame], inheritedXform);
      subClipRect     = CGRectIntersection( clipRect, transformedRect);
   }

   //
   // if we clip to nothing we don't do anything
   // we use 0.1 for FP errors. An invalid intersetion also produces
   // inf origins, which apparently is bad later on. This should implicitly
   // catch this too
   if( subClipRect.size.width < 0.1 || subClipRect.size.height < 0.1)
      return;

#ifdef HAVE_RENDER_CACHE
   if( _cacheLayer)
   {
      [_cacheLayer setTransform:xform];
      [_cacheLayer setAlpha:alpha];
      [_cacheLayer setClipRect:subClipRect];
      mulle_pointerarray_add( renderQueue, _cacheLayer);
   }
   else
#endif
   {
      /*
      * Layers
      */
      [_mainLayer setTransform:xform];
      [_mainLayer setAlpha:alpha];
      [_mainLayer setClipRect:subClipRect];
      mulle_pointerarray_add( renderQueue, _mainLayer);

      rover = mulle_pointerarray_enumerate( _layers);
      while( _mulle_pointerarrayenumerator_next( &rover, (void **) &layer))
      {
         [layer setTransform:xform];
         [layer setAlpha:alpha];
         [layer setClipRect:subClipRect];
         mulle_pointerarray_add( renderQueue, layer);
      }
      mulle_pointerarrayenumerator_done( &rover);
   }
   /*
    * Subviews
    */
   rover = mulle_pointerarray_enumerate( _subviews);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &view))
   {
      // we cull clipped views completely here
      screenRect = CGRectApplyAffineTransform( [view frame], xform);
      if( CGRectIntersectsRect( subClipRect, screenRect))
         [view createRenderQueue:renderQueue
                       transform:xform
                        clipRect:subClipRect
                           alpha:alpha];
   }
   mulle_pointerarrayenumerator_done( &rover);
}

@end


@implementation UIWindow( RenderQueue)

- (void) setClipsToBounds:(BOOL) flag
{
   assert( ! flag);
}


- (void) createRenderQueue:(struct mulle_pointerarray *) renderQueue
{
   struct mulle_pointerarrayenumerator   rover;
   UIView                                *view;

   rover = mulle_pointerarray_enumerate( _subviews);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &view))
   {
      [view createRenderQueue:renderQueue
                    transform:CGAffineTransformMakeIdentity()
                     clipRect:CGRectMake( -INFINITY, -INFINITY, INFINITY, INFINITY)
                        alpha:1.0];
   }
   mulle_pointerarrayenumerator_done( &rover);
}


- (void) dumpRenderQueue:(struct mulle_pointerarray *) renderQueue
{
   struct mulle_pointerarrayenumerator   rover;
   CALayer                               *layer;

   rover = mulle_pointerarray_enumerate( renderQueue);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &layer))
   {
      [layer dumpWithIndent:1];
   }
   mulle_pointerarrayenumerator_done( &rover);
}

@end
