#define _GNU_SOURCE

#import <MulleUIApplication/MulleUIApplication.h>

#include <time.h>


@implementation UIApplication ( Hacky)

//
// Check it out: we are returning an autoreleased char pointer here,
// pass it through to another thread and print it there... And there are
// no leaks or crashes
//
- (char *) callMeWithInteger:(NSInteger) value
              textUTF8String:(char *) s   MULLE_UI_MAIN_THREAD_ONLY
{
   char   *result;

   assert( [NSThread mulleIsMainThread]);

   result = MulleObjC_asprintf( "%s %td", s, value);
   if( value == 1848)
      [[NSThread mainThread] cancel];

   // do an inconvenient sleep to slow consumer down a bit
   mulle_relativetime_sleep( (rand() % 100000) / 1000000.0);

   return( result);
}


- (void) _callSynchronousTest:(NSUInteger) value   MULLE_OBJC_THREADSAFE_METHOD
{
   NSMethodSignature   *signature;
   NSInvocation        *invocation;
   auto char           auto_s[] = { 'V', 'f', 'L', ' ', 'B', 'o', 'c', 'h', 'u', 'm', 0 };
   char                *s = auto_s;
   char                *rval;

   @autoreleasepool
   {
      signature  = [self methodSignatureForSelector:@selector( callMeWithInteger:textUTF8String:)];
      invocation = [NSInvocation invocationWithMethodSignature:signature];

      [invocation setTarget:self];
      // method signature could preset this really or ?
      [invocation setSelector:@selector( callMeWithInteger:textUTF8String:)];
      [invocation setArgument:&value
                      atIndex:2];
      [invocation setArgument:&s  // notice how the text is on the stack
                      atIndex:3];

      [self invokeOnMainThread:invocation
                 waitUntilDone:YES];
      memset( auto_s, 0xAA, sizeof( auto_s)); // clobber
      [invocation getReturnValue:&rval];
      printf( "%s\n", (char *) rval);
   }
   // notice how the autoreleased invocations lifetime is done now
}

- (void) synchronousTest:(id) unused   MULLE_OBJC_THREADSAFE_METHOD
{
   NSUInteger   i;

   for( i = 1; i <= 1848; i++)
      [self _callSynchronousTest:i];
   mulle_fprintf( stderr, "thread dies\n");
}

@end



int   main( int argc, char *argv[])
{
   UIApplication   *app;

   app = [UIApplication sharedInstance];

   @autoreleasepool
   {
      [NSThread detachNewThreadSelector:@selector( synchronousTest:)
                              toTarget:app
                            withObject:nil];

      while( ! [[NSThread currentThread] isCancelled])
      {
         @autoreleasepool
         {
            [app runInvocations]; // busy runner but shucks
         }
      }
   }

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

