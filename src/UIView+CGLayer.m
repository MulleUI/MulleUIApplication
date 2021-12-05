//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "UIView+CGLayer.h"

#import "UIView+Render.h"

#import "import-private.h"



@implementation UIView ( CGLayer)

//
// This must not be called, if context is currently rendering (at least for
// now) as we are starting an offline render.
//
- (CGLayer *) textureImageWithContext:(CGContext *) context
                            frameInfo:(struct CGFrameInfo *) info
                              options:(NSUInteger) options
{
   struct CGFrameInfo     renderInfo;
   CGLayer                   *layer;
   CGRect                    frame;
   struct CGBitmapInfo     bitmapInfo;
   NVGcontext                *vg;

   frame = [self frame];

   memset( &renderInfo, 0, sizeof( renderInfo));

   renderInfo.size                      = frame.size;
   renderInfo.framebufferSize.width     = renderInfo.size.width / info->pixelRatio;
   renderInfo.framebufferSize.height    = renderInfo.size.height / info->pixelRatio;
   renderInfo.viewportFrame.size        = renderInfo.framebufferSize;
   renderInfo.UIScale                   = info->UIScale;
   renderInfo.pixelRatio                = info->pixelRatio;

   layer = [CGLayer layerWithBitmapSize:renderInfo.framebufferSize
                             imageFlags:(int) options
                                context:context];
   if( ! layer)
      return( layer);

   [layer beginRender:&renderInfo];
   @autoreleasepool
   {
      vg = CGContextGetNVGContext( context);
      // translate to 0.0 ? scale to fit ?
      if( options & NVG_IMAGE_FLIPY)
      {
         nvgScale( vg, 1.0, -1.0);
         nvgTranslate( vg, -frame.origin.x, -frame.origin.y - frame.size.height);
      }
      else
         nvgTranslate( vg, -frame.origin.x, -frame.origin.y);

      // haben wir nach Window verschoben, war wohl dumm...
      [self renderInContext:context];
#if 0
      nvgBeginPath( vg);
      nvgRoundedRect( vg, frame.origin.x,
                          frame.origin.y,
                          frame.size.width,
                          frame.size.height,
                          10);
      nvgFillColor(vg, nvgRGBA(220,160,0,255));
      nvgFill( vg);

      nvgCreateFont( vg, "foo", "Anonymous Pro.ttf");
      nvgFontFace( vg, "foo");
      nvgFontSize( vg, 64);
      nvgTextColor( vg, nvgRGBA(0,0,0,255), nvgRGBA(220,160,0,255)); // TODO: use textColor
      nvgText( vg, frame.origin.x + frame.size.width / 2.0,
                   frame.origin.y + frame.size.height / 2.0,
                   "XXXX", NULL);
#endif
   }
   [layer endRender];

   return( layer);
}

@end
