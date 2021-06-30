//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
// prefer a local UIWindow over one in import.h
#ifdef __has_include
# if __has_include( "UIWindow.h")
#  import "UIWindow.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"


@interface UIWindow( CAAnimation)

- (void) addAnimationGroup:(CAAnimationGroup *) animation;
- (void) removeAnimationGroup:(CAAnimationGroup *) animation;
- (void) removeAllAnimationGroups;
- (void) animateWithAbsoluteTime:(CAAbsoluteTime) renderTime;

@end
