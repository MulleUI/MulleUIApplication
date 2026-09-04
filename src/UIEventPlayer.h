//
//  UIEventPlayer.h
//  MulleUIApplication
//
//  Copyright (c) 2026 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
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
