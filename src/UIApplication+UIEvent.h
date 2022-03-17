//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
// prefer a local UIApplication over one in import.h

// we want "import.h" always anyway
#import "UIApplication.h"
#import "UIEvent.h"


@interface UIApplication( UIEvent) <UIEventReceiver>
@end
