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


@interface UIView( CGLayer)

- (CGLayer *) textureImageWithContext:(CGContext *) context
                            frameInfo:(struct MulleFrameInfo *) info
                              options:(NSUInteger) options;

@end
