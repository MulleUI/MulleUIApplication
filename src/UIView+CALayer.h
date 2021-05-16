//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
// prefer a local UIView over one in import.h
#ifdef __has_include
# if __has_include( "UIView.h")
#  import "UIView.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"



@interface UIView( CALayer)

- (CGPoint) convertPoint:(CGPoint) pos toLayer:(CALayer*) toView;
//- (CGPoint) convertPoint:(CGPoint) pos fromLayer:(CALayer*) fromView;


// will return sublayer if any hit, or returns mainLayer by default
// even if point does not hit
- (CALayer *) layerHitTest:(CGPoint) point;

@end
