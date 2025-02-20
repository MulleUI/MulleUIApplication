#import <MulleUIApplication/MulleUIApplication.h>


int   main( void)
{
   UIKeyboardEvent   *event;
   struct UIInputState   inputState;

   inputState = UIInputStateMake( CGPointMake( 2, 3), 8, 4);
   event = [[[UIKeyboardEvent alloc] initWithInputState:&inputState
                                                    key:5
                                               scanCode:6
                                                 action:7
                                              isARepeat:YES] autorelease];
   mulle_printf( "type             : %td\n", [event eventType]);
   mulle_printf( "locationInWindow : %s\n",  CGPointUTF8String( [event locationInWindow]));
   mulle_printf( "keyModifiers     : %td\n", [event keyModifiers]);
   mulle_printf( "key              : %td\n", [event key]);
   mulle_printf( "scanCode         : %td\n", [event scanCode]);
   mulle_printf( "action           : %td\n", [event action]);
   mulle_printf( "isARepeat        : %btd\n",[event isARepeat]);

   return( 0);
}