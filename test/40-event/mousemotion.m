#import <MulleUIApplication/MulleUIApplication.h>


int   main( void)
{
   UIMouseMotionEvent   *event;
   struct UIInputState   inputState;

   inputState = UIInputStateMake( CGPointMake( 2, 3), 7, 4);
   event = [[[UIMouseMotionEvent alloc] initWithInputState:&inputState] autorelease];

   printf( "type             : %td\n", [event eventType]);
   printf( "locationInWindow : %s\n",  CGPointUTF8String( [event locationInWindow]));
   printf( "modifiers        : %td\n", [event keyModifiers]);
   printf( "buttonStates     : %td\n", [event buttonStates]);

   return( 0);
}