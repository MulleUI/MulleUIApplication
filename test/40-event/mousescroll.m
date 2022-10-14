#import <MulleUIApplication/MulleUIApplication.h>


int   main( void)
{
   UIMouseScrollEvent   *event;
   struct UIInputState   inputState;

   inputState = UIInputStateMake( CGPointMake( 2, 3), 7, 4);
   event = [[[UIMouseScrollEvent alloc] initWithInputState:&inputState
                                               scrollOffset:CGPointMake( 5, 6)] autorelease];
   printf( "type             : %td\n", [event eventType]);
   printf( "locationInWindow : %s\n",  CGPointUTF8String( [event locationInWindow]));
   printf( "modifiers        : %td\n", [event keyModifiers]);
   printf( "scrollOffset     : %s\n",  CGPointUTF8String( [event scrollOffset]));

   return( 0);
}