#import <MulleUIApplication/MulleUIApplication.h>


int   main( void)
{
   UIUnicodeEvent   *event;
   struct UIInputState   inputState;

   inputState = UIInputStateMake( CGPointMake( 2, 3), 7, 4);
   event = [[[UIUnicodeEvent alloc] initWithInputState:&inputState
                                                character:5] autorelease];
   printf( "type             : %td\n", [event eventType]);
   printf( "locationInWindow : %s\n",  CGPointUTF8String( [event locationInWindow]));
   printf( "modifiers        : %td\n", [event keyModifiers]);
   printf( "character        : %td\n", [event character]);

   return( 0);
}