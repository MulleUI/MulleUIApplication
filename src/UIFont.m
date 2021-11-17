#define _GNU_SOURCE // for strrchr
#import "UIFont.h"


@implementation UIFont


+ (instancetype) fontWithNameUTF8String:(char *) name
{
   return( [self fontWithNameUTF8String:name
                                size:12.0]);
}


+ (instancetype) fontWithNameUTF8String:(char *) name
                                size:(CGFloat) pointSize
{
   UIFont   *font;

   font = [[[self alloc] init] autorelease];
   [font setFontName:name];
   [font setPointSize:pointSize];
   return( font);
}


+ (instancetype) boldSystemFontOfSize:(CGFloat) pointSize
{
   return( [self fontWithNameUTF8String:"sans"
                                size:pointSize]);
}


- (void) dealloc
{
   struct mulle_allocator  *allocator;

   allocator = MulleObjCInstanceGetAllocator( self);
   mulle_allocator_free( allocator, _fontName);
   [super dealloc];
}


- (void) setFontName:(char *) s
{
   MulleObjCObjectSetDuplicatedUTF8String( self, &_fontName, s);
}

@end
