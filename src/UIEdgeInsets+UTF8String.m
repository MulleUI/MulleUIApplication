#include "UIEdgeInsets+UTF8String.h"


// same as MulleEdgeInsetsUTF8String, but we don't have MulleGraphics here
char   *UIEdgeInsetsUTF8String( UIEdgeInsets insets)
{
   auto char  *s;

   s = MulleObjC_asprintf( "%.2f %.2f %.2f %.2f",
         insets.top,
         insets.left,
         insets.bottom,
         insets.right);
   return( s);
}

