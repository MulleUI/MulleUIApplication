#import "UIWindowTypes.h"

#import "import-private.h"

MULLE_UI_APPLICATION_GLOBAL_VAR
NS_OPTIONS_TABLE( UIWindowStyle, 24) =
{
   NS_OPTIONS_ITEM( UIWindowStyleNop),

   NS_OPTIONS_ITEM( UIWindowStyleResizable),
   NS_OPTIONS_ITEM( UIWindowStyleHidden),
   NS_OPTIONS_ITEM( UIWindowStyleOffscreen),
   NS_OPTIONS_ITEM( UIWindowStyleSingleBuffer),
   NS_OPTIONS_ITEM( UIWindowStyleTransparent),
   NS_OPTIONS_ITEM( UIWindowStyleFloating),
   NS_OPTIONS_ITEM( UIWindowStyleBare),
   NS_OPTIONS_ITEM( UIWindowStylePlanes),
   NS_OPTIONS_ITEM( UIWindowStyleNoView),

   NS_OPTIONS_ITEM( UIWindowStyleAntiAlias),
   NS_OPTIONS_ITEM( UIWindowStyleForceEdgeAntiAlias),
   NS_OPTIONS_ITEM( UIWindowStyleStencilStrokes),
   NS_OPTIONS_ITEM( UIWindowStyleClearType),
   NS_OPTIONS_ITEM( UIWindowStyleRetained),
   NS_OPTIONS_ITEM( UIWindowStyleRetainedOnMainThread),

   NS_OPTIONS_ITEM( UIWindowOpenGLCoreProfile),
   NS_OPTIONS_ITEM( UIWindowOpenGLForward),
   NS_OPTIONS_ITEM( UIWindowOpenGLLibraryFallback),

   NS_OPTIONS_ITEM( UIWindowOpenGLDeprecated),

   NS_OPTIONS_ITEM( UIWindowStyleNoDelayedShow)
};


char  *UIWindowFrameRateUTF8String( double frameRate)
{
   if( frameRate == UIWindowFrameRateUnsynced)
      return( "UIWindowFrameRateUnsynced");
   if( frameRate == UIWindowFrameRateAsync)
      return( "UIWindowFrameRateAsync");
   if( frameRate == UIWindowFrameRateSynced)
      return( "UIWindowFrameRateSynced");
   return( MulleObjC_asprintf( "%.4gHz", 1.0 / frameRate));
}


char  *UIWindowDisplayBitsUTF8String( NSUInteger bits)
{
   NSUInteger   bit;
   char         *hein;
   char         *text;
   auto char    *s;

   if( ! bits)
      return( "None");

   mulle_buffer_do_autoreleased_string( buffer, NULL, s)
   {
      bit  = 0x1;
      hein = "";

      while( bits)
      {
         if( bits & bit)
         {
            text = UIWindowDisplayBitUTF8String( bit);
            if( ! text)
               hein = " ???";
            else
            {
               mulle_buffer_add_char( buffer, ' ');
               mulle_buffer_add_string( buffer, text);
            }
         }
         bits &= ~bit;
         bit <<= 1;
      }
      mulle_buffer_add_string( buffer, hein);
   }

   return( s);
}
