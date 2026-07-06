#import <MulleUIApplication/MulleUIApplication.h>


int   main( void)
{
   UIMouseButtonEvent   *event;
   struct UIInputState   inputState;

   inputState = UIInputStateMake( CGPointMake( 2, 3), 7, 4);
   event = [[[UIMouseButtonEvent alloc] initWithInputState:&inputState
                                                    button:5
                                                    action:6
                                                clickCount:1] autorelease];
   printf( "type             : %td\n", [event eventType]);
   printf( "locationInWindow : %s\n",  CGPointUTF8String( [event locationInWindow]));
   printf( "modifiers        : %td\n", [event keyModifiers]);
   printf( "buttonStates     : %td\n", [event buttonStates]);
   printf( "button           : %td\n", [event button]);
   printf( "action           : %td\n", [event action]);

   return( 0);
}