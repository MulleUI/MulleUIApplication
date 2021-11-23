// prefer a local UIEvent over one in import.h
#ifdef __has_include
# if __has_include( "UIEvent.h")
#  import "UIEvent.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"

@class UIView;

@interface UIEvent( UIView)

//
// translated mouseLocation to current view bounds (ephemeral)
// set by _handleEvent:position for
//
- (CGPoint) mouseLocationInView:(UIView *) view;

- (void) _setTranslatedPoint:(CGPoint) point
                     forView:(UIView *) view;
- (CGPoint) _translatedPointForView:(UIView *) view;

@end


