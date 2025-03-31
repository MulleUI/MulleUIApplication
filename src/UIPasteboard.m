//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "UIPasteboard.h"

#import "import-private.h"


@implementation UIPasteboard

+ (instancetype) pasteboardWithWindow:(id <UIWindow>) window
{
   UIPasteboard   *pasteboard;

   pasteboard = [UIPasteboard object];
   [pasteboard setWindow:window];
   return( pasteboard);
}


- (char *) textUTF8String
{
   return( (char *) [_window pasteboardCString]);
}


- (void) setTextUTF8String:(char *) s
{
   [_window setPasteboardCString:s];
}

@end
