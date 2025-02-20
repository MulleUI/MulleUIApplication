#import <MulleUIApplication/MulleUIApplication.h>


int   main( void)
{
   UIWindowMoveEvent   *event;

   event = [[[UIWindowMoveEvent alloc] initWithOrigin:CGPixelPointMake( 5, 6)] autorelease];

   printf( "type   : %td\n", [event eventType]);
   printf( "origin : %s\n",  CGPixelPointUTF8String( [event origin]));

   return( 0);
}