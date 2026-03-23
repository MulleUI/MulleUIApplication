#import "import.h"
#ifndef M_PI
# define M_PI 3.14159265358979323846
#endif

static void   drawColorwheel(CGContext *context, float x, float y, float w, float h, NSUInteger frameNumber)
{
   int i;
   float r0, r1, ax,ay, bx,by, cx,cy, aeps, r;
   float fummel = fmod( frameNumber / 100.0, M_PI * 2.0) == 0.0 ? 1.0 : fmod( frameNumber / 100.0, M_PI * 2.0);
   float hue = sinf( fummel * 0.12);
   float rot;

   // stolen from a demo and stupidified

   // RING
   CGContextSave( context);
   {
      cx = x + w*0.5f;
      cy = y + h*0.5f;
      r1 = (w < h ? w : h) * 0.5f - 5.0f;
      r0 = r1 - 20.0f;
      aeps = 0.5f / r1; // half a pixel arc length in radians (2pi cancels out).

      CGContextTranslate( context, CGPointMake(cx, cy));
      rot = -fummel;
      CGContextRotate( context, rot);
      CGContextTranslate( context, CGPointMake(-cx, -cy));

      for (i = 0; i < 6; i++) {
         float a0 = (float)i / 6.0f * M_PI * 2.0f - aeps;
         float a1 = (float)(i+1.0f) / 6.0f * M_PI * 2.0f + aeps;
         CGContextBeginPath( context);
         CGContextArc( context, CACircleMakeWithCenterAndRadius( CGPointMake(cx, cy), r0), CARadiansToAngle( a0), a1 - a0);
         CGContextArc( context, CACircleMakeWithCenterAndRadius( CGPointMake(cx, cy), r1), CARadiansToAngle( a1), a0 - a1);
         CGContextClosePath( context);
         ax = cx + cosf(a0) * (r0+r1)*0.5f;
         ay = cy + sinf(a0) * (r0+r1)*0.5f;
         bx = cx + cosf(a1) * (r0+r1)*0.5f;
         by = cy + sinf(a1) * (r0+r1)*0.5f;
         CGContextSetFillLinearGradient( context, CGPointMake(ax, ay), CGPointMake(bx, by), CGColorMakeWithHSLA(a0/(M_PI*2),1.0f,0.55f,1.0f), CGColorMakeWithHSLA(a1/(M_PI*2),1.0f,0.55f,1.0f));
         CGContextFill( context);
      }

      CGContextBeginPath( context);
      CGContextCircle( context, CACircleMakeWithCenterAndRadius( CGPointMake(cx, cy), r0-0.5f));
      CGContextCircle( context, CACircleMakeWithCenterAndRadius( CGPointMake(cx, cy), r1+0.5f));
      CGContextStrokeColor( context, CGColorMakeWithRGBABytes(0,0,0,64));
      CGContextStrokeWidth( context, 1.0f);
      CGContextStroke( context);
   }
   CGContextRestore( context);

   // TRIANGLE
   CGContextSave( context);
   {
      CGContextTranslate( context, CGPointMake(cx, cy));
      rot = fummel;
      CGContextRotate( context, rot);

      r = r0 - 6;
      ax = cosf(120.0f/180.0f*M_PI) * r;
      ay = sinf(120.0f/180.0f*M_PI) * r;
      bx = cosf(-120.0f/180.0f*M_PI) * r;
      by = sinf(-120.0f/180.0f*M_PI) * r;
      CGContextBeginPath( context);
      CGContextMoveTo( context, CGPointMake(r, 0));
      CGContextLineTo( context, CGPointMake(ax, ay));
      CGContextLineTo( context, CGPointMake(bx, by));
      CGContextClosePath( context);
      CGContextSetFillLinearGradient( context, CGPointMake(r, 0), CGPointMake(ax, ay), CGColorMakeWithHSLA(hue,1.0f,0.5f,1.0f), CGColorMakeWithRGBA(1,1,1,1));
      CGContextFill( context);
      CGContextSetFillLinearGradient( context, CGPointMake((r+ax)*0.5f, (0+ay)*0.5f), CGPointMake(bx, by), CGColorMakeWithRGBA(0,0,0,0), CGColorMakeWithRGBA(0,0,0,1));
      CGContextFill( context);
      CGContextStrokeColor( context, CGColorMakeWithRGBABytes(0,0,0,64));
      CGContextStroke( context);
   }
   CGContextRestore( context);
}
static BOOL   drawStuff( CGGraphicsLayer *layer, CGContext *context)
{
   CGFloat       diameter;
   CGRect        canvas;
   CGRect        rect;
   CGPoint       a;
   CGPoint       b;
   NSUInteger    numberOfFrames;

   numberOfFrames = [context numberOfFrames];

   // MulleUICLog( "layer: %#@ context: %#@ numberOfFrames: %tu", layer, context, numberOfFrames);

   canvas         = [layer canvas];
   rect           = UIEdgeInsetsInsetRect( canvas, UIEdgeInsetsMake( 10, 10, 10, 10));
   diameter       = CGFloatMinimum( CGRectGetWidth( rect), CGRectGetHeight( rect));
   rect.origin    = CGSizeGetCenterInRect( CGSizeMake( diameter, diameter), rect);
   rect.size      = CGSizeMake( diameter, diameter);

   drawColorwheel( context,
                   rect.origin.x,
                   rect.origin.y,
                   diameter,
                   diameter,
                   numberOfFrames);
   return( YES);
}
static void   setupSceneInWindow( UIWindow *window)
{
   UIView   *view;
   CGRect   frame;
   UIView   *contentPlane;

   contentPlane = [window contentView];

   frame = [contentPlane contentRect];
   frame = UIEdgeInsetsInsetRect( frame, UIEdgeInsetsMake( 10, 10, 10, 10));

   view  = [UIView viewWithFrame:frame];
   [view setBackgroundColor:CGColorMakeWithRGBA( 0.0, 0.0, 0.0, 1.0)];
   [(CGGraphicsLayer *) [view layer] setDrawCallback:drawStuff];
   [contentPlane addSubview:view];
}

enum
{
   Vsync,
   Softsync
};
#define N_WINDOWS     2
#define DISPLAY_MODE  Vsync
#define HZ            2.0
int   main( int argc, char *argv[])
{
   UIWindow                 *window[ N_WINDOWS];
   UIApplication            *app;
   NSUInteger               i;
   NSUInteger               n_open;
   id <UIGraphicsContext>   context;
   int                      mode = DISPLAY_MODE;
   NSUInteger               styleMask;
   char                     buf[ 32];

   if( argc == 2)
   {
      if( argv[ 1][ 0] == 'v')
         mode = Vsync;
      else
         mode = Softsync;
   }

   //
   // MEMO: The framerate for windows in one-thread scenario with Softsync
   //       is not additive interestingly enough.
   //       With VSync windows speed up as other windows are closed.
   //
   app = [UIApplication sharedInstance];

   @autoreleasepool
   {
      for( i = 0; i < N_WINDOWS; i++)
      {
         styleMask  = UIWindowStyleMaskDefault & ~UIWindowStyleRetained;
         mulle_snprintf( buf, sizeof( buf), "Demo Window #%tu", i);
         window[ i] = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 200.0, 200.0)
                                titleUTF8String:buf
                                      styleMask:styleMask];
         switch( mode)
         {
         case Vsync :
            // Framerate don't really matter, as the swapInterval ties us to
            // Vsync. A lower framerate could slow down, but a higher won't
            // speed up.

            [window[ i] setFrameRate:UIWindowFrameRateUnsynced];
            context = [window[ i] activateWindowGraphicsContext];
            {
               [window[ i] setSwapInterval:1];
            }
            [window[ i] deactivateGraphicsContext:context];
            break;

         case Softsync :
            [window[ i] setFrameRateHz:HZ];
            break;
         }

         [window[ i] setBackgroundColor:CGColorMakeWithRGBA( 1.0 / N_WINDOWS, 
                                                             1.0 - 1.0 / N_WINDOWS,
                                                             0.5  / N_WINDOWS,
                                                             1.0)];
         setupSceneInWindow( window[ i]);
         [app addWindow:window[ i]];
      }
   }

   return( [app runApp]);
}

