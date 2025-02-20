#import <MulleUIApplication/MulleUIApplication.h>


int   main( void)
{
   UIWindowResizeEvent   *event;

   event = [[[UIWindowResizeEvent alloc] initWithSize:CGPixelSizeMake( 5, 6)] autorelease];

   printf( "type : %td\n", [event eventType]);
   printf( "size : %s\n",  CGPixelSizeUTF8String( [event size]));

   return( 0);
}