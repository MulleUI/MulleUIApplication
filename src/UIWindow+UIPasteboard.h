//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
// prefer a local UIWindow over one in import.h
#import "UIWindow.h"

// we want "import.h" always anyway
#import "import.h"


@class UIPasteboard;


@interface UIWindow( UIPasteboard)

- (UIPasteboard *) pasteboard;

@end


@interface UIWindow( OSPasteboard)

- (char *) pasteboardCString;
- (void) setPasteboardCString:(char *) s;

@end
