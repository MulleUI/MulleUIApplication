#import "UIColor.h"


@implementation UIColor

+ (instancetype) alloc
{
   assert( 0 && "don't create UIColor instances");
   return( nil);
}


- (instancetype) init
{
   assert( 0 && "don't create UIColor instances");
   [self release];
   return( nil);
}



+ (CGColor) blackColor     { return( CGColorMakeWithUnsignedInteger( 0x000000FF)); }

+ (CGColor) whiteColor     { return( CGColorMakeWithUnsignedInteger( 0xFFFFFFFF)); }
+ (CGColor) redColor       { return( CGColorMakeWithUnsignedInteger( 0xFF0000FF)); }
+ (CGColor) greenColor     { return( CGColorMakeWithUnsignedInteger( 0x00FF00FF)); }
+ (CGColor) blueColor      { return( CGColorMakeWithUnsignedInteger( 0x0000FFFF)); }
+ (CGColor) grayColor      { return( CGColorMakeWithUnsignedInteger( 0x7F7F7FFF)); }
+ (CGColor) darkGrayColor  { return( CGColorMakeWithUnsignedInteger( 0x3F3F3FFF)); }
+ (CGColor) lightGrayColor { return( CGColorMakeWithUnsignedInteger( 0xBFBFBFFF)); }
+ (CGColor) yellowColor    { return( CGColorMakeWithUnsignedInteger( 0xFFFF00FF)); }

+ (CGColor) magentaColor   { return( CGColorMakeWithUnsignedInteger( 0xFF00FFFF)); }
+ (CGColor) brownColor     { return( CGColorMakeWithUnsignedInteger( 0x8F5F2FFF)); }
+ (CGColor) cyanColor      { return( CGColorMakeWithUnsignedInteger( 0x00FFFFFF)); }
+ (CGColor) orangeColor    { return( CGColorMakeWithUnsignedInteger( 0xFF7F00FF)); }
+ (CGColor) purpleColor    { return( CGColorMakeWithUnsignedInteger( 0x7F007FFF)); }

// maus grau :) -> Loriot Eheberatung
+ (CGColor) underPageBackgroundColor  { return( CGColorMakeWithUnsignedInteger( 0x6b716fFF)); }
+ (CGColor ) colorWithCGColor:(CGColor) cgColor  { return( cgColor); }

@end