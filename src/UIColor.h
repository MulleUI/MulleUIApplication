#import "import.h"

//
// UIColor is merely a factory for CGColor which is really the
// nanovg color struct
//
// I think colors wrapped into objects is too heavyweight
// In case of need, one should use NSValue for that.

@interface UIColor : NSObject

+ (CGColor) blackColor;
+ (CGColor) whiteColor;
+ (CGColor) redColor;
+ (CGColor) blueColor;
+ (CGColor) greenColor;
+ (CGColor) grayColor;
+ (CGColor) yellowColor;
+ (CGColor) darkGrayColor;
+ (CGColor) lightGrayColor;

+ (CGColor) magentaColor;
+ (CGColor) brownColor;
+ (CGColor) cyanColor;
+ (CGColor) orangeColor;
+ (CGColor) purpleColor;

+ (CGColor) underPageBackgroundColor;
+ (CGColor) colorWithCGColor:(CGColor) cgColor;


@end

