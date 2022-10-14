#import <MulleUIApplication/MulleUIApplication.h>


int   main( void)
{
   UIWindowMoveEvent   *event;

   event = [[[UIWindowMoveEvent alloc] initWithOrigin:MulleIntegerPointMake( 5, 6)] autorelease];

   printf( "type   : %td\n", [event eventType]);
   printf( "origin : %s\n",  MulleIntegerPointUTF8String( [event origin]));

   return( 0);
}