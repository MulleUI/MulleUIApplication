#import <MulleUICore/MulleUICore.h>

#import <string.h>


@interface CircleLayer : CALayer

@property( observable) CGFloat     scale;
@property( observable) CGColor  color;
@property( observable) CGRect      box;

@end


@implementation CircleLayer

- (instancetype) initWithFrame:(CGRect) frame
{
   [super initWithFrame:frame];

   _scale = 1;
   _color = CGColorMakeWithUnsignedInteger( 0x000000FF);
   _box   = [self canvas];

   return( self);
}

@end


static void   drawStuff( CALayer *aLayer, CGContext *context)
{
   CircleLayer         *layer = (CircleLayer *) aLayer;
   CGFloat             radius;
   CGRect              box;
   CGRect              canvas;
   struct NVGcontext   *vg;

   canvas = [layer canvas];
   vg     = CGContextGetNVGContext( context);

   nvgBeginPath( vg);
   {
      radius  = CGFloatMinimum( CGRectGetWidth( canvas), CGRectGetHeight( canvas)) / 2 - 10;
      radius *= [layer scale];

      nvgCircle( vg, CGRectGetMidX( canvas), CGRectGetMidY( canvas), radius);
      nvgStrokeColor( vg, [layer color]);
      nvgStrokeWidth( vg, 3.5);
   }
   nvgStroke( vg);

   nvgBeginPath( vg);
   {
      box = [layer box];
      nvgRect( vg, CGRectGetMinX( box), CGRectGetMinY( box), CGRectGetWidth( box), CGRectGetHeight( box));
      nvgStrokeColor( vg, [layer color]);
      nvgStrokeWidth( vg, 3.5);
   }
   nvgStroke( vg);
}


void  setupAnimation( UIWindow *window, CircleLayer *layer)
{
   CAAnimationGroup   *group;

   // UIView -> CAAnimation
   [UIView beginAnimations:"animation"
                    context:NULL];
   {
      [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
      [UIView setAnimationDelay:2];
      [UIView setAnimationDuration:2];
      [UIView setAnimationRepeatCount:20];

      [layer setScale:-1.0];
      [layer setColor:CGColorMakeWithUnsignedInteger( 0x0000FFFF)];
      [layer setBox:CGRectMake( 100, 100, 100, 100)];
   }
   group = [UIView commitAnimations];

   [[window postLayoutAnimator] addAnimation:group];
}


void   setupSceneAndAnimation( UIWindow *window)
{
   UIView         *view;
   CGRect         frame;
   UIEdgeInsets   insets;
   CircleLayer    *layer;

   frame  = [[window contentPlane] contentRect];
   insets = UIEdgeInsetsMake( 8, 8, 8, 8);
   frame  = UIEdgeInsetsInsetRect( frame, insets);

   layer = [CircleLayer layerWithFrame:frame];
   [layer setColor:CGColorMakeWithUnsignedInteger( 0xFF0000FF)];
   [layer setDrawCallback:drawStuff];

   view  = [UIView viewWithLayer:layer];
   [[window contentPlane] addSubview:view];

   // UIView -> CAAnimation
   setupAnimation( window, layer);
}


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;
   /*
    * window and app
    */
   app    = [UIApplication sharedInstance];
   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800.0, 600.0)];
   assert( window);

   [window setBackgroundColor:CGColorMakeRGBA( 1.0, 1.0, 1.0, 1.0)];

   setupSceneAndAnimation( window);

   [window dump];

   [app addWindow:window];
   [window renderLoop];

   return( [app terminate]);
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

