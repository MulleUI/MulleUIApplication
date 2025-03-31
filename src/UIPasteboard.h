//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "import.h"

#import "UIWindowTypes.h"


//
// This is stuck via glfw to the current window. So really the
// window owns a single UIPasteboard instance. Having the pasteboard
// as its own object makes little technical sense. It's just here for
// familiarity and disoverabilty.
//
@interface UIPasteboard : NSObject

@property( retain) id <UIWindow>   window;

+ (instancetype) pasteboardWithWindow:(id <UIWindow>) window;

- (char *) textUTF8String;
- (void) setTextUTF8String:(char *) s;

@end
