#import <MulleUICore/MulleUICore.h>


int   main( void)
{
   UIApplication   *app;

   app = [UIApplication sharedInstance];
   if( ! app)
   {
      fprintf( stderr, "sharedInstance failed\n");
      exit( 1);
   }
   [app terminate];
   return( 0);
}