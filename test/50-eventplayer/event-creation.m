#include <stdio.h>

#import <MulleUIApplication/MulleUIApplication.h>


int   main( void)
{
   UIEventPlayer   *player;
   BOOL             result;
   
   player = [UIEventPlayer instance];
   
   mulle_printf( "=== UIEventPlayer Event Creation Test ===\n\n");
   
   // Test: Create events from script and verify they're created
   mulle_printf( "Loading script with various events...\n");
   result = [player loadScriptWithUTF8String:
      "0.0 mouseMove x=50 y=75\n"
      "0.1 mouseDown button=Left x=50 y=75\n"
      "0.2 mouseUp button=Left x=50 y=75\n"
      "0.5 keyDown key=A mods=Shift\n"
      "0.6 keyUp key=A mods=Shift\n"
      "1.0 terminate\n"];
   
   if( ! result)
   {
      mulle_printf( "FAILED: Could not load script\n");
      return( 1);
   }
   
   mulle_printf( "SUCCESS: Script loaded\n\n");
   
   mulle_printf( "Note: To actually dispatch events, we need:\n");
   mulle_printf( "  - A window to receive events (UIPureWindow or UIWindow)\n");
   mulle_printf( "  - UIApplication running the event loop\n");
   mulle_printf( "  - Window's event callback mechanism\n\n");
   
   mulle_printf( "Next steps:\n");
   mulle_printf( "  1. Study UIPureWindow event dispatch in MulleUIPureWindow\n");
   mulle_printf( "  2. Create offscreen window for testing (UIWindowStyleOffscreen)\n");
   mulle_printf( "  3. Hook up UIEventPlayer to dispatch events to window\n");
   mulle_printf( "  4. Verify events are received by window/responders\n\n");
   

   return( 0);
}