//
//                           ,╓≤æKª╨╙╙▓█D"╙╙╙*╨¥W▄╓,
//                      ╓▄ª╙└╧▓        █           ⁿ▓▓ª╦w
//                  ╓#╜^*█⌐   `╕       █           ╓▌    `╙%w
//               ╓ΦΓ      █    ╙⌐     ,█,,,Φ      ╓▌         ╙¥▄
//            ,▄▀ █▄       █µ,╓╝,╓≤╗≡≡ª╨╨╨¥≡∞╗w╓,ª█,  ,       ]▄▀V,
//          ,Φ└   ║"▀▄     ,▄▀╨"                 "╙¥▓▓       ▄▀  º▄¥,
//        ,#▌Φ▓▄╓  Φ `█Q▄M╙                           ╙¥▄ ,▄▀ ╙▄⌐`  `Φ
//       ▄▀   `V,"▀▀¼╓╩└                                 ╙¥▓╗ ,       ╙▄
//      Φ       `¥═▄▀                            ╒          ▀▄          ▓
//    .▓         ╓▓]V▄H       ▓                 ,Å            ▀,         ▀
//    █      ,-ª▓╛  `██▀½      "▄  ,╓╓╓╓;╓▄▄▄▄╗▄█,             ╙▄         ▀
//   █  `██▄   ▓. - Φ█═.~     ,≤█▄▀-      `   █└"▀▀▀▀▄╓╓╓╓       ▌    ██▄, █
//  ║⌐  " ▀   ▓╨⌐   }▀`      ,█  `           █      .█▀▄▄███▄     ▌  ` ▀    ▌
//  ▌        ▐M A   '┴      ▌                ▀        ╙█▌████▌    ╙▄        ║⌐
// ║⌐        █⌐'║▄ Γr2«    ║▀                 ▄▄▄      ╙▌▄███      █         ▌
// █]     ,▄▐H  ██████═ª  ╓` ▄█▀▀▀▀█▄        ████     ╓███` `╙╙║█  ▐H        █
// █ "% ,▄▀ ║░╠K█═╣███^   ╛╓█▀      ▐█         ,╓╓═ª╙└   █      ╙█▄▐▌▓######▌╫
// █║▄▄▄█▄▄▄║H:  "╙▀███▄╓▄,█▌╓▄,,▄∩  ██p$ΦΦ▀▀▀▀▀ΦΦΦR≡≥▄╓ ║▄       ╙j▌` ▄▀╙╗ `╫
// █"      ╙▐H-═M ▄███████¥█H "^╙    '█, ,«^``     `     ║▌        ▐M▄▀    "Φ█
// ║        !█▄▄████≤═^`╓█ █▌╓▀╦▄▀█   ╙█⌐               ╓█▌        ▓ `       █
//  ▌      ,▄██╫██ ▄█═╜" █▌▐█╣Hj⌐ █    █▌╙¥w,           ██▄       ╓▌        ▐M
//  ╢"▄▄#▀▀╙╟█Ü███▀`▀█  ║██J█▄▌jH █    ██    ╙▀W▄;    ,██  `╙w,   █▄     ,╓ █
//   █╙     ▐███▌▀█w ▀█ ╠██████j▌║█▌   ▀██▄       `╙▓██▀w,     ╙╗█'`"▀█▀╙"`║`
//   ╙▌     Φ████████▄██ ███████████    ═██▀W▄,   ╓█▀└         ╓▀ "    ╙▄ ╓▀
//    ╙▄     ╙▀███╙█▄▐██▄,╙▀█████▄▀▄▀▄   ,█M╗ ▀▄██▀╙""*ⁿ═─≈-,,▄▌,        ▄▀
//     `▌╙µ,▄Φ▀x███▄██████████▀V███▀╙└ ,▄#▌████▀`"*«,      .█▀▄▀▄,      ▄╛
//       ▀Ö█  ;▓████████▄▄█▀▄╙W "V▄██▀▀│▄███▀└ ▀╦     "*═╥▄▀ ║,  ║▀▄  ,▓
//        ╙W▀ '█████╨▀▀█████████   "▀▀████└      ╙▄   ,▄▀'   `▀▀╣H ▐▀▄▀
//          ╙▄  ▀▀Γ╓▌  ▄▀ⁿ`╙▀███      ██▌         ╓█R▀▄A█        ▀▀▄▀
//            ╙W,Φ╙  ║█        ▄╙╙ª%≡╦██≤≤╗╗≡≡╜▀▀   ╣▌   █╕     ,▄▀
//              `▀▄M█┘        ║▀▌   ╫"    *Φ▄  █       Φ` ▀▌, ▄M╙
//                 "▀╦,       M ╙▌  ▀       `█W▐▌       wæQ▄▀╙
//                     ╙▀W╥,╓╣   ╙█║        ╫M  █    ,╓▄╝╙`
//                          ╙╙▀%▄▄▄▌,≤▄_▄≡,▐▓▓▄▄#ª▀"`

