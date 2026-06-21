#import "import.h"

#import "UIWindowTypes.h"

#include <stdio.h>

typedef NS_ENUM( NSUInteger, UIEventPlayerStopAction)
{
   UIEventPlayerTerminatesOnRequestOnly = 0,
   UIEventPlayerTerminates,
   UIEventPlayerIgnoresTerminationScriptEvent,
};


@interface UIEventPlayer : NSObject <UITimerReceiver>
{
   struct mulle_structarray   _events;
   NSUInteger                 _nextIndex;
   mulle_absolutetime_t       _startTime;
   NSTimer                   *_timer;
   BOOL                       _stopOnInvalidWindowIndex;
   NSUInteger                 _currentWindowIndex;   // default window for events without N:

   mulle_absolutetime_t       _lastMouseButtonPressTime;
   NSUInteger                 _mouseButtonClickCount;
   CGPoint                    _lastMouseButtonPressLocation;
}

@property( assign) NSUInteger   debuggingFlags     MULLE_OBJC_THREADSAFE_PROPERTY;

@property( assign) UIEventPlayerStopAction   stopAction;

// Load script from string or file
- (BOOL) loadScriptWithUTF8String:(char *) scriptText;
- (BOOL) loadScriptWithContentsOfFile:(char *) path;
- (BOOL) loadScriptWithFILE:(FILE *) fp;

// Start playback (call after loading script)
- (void) startPlayback;
- (void) stopPlayback;

// Set to NO to skip events with invalid window index instead of aborting (default: YES)
- (void) setAbortOnInvalidWindowIndex:(BOOL) flag;
- (BOOL) abortOnInvalidWindowIndex;

// UITimerReceiver
- (void) timerFired:(NSTimer *) timer;

@end
