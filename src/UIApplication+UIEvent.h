//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
// prefer a local UIApplication over one in import.h

// we want "import.h" always anyway
#import "UIApplication.h"
#import "UIEvent.h"


@interface UIApplication( UIEvent) <UIEventReceiver>

- (UIWindowEvent *) handleScreenEvent:(UIScreenEvent *) event   MULLE_UI_MAIN_THREAD_ONLY;
- (UIWindowEvent *) handleGamepadEvent:(UIGamepadEvent *) event MULLE_UI_MAIN_THREAD_ONLY;

@end


