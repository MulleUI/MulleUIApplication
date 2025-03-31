#import "UIWindowTypes.h"

#import "import-private.h"

#import "import-project.h"


NS_OPTIONS_TABLE( UIWindowStyle, 20) =
{
   NS_OPTIONS_ITEM( UIWindowStyleNop),

   NS_OPTIONS_ITEM( UIWindowStyleResizable),
   NS_OPTIONS_ITEM( UIWindowStyleInvisible),
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

   NS_OPTIONS_ITEM( UIWindowOpenGLDeprecated)
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


PROTOCOLCLASS_IMPLEMENTATION( MulleUINamedObject)

- (char *) threadSafeUTF8String
{
   char   *s;
   char   *name;

   mulle_buffer_do_autoreleased_string( buffer, NULL, s)
   {
      s = MulleObjCClassGetNameUTF8String( NSClassFromObject( self));
      mulle_buffer_sprintf( buffer, "<%s %p", s, self);
      name = [self nameUTF8String];
         mulle_buffer_sprintf( buffer, " \"%s\"", name);
      mulle_buffer_add_string( buffer, ">");
   }
   return( s);
}

PROTOCOLCLASS_END()

