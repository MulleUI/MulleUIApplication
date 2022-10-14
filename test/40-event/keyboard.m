#import <MulleUIApplication/MulleUIApplication.h>


int   main( void)
{
   UIKeyboardEvent   *event;
   struct UIInputState   inputState;

   inputState = UIInputStateMake( CGPointMake( 2, 3), 8, 4);
   event = [[[UIKeyboardEvent alloc] initWithInputState:&inputState
                                                    key:5
                                               scanCode:6
                                                 action:7] autorelease];
   printf( "type             : %td\n", [event eventType]);
   printf( "locationInWindow : %s\n",  CGPointUTF8String( [event locationInWindow]));
   printf( "keyModifiers     : %td\n", [event keyModifiers]);
   printf( "key              : %td\n", [event key]);
   printf( "scanCode         : %td\n", [event scanCode]);
   printf( "action           : %td\n", [event action]);

   return( 0);
}