#import "import.h"

#import "UIWindowTypes.h"


@interface UIEventPlayer : NSObject <UITimerReceiver>
{
   struct mulle_structarray   _events;
   NSUInteger                 _nextIndex;
   mulle_absolutetime_t       _startTime;
   NSTimer                   *_timer;
   BOOL                       _abortOnInvalidWindowIndex;
   NSUInteger                 _currentWindowIndex;   // default window for events without N:
}

@property( assign) NSUInteger   debuggingFlags  MULLE_OBJC_THREADSAFE_PROPERTY;

// Load script from string or file
- (BOOL) loadScriptFromUTF8String:(char *) scriptText;
- (BOOL) loadScriptFromFile:(char *) path;

// Start playback (call after loading script)
- (void) startPlayback;

// Set to NO to skip events with invalid window index instead of aborting (default: YES)
- (void) setAbortOnInvalidWindowIndex:(BOOL) flag;
- (BOOL) abortOnInvalidWindowIndex;

// UITimerReceiver
- (void) timerFired:(NSTimer *) timer;

@end
