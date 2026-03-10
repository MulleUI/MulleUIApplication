#include <stdio.h>

#import <MulleUIApplication/MulleUIApplication.h>


int   main( void)
{
   UIEventPlayer   *player;
   BOOL             result;
   char            *scriptPath;
   
   player = [UIEventPlayer instance];
   
   // Test 1: Parse from string with various event types
   mulle_printf( "Test 1: Parse comprehensive string\n");
   result = [player loadScriptFromUTF8String:
      "# Test script\n"
      "0.0 mouseMove x=50 y=75\n"
      "0.5 mouseDown button=Left x=50 y=75\n"
      "0.6 mouseUp button=Left x=50 y=75\n"
      "1.0 mouseDown button=Right x=100 y=100\n"
      "1.1 mouseUp button=Right x=100 y=100\n"
      "2.0 keyDown key=A mods=Shift\n"
      "2.1 keyUp key=A mods=Shift\n"
      "2.5 keyDown key=C mods=Control\n"
      "2.6 keyUp key=C mods=Control\n"
      "3.0 keyDown key=Space\n"
      "3.1 keyUp key=Space\n"
      "3.5 keyDown key=F1\n"
      "3.6 keyUp key=F1\n"
      "4.0 keyDown key=Left\n"
      "4.1 keyUp key=Left\n"
      "4.5 keyDown key=S mods=Control|Shift\n"
      "4.6 keyUp key=S mods=Control|Shift\n"
      "5.0 terminate\n"];
   
   if( result)
      mulle_printf( "  Parse from string: SUCCESS\n");
   else
      mulle_printf( "  Parse from string: FAILED\n");
   
   // Test 2: Parse from comprehensive file
   mulle_printf( "\nTest 2: Parse comprehensive file\n");
   scriptPath = "test-script.txt";
   result = [player loadScriptFromFile:scriptPath];
   
   if( result)
      mulle_printf( "  Parse from file: SUCCESS\n");
   else
      mulle_printf( "  Parse from file: FAILED\n");
   
   // Test 3: Abort flag accessors
   mulle_printf( "\nTest 3: Abort flag\n");
   [player setAbortOnInvalidWindowIndex:NO];
   if( [player abortOnInvalidWindowIndex] == NO)
      mulle_printf( "  Abort flag set to NO: SUCCESS\n");
   else
      mulle_printf( "  Abort flag set to NO: FAILED\n");
   
   [player setAbortOnInvalidWindowIndex:YES];
   if( [player abortOnInvalidWindowIndex] == YES)
      mulle_printf( "  Abort flag set to YES: SUCCESS\n");
   else
      mulle_printf( "  Abort flag set to YES: FAILED\n");
   
   // Test 4: Test comment and blank line handling
   mulle_printf( "\nTest 4: Comment and blank line handling\n");
   result = [player loadScriptFromUTF8String:
      "# This is a comment\n"
      "\n"
      "   # Indented comment\n"
      "\n"
      "0.0 mouseMove x=10 y=20\n"
      "   \n"
      "# Another comment\n"
      "1.0 terminate\n"];
   
   if( result)
      mulle_printf( "  Comment handling: SUCCESS\n");
   else
      mulle_printf( "  Comment handling: FAILED\n");
   
   // Test 5: Test all mouse buttons
   mulle_printf( "\nTest 5: All mouse buttons\n");
   result = [player loadScriptFromUTF8String:
      "0.0 mouseDown button=Left x=1 y=1\n"
      "0.1 mouseUp button=Left x=1 y=1\n"
      "0.2 mouseDown button=Right x=2 y=2\n"
      "0.3 mouseUp button=Right x=2 y=2\n"
      "0.4 mouseDown button=Middle x=3 y=3\n"
      "0.5 mouseUp button=Middle x=3 y=3\n"
      "1.0 terminate\n"];
   
   if( result)
      mulle_printf( "  All mouse buttons: SUCCESS\n");
   else
      mulle_printf( "  All mouse buttons: FAILED\n");
   
   // Test 6: Test modifier combinations
   mulle_printf( "\nTest 6: Modifier combinations\n");
   result = [player loadScriptFromUTF8String:
      "0.0 keyDown key=A mods=Shift\n"
      "0.1 keyDown key=B mods=Control\n"
      "0.2 keyDown key=C mods=Alt\n"
      "0.3 keyDown key=D mods=Super\n"
      "0.4 keyDown key=E mods=Control|Shift\n"
      "0.5 keyDown key=F mods=Control|Alt\n"
      "0.6 keyDown key=G mods=Control|Shift|Alt\n"
      "1.0 terminate\n"];
   
   if( result)
      mulle_printf( "  Modifier combinations: SUCCESS\n");
   else
      mulle_printf( "  Modifier combinations: FAILED\n");
   
   // Test 7: Test special keys
   mulle_printf( "\nTest 7: Special keys\n");
   result = [player loadScriptFromUTF8String:
      "0.0 keyDown key=Space\n"
      "0.1 keyDown key=Enter\n"
      "0.2 keyDown key=Tab\n"
      "0.3 keyDown key=Escape\n"
      "0.4 keyDown key=Backspace\n"
      "0.5 keyDown key=Delete\n"
      "0.6 keyDown key=Home\n"
      "0.7 keyDown key=End\n"
      "0.8 keyDown key=PageUp\n"
      "0.9 keyDown key=PageDown\n"
      "1.0 keyDown key=Insert\n"
      "1.1 keyDown key=Left\n"
      "1.2 keyDown key=Right\n"
      "1.3 keyDown key=Up\n"
      "1.4 keyDown key=Down\n"
      "2.0 terminate\n"];
   
   if( result)
      mulle_printf( "  Special keys: SUCCESS\n");
   else
      mulle_printf( "  Special keys: FAILED\n");
   
   // Test 8: Test function keys
   mulle_printf( "\nTest 8: Function keys\n");
   result = [player loadScriptFromUTF8String:
      "0.0 keyDown key=F1\n"
      "0.1 keyDown key=F2\n"
      "0.2 keyDown key=F5\n"
      "0.3 keyDown key=F10\n"
      "0.4 keyDown key=F12\n"
      "1.0 terminate\n"];
   
   if( result)
      mulle_printf( "  Function keys: SUCCESS\n");
   else
      mulle_printf( "  Function keys: FAILED\n");
   
   // Test 9: Test window indexing
   mulle_printf( "\nTest 9: Window indexing\n");
   result = [player loadScriptFromUTF8String:
      "0.0 mouseMove x=10 y=10\n"
      "1: 0.1 mouseMove x=20 y=20\n"
      "2: 0.2 mouseMove x=30 y=30\n"
      "0: 0.3 mouseMove x=40 y=40\n"
      "1.0 terminate\n"];
   
   if( result)
      mulle_printf( "  Window indexing: SUCCESS\n");
   else
      mulle_printf( "  Window indexing: FAILED\n");
   
   mulle_printf( "\n=== All tests completed ===\n");

   return( 0);
}
