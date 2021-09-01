#import "import-private.h"

#import "CGContext.h"
#import "UIApplication.h"
#import "UIWindow.h"
#import "UIView.h"
#import "UIView+Layout.h"
#import "CALayer.h"
#import <string.h>
#import "UIEdgeInsets.h"

struct
{
   uint32_t     color;
   NSUInteger   mask;
} subviewInfo[ 12] =
{
   { 0x2020207F, UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight },
   { 0x4040407F, UIViewAutoresizingFlexibleWidth },
   { 0x4040407F, UIViewAutoresizingFlexibleHeight },

   // TL, TC, TR (blueish)
   { 0x20FFFFF, UIViewAutoresizingStickToTop|UIViewAutoresizingStickToLeft },
   { 0xA0FFFFF, UIViewAutoresizingStickToTop|UIViewAutoresizingStickToCenter },
   { 0x60FFFFF, UIViewAutoresizingStickToTop|UIViewAutoresizingStickToRight },

   // ML, MC, MR (magenta)
   { 0xFF20FFFF, UIViewAutoresizingStickToMiddle|UIViewAutoresizingStickToLeft },
   { 0xFF80FFFF, UIViewAutoresizingStickToMiddle|UIViewAutoresizingStickToCenter },
   { 0xFF40FFFF, UIViewAutoresizingStickToMiddle|UIViewAutoresizingStickToRight },

   // BL, BC, BR (yellow)
   { 0xFFFF20FF, UIViewAutoresizingStickToBottom|UIViewAutoresizingStickToLeft },
   { 0xFFFF80FF, UIViewAutoresizingStickToBottom|UIViewAutoresizingStickToCenter },
   { 0xFFFF40FF, UIViewAutoresizingStickToBottom|UIViewAutoresizingStickToRight }
};


void   setupScene( UIWindowPlane *contentPlane)
{
   UIView         *view;
   UIView         *subview;
   CGRect         frame;
   CGRect         bounds;
   UIEdgeInsets   insets;
   CALayer        *layer;
   NSUInteger     i;
   char           buf[ 64];

   frame  = [contentPlane contentRect];
   insets = UIEdgeInsetsMake( 8, 8, 8, 8);
   frame  = UIEdgeInsetsInsetRect( frame, insets);

   view  = [UIView viewWithFrame:frame];
   [view setDebugNameCString:"parent"];
   [view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
   [view setBackgroundColor:CGColorMakeRGBA( 0.0, 1.0, 0.0, 1.0)];
   [view setPadding:UIEdgeInsetsMake( 4.0, 4.0, 4.0, 4.0)];

   [contentPlane addSubview:view];

   for( i = 0; i < 12; i++)
   {
      frame   = CGRectMake( 20, 20, 20, 20);
      subview = [UIView viewWithFrame:frame];

      sprintf( buf, "child #%ld", (long) i);
      [subview setDebugNameCString:buf];
      [subview setBackgroundColor:MulleColorMake( subviewInfo[ i].color)];
      [subview setAutoresizingMask:subviewInfo[ i].mask];
      [view addSubview:subview];
      [view setNeedsLayout];
   }
}


int   main()
{
   CGContext       *context;
   UIWindow        *window;
   UIApplication   *application;

   application = [UIApplication sharedInstance];
   /*
    * window and app
    */
   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800, 600)];
   [window setBackgroundColor:CGColorMakeRGBA( 1.0, 1.0, 1.0, 1.0)];

   setupScene( [window contentPlane]);

   [window dump];

   [application addWindow:window];
   [window renderLoop];
   [application terminate];

   return( 0);
}
