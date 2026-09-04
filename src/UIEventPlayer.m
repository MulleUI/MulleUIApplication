//
//  UIEventPlayer.m
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
#import "UIEventPlayer.h"

#import "UIApplication.h"
#import "UIEvent.h"
#import "UIWindowTypes.h"
#import "UIEventPlayer+DebugPrivate.h"
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>


// Private enum for script event types
typedef NS_ENUM( NSUInteger, UIScriptedEventType)
{
   UIScriptedEventTypeMouseMove,
   UIScriptedEventTypeMouseDown,
   UIScriptedEventTypeMouseUp,
   UIScriptedEventTypeKeyDown,
   UIScriptedEventTypeKeyUp,
   UIScriptedEventTypeTerminate,
   UIScriptedEventTypeCloseButton
};


// Table defined in .m file
static NS_ENUM_TABLE( UIScriptedEventType, 7);


// Private enum for modifier shortcuts in scripts
typedef NS_OPTIONS( NSUInteger, UIScriptModifier)
{
   Shift    = UIEventKeyModifierShift,
   Control  = UIEventKeyModifierControl,
   Alt      = UIEventKeyModifierAlt,
   Super    = UIEventKeyModifierSuper,
   CapsLock = UIEventKeyModifierCapsLock,
   NumLock  = UIEventKeyModifierNumLock
};


// Table defined in .m file
static NS_OPTIONS_TABLE( UIScriptModifier, 6);


// windows defines this (argh) #1#
#ifdef Escape
# undef Escape
#endif

// Private enum for key shortcuts in scripts
typedef NS_ENUM( NSUInteger, UIScriptKey)
{
   Space      = UIEventKeySpace,
   Enter      = UIEventKeyEnter,
   Tab        = UIEventKeyTab,
   Backspace  = UIEventKeyBackspace,
   //Escape     = UIEventKeyEscape,      // windows defines this (argh) #1#
   Delete     = UIEventKeyDelete,
   Insert     = UIEventKeyInsert,
   Home       = UIEventKeyHome,
   End        = UIEventKeyEnd,
   PageUp     = UIEventKeyPageUp,
   PageDown   = UIEventKeyPageDown,
   Left       = UIEventKeyLeft,
   Right      = UIEventKeyRight,
   Up         = UIEventKeyUp,
   Down       = UIEventKeyDown,
   F1         = UIEventKeyF1,
   F2         = UIEventKeyF2,
   F3         = UIEventKeyF3,
   F4         = UIEventKeyF4,
   F5         = UIEventKeyF5,
   F6         = UIEventKeyF6,
   F7         = UIEventKeyF7,
   F8         = UIEventKeyF8,
   F9         = UIEventKeyF9,
   F10        = UIEventKeyF10,
   F11        = UIEventKeyF11,
   F12        = UIEventKeyF12,
   A          = UIEventKeyA,
   B          = UIEventKeyB,
   C          = UIEventKeyC,
   D          = UIEventKeyD,
   E          = UIEventKeyE,
   F          = UIEventKeyF,
   G          = UIEventKeyG,
   H          = UIEventKeyH,
   I          = UIEventKeyI,
   J          = UIEventKeyJ,
   K          = UIEventKeyK,
   L          = UIEventKeyL,
   M          = UIEventKeyM,
   N          = UIEventKeyN,
   O          = UIEventKeyO,
   P          = UIEventKeyP,
   Q          = UIEventKeyQ,
   R          = UIEventKeyR,
   S          = UIEventKeyS,
   T          = UIEventKeyT,
   U          = UIEventKeyU,
   V          = UIEventKeyV,
   W          = UIEventKeyW,
   X          = UIEventKeyX,
   Y          = UIEventKeyY,
   Z          = UIEventKeyZ
};


// Table defined in .m file
static NS_ENUM_TABLE( UIScriptKey, 60);


// Private enum for mouse button shortcuts in scripts
typedef NS_ENUM( NSUInteger, UIScriptMouseButton)
{
   ButtonLeft   = UIEventMouseButtonLeft,
   ButtonRight  = UIEventMouseButtonRight,
   ButtonMiddle = UIEventMouseButtonMiddle
};


// Table defined in .m file
static NS_ENUM_TABLE( UIScriptMouseButton, 3);


struct UIScriptedEvent
{
   mulle_relativetime_t        relativeTime;
   NSUInteger                  windowIndex;
   UIScriptedEventType         eventType;
   
   union
   {
      struct
      {
         double   x;
         double   y;
      } mouseMove;
      
      struct
      {
         NSUInteger   button;
         double       x;
         double       y;
      } mouseButton;
      
      struct
      {
         NSUInteger   key;
         NSUInteger   scancode;
         NSUInteger   mods;
      } keyboard;
   } params;
};


@implementation UIEventPlayer


static struct
{
   NSUInteger   _debuggingFlags;
} ClassStatic;


static void   UIEventPlayerInitializeDebuggingFlags( Class self)
{
   char   *s;

   s = getenv( MULLE_C_STRINGIFY( UIEventPlayer) "DebuggingFlags");
   if( ! s)
      s = getenv( "UIDebuggingFlags");
   if( s)
      ClassStatic._debuggingFlags = strtol( s, NULL, 0);
}


+ (void) setDebuggingFlags:(NSUInteger) flag   MULLE_OBJC_THREADSAFE_METHOD
{
   ClassStatic._debuggingFlags = flag;
}


+ (void) initialize
{
   MulleObjCClassInitializeOnceDo( self)
   {
      UIEventPlayerInitializeDebuggingFlags( self);
   }
}



- (instancetype) init
{
   _debuggingFlags           = ClassStatic._debuggingFlags;
   _stopOnInvalidWindowIndex = YES;
   _currentWindowIndex       = 0;

   mulle_structarray_init( &_events,
                           sizeof( struct UIScriptedEvent),
                           __alignof__( struct UIScriptedEvent),
                           0,
                           NULL);
   return( self);
}


- (void) dealloc
{
   mulle_structarray_done( &_events);
   
   [super dealloc];
}


- (void) setAbortOnInvalidWindowIndex:(BOOL) flag
{
   _stopOnInvalidWindowIndex = flag;
}


- (BOOL) abortOnInvalidWindowIndex
{
   return( _stopOnInvalidWindowIndex);
}


- (void) handleRetainedTimer:(NSTimer *) timer
{
   [self timerFired:timer];
   [timer autorelease];
}


#pragma mark - Script Loading


static NSUInteger   parseMouseButton( char *name)
{
   unsigned long long   ull;

   if( NS_ENUM_PARSE_STRICT( UIScriptMouseButton, name, &ull))
      return( (NSUInteger) ull);
   return( NSUIntegerMax);
}


static NSUInteger   parseKey( char *name)
{
   unsigned long long   ull;

   if( NS_ENUM_PARSE_STRICT( UIScriptKey, name, &ull))
      return( (NSUInteger) ull);
   return( NSUIntegerMax);
}


static NSUInteger   parseModifiers( char *name)
{
   unsigned long long   ull;

   // Handle numeric value
   if( isdigit( name[ 0]))
      return( (NSUInteger) strtoul( name, NULL, 0));
   

   if( NS_OPTIONS_PARSE_STRICT( UIScriptModifier, name, &ull))
      return( (NSUInteger) ull);
   return( NSUIntegerMax);
}


- (BOOL) parseScriptLine:(char *) line
                   event:(struct UIScriptedEvent *) event
                 lineNum:(NSUInteger) lineNum
                 lineEnd:(char *) lineEnd
{
   char         *p;
   char         eventType[ 64];
   NSUInteger   windowIndex;
   double       relativeTime;
   
   // Initialize event
   memset( event, 0, sizeof( *event));
   
   p               = line;
   windowIndex     = _currentWindowIndex;
   
   // Skip leading whitespace
   while( p < lineEnd && isspace( *p))
      p++;
   
   // Check for window index (N:)
   if( p < lineEnd && isdigit( *p))
   {
      char   *colon;
      
      colon = strchr( p, ':');
      if( colon && colon < lineEnd && colon[ 1] == ' ')
      {
         windowIndex    = (NSUInteger) strtoul( p, NULL, 10);
         p              = colon + 1;
         
         // Skip whitespace after colon
         while( p < lineEnd && isspace( *p))
            p++;
      }
   }
   
   event->windowIndex = windowIndex;
   
   // Parse relative time
   if( p >= lineEnd || sscanf( p, "%lf", &relativeTime) != 1)
   {
      mulle_fprintf( stderr, "UIEventPlayer: Line %lu: Failed to parse time from: %.*s\n", 
                     lineNum, (int)(lineEnd - p), p);
      return( NO);
   }
   
   event->relativeTime = relativeTime;
   
   // Skip to event type
   while( p < lineEnd && ! isspace( *p))
      p++;
   while( p < lineEnd && isspace( *p))
      p++;
   
   // Parse event type
   if( p >= lineEnd || sscanf( p, "%63s", eventType) != 1)
   {
      mulle_fprintf( stderr, "UIEventPlayer: Line %lu: Failed to parse event type from: %.*s\n", 
                     lineNum, (int)(lineEnd - p), p);
      return( NO);
   }
   
   // Parse event type (strict when available)
   {
      unsigned long long   ull;
      if( NS_ENUM_PARSE_STRICT( UIScriptedEventType, eventType, &ull))
         event->eventType = (UIScriptedEventType) ull;
      else
         event->eventType = (UIScriptedEventType) -1;
   }

   if( event->eventType == (UIScriptedEventType) -1)
   {
      mulle_fprintf( stderr, "UIEventPlayer: Line %lu: Unknown event type: %s\n", lineNum, eventType);
      return( NO);
   }
   
   // Terminate and closeButton events have no parameters
   if( event->eventType == UIScriptedEventTypeTerminate ||
       event->eventType == UIScriptedEventTypeCloseButton)
      return( YES);
   
   // Skip to parameters
   while( *p && ! isspace( *p))
      p++;
   while( *p && isspace( *p))
      p++;
   
   // Parse parameters based on event type
   switch( event->eventType)
   {
   case UIScriptedEventTypeMouseMove:
      if( sscanf( p, "x=%lf y=%lf", 
                  &event->params.mouseMove.x,
                  &event->params.mouseMove.y) != 2)
      {
         mulle_fprintf( stderr, "UIEventPlayer: Line %lu: Failed to parse mouseMove parameters: %s\n", lineNum, p);
         return( NO);
      }
      break;
      
   case UIScriptedEventTypeMouseDown:
   case UIScriptedEventTypeMouseUp:
      {
         char   buttonName[ 64];
         
         if( sscanf( p, "button=%63s x=%lf y=%lf",
                     buttonName,
                     &event->params.mouseButton.x,
                     &event->params.mouseButton.y) != 3)
         {
            mulle_fprintf( stderr, "UIEventPlayer: Line %lu: Failed to parse mouse button parameters: %s\n", lineNum, p);
            return( NO);
         }
         
         event->params.mouseButton.button = parseMouseButton( buttonName);
         if( event->params.mouseButton.button == NSUIntegerMax)
         {
            mulle_fprintf( stderr, "UIEventPlayer: Line %lu: Invalid button name: %s\n", lineNum, buttonName);
            return( NO);
         }
      }
      break;
      
   case UIScriptedEventTypeKeyDown:
   case UIScriptedEventTypeKeyUp:
      {
         char   name[ 64];
         char   value[ 256];
         char   *q;

         // Set defaults
         event->params.keyboard.scancode = 0;
         event->params.keyboard.mods     = 0;

         // Parse key=value tokens until end of line
         q = p;
         while( q < lineEnd)
         {
            // skip whitespace
            while( q < lineEnd && isspace( (unsigned char) *q))
               q++;
            if( q >= lineEnd)
               break;

            // read name=value token
            if( sscanf( q, "%63[^= ]=%255s", name, value) != 2)
               break;

            if( ! strcmp( name, "key"))
            {
               event->params.keyboard.key = parseKey( value);
               if( event->params.keyboard.key == NSUIntegerMax)
               {
                  mulle_fprintf( stderr, "UIEventPlayer: Line %lu: Invalid key name: %s\n", lineNum, value);
                  return( NO);
               }
            }
            else if( ! strcmp( name, "mods"))
            {
               event->params.keyboard.mods = parseModifiers( value);
               if( event->params.keyboard.mods == NSUIntegerMax)
               {
                  mulle_fprintf( stderr, "UIEventPlayer: Line %lu: Invalid modifiers: %s\n", lineNum, value);
                  return( NO);
               }
            }
            else if( ! strcmp( name, "scancode"))
            {
               event->params.keyboard.scancode = (NSUInteger) strtoul( value, NULL, 0);
            }

            // advance past this token
            while( q < lineEnd && ! isspace( (unsigned char) *q))
               q++;
         }

         if( ! event->params.keyboard.key)
         {
            mulle_fprintf( stderr, "UIEventPlayer: Line %lu: Missing key parameter\n", lineNum);
            return( NO);
         }
      }
      break;
      
   default:
      break;
   }
   
   return( YES);
}


- (BOOL) loadScriptWithUTF8String:(char *) scriptText
{
   char                     *p;
   char                     *lineStart;
   char                     *lineEnd;
   struct UIScriptedEvent   event;
   NSUInteger               lineNum;
   
   // Clear any existing events
   mulle_structarray_reset( &_events);
   
   p       = scriptText;
   lineNum = 0;
   
   while( *p)
   {
      lineNum++;
      lineStart = p;
      memset( &event, 0, sizeof( event));
      
      // Find end of line
      while( *p && *p != '\n')
         p++;
      
      lineEnd = p;
      
      // Skip the newline for next iteration
      if( *p == '\n')
         p++;
      
      // Skip leading whitespace in line
      while( lineStart < lineEnd && isspace( *lineStart))
         lineStart++;
      
      // Skip comments and blank lines
      if( lineStart >= lineEnd || *lineStart == '#')
         continue;
      
      // Handle 'window N' directive setting default window index (only if line is just that)
      if( ! strncmp( lineStart, "window", 6))
      {
         char           *q;
         char           *endptr;
         unsigned long   n;
         
         q = lineStart + 6;
         while( q < lineEnd && isspace( *q))
            q++;
         n      = strtoul( q, &endptr, 10);
         if( endptr != q)
         {
            while( endptr < lineEnd && isspace( *endptr))
               endptr++;
            if( endptr == lineEnd)
            {
               _currentWindowIndex = (NSUInteger) n;
               continue;  // consume directive line
            }
         }
         // Not a pure directive, fall through to normal parsing
      }
      
      // Parse line (lineEnd points to \n or \0)
      if( ! [self parseScriptLine:lineStart
                            event:&event
                            lineNum:lineNum
                            lineEnd:lineEnd])
         return( NO);
      
      // Add event
      mulle_structarray_add( &_events, &event);
   
   }
   
   return( YES);
}


- (BOOL) loadScriptWithFILE:(FILE *) fp
{
   char     *content;
   char     *tmp;
   size_t   cap;
   size_t   len;
   size_t   n;
   BOOL     result;

   cap     = 4096;
   len     = 0;
   content = malloc( cap);
   if( ! content)
   {
      mulle_fprintf( stderr, "UIEventPlayer: out of memory reading script\n");
      return( NO);
   }

   for( ;;)
   {
      n = fread( content + len, 1, cap - len - 1, fp);
      if( ! n)
      {
         if( ferror( fp))
         {
            mulle_fprintf( stderr, "UIEventPlayer: Failed to read script\n");
            free( content);
            return( NO);
         }
         break;
      }
      len += n;
      if( cap - len < 1024)
      {
         cap *= 2;
         tmp  = realloc( content, cap);
         if( ! tmp)
         {
            mulle_fprintf( stderr, "UIEventPlayer: out of memory reading script\n");
            free( content);
            return( NO);
         }
         content = tmp;
      }
   }
   content[ len] = '\0';

   result = [self loadScriptWithUTF8String:content];
   free( content);
   return( result);
}


// MEMO: could be using NSData but we dont't have it
- (BOOL) loadScriptWithContentsOfFile:(char *) path
{
   FILE   *fp;
   BOOL   result;

   fp = fopen( path, "r");
   if( ! fp)
   {
      mulle_fprintf( stderr, "UIEventPlayer: Failed to open script file '%s': %s\n",
               path, strerror( errno));
      return( NO);
   }
   
   result = [self loadScriptWithFILE:fp];
   fclose( fp);

   return( result);
}



#pragma mark - Playback


- (void) startPlayback
{
   struct UIScriptedEvent   *event;
   mulle_relativetime_t     delay;
   NSTimer                  *timer;
   UIApplication            *app;

   UIEventPlayerLog( "");

   _startTime  = mulle_absolutetime_now();
   _nextIndex  = 0;

   if( mulle_structarray_get_count( &_events) == 0)
   {
      UIEventPlayerLog( "No events, nothing to do");
      return;
   }

   app = [UIApplication sharedInstance];
   // Ensure lifecycle is tied to UIApplication
   [app setEventPlayer:self];
   
   // Schedule first event
   event = mulle_structarray_get( &_events, 0);
   delay = event->relativeTime;
   
   timer = [NSTimer mulleTimerWithRelativeTimeInterval:delay
                                        repeatInterval:0.0
                                                target:self
                                              selector:@selector( timerFired:)
                                              userInfo:nil
                            fireUsesUserInfoAsArgument:NO];
   
   [app addTimer:timer
forTimerReceiver:self];
}


- (void) scheduleNextEvent
{
   struct UIScriptedEvent   *event;
   mulle_absolutetime_t     now;
   mulle_relativetime_t     delay;
   NSTimer                  *timer;
   UIApplication            *app;
   
   if( _nextIndex >= mulle_structarray_get_count( &_events))
      return;
   
   event = mulle_structarray_get( &_events, _nextIndex);
   now   = mulle_absolutetime_now();
   delay = (_startTime + event->relativeTime) - now;
   
   if( delay < 0.0)
      delay = 0.0;

   UIEventPlayerLog( "index=%lu relativeTime=%.3f delay=%.3f",
                     (unsigned long) _nextIndex,
                     event->relativeTime,
                     delay);
   
   timer = [NSTimer mulleTimerWithRelativeTimeInterval:delay
                                         repeatInterval:0.0
                                                 target:self
                                               selector:@selector( timerFired:)
                                               userInfo:nil
                     fireUsesUserInfoAsArgument:NO];
   
   app = [UIApplication sharedInstance];
   [app addTimer:timer
 forTimerReceiver:self];
}


- (UIEvent *) newEventWithScriptedEvent:(struct UIScriptedEvent *) scriptEvent
{
   struct UIInputState   inputState;
   UIEvent              *event;
   
   memset( &inputState, 0, sizeof( inputState));
   event = nil;
   
   switch( scriptEvent->eventType)
   {
   case UIScriptedEventTypeMouseMove:
      inputState.locationInWindow = CGPointMake( scriptEvent->params.mouseMove.x,
                                                  scriptEvent->params.mouseMove.y);
      event = [[UIMouseMotionEvent alloc] initWithInputState:&inputState];
      break;
      
   case UIScriptedEventTypeMouseDown:
   case UIScriptedEventTypeMouseUp:
      inputState.timestamp        = mulle_absolutetime_now();
      inputState.locationInWindow = CGPointMake( scriptEvent->params.mouseButton.x,
                                                  scriptEvent->params.mouseButton.y);
      inputState.buttonStates     = scriptEvent->params.mouseButton.button;

      if( scriptEvent->eventType == UIScriptedEventTypeMouseDown)
      {
         CGFloat  dx  = inputState.locationInWindow.x - _lastMouseButtonPressLocation.x;
         CGFloat  dy  = inputState.locationInWindow.y - _lastMouseButtonPressLocation.y;
         BOOL     isMultiClick;

         isMultiClick = dx * dx + dy * dy < 5.0 * 5.0
                        && inputState.timestamp - _lastMouseButtonPressTime < [UIMouseButtonEvent doubleClickInterval];
         if( ! isMultiClick)
            _mouseButtonClickCount = 0;
         ++_mouseButtonClickCount;
         _lastMouseButtonPressTime     = inputState.timestamp;
         _lastMouseButtonPressLocation = inputState.locationInWindow;
      }

      event = [[UIMouseButtonEvent alloc] initWithInputState:&inputState
                                                      button:scriptEvent->params.mouseButton.button
                                                      action:scriptEvent->eventType == UIScriptedEventTypeMouseDown
                                                               ? UIEventButtonActionDown
                                                               : UIEventButtonActionUp
                                                  clickCount:_mouseButtonClickCount];
      break;
      
   case UIScriptedEventTypeKeyDown:
   case UIScriptedEventTypeKeyUp:
      inputState.keyModifiers = scriptEvent->params.keyboard.mods;
      event = [[UIKeyboardEvent alloc] initWithInputState:&inputState
                                                        key:scriptEvent->params.keyboard.key
                                                   scanCode:scriptEvent->params.keyboard.scancode
                                                     action:scriptEvent->eventType == UIScriptedEventTypeKeyDown
                                                              ? UIEventButtonActionDown
                                                              : UIEventButtonActionUp
                                                  isARepeat:NO];
      break;
      
   default:
      mulle_fprintf( stderr,
                     "UIEventPlayer: unsupported scripted event type %u\n",
                     (unsigned) scriptEvent->eventType);
      abort();
      break;
   }
   
   return( event);
}


- (void) stopPlayback
{
   UIApplication   *app;

   app = [UIApplication sharedInstance];

   [app removeAllTimersForTimerReceiver:self];
   [app setEventPlayer:nil];
}


- (void) timerFired:(NSTimer *) timer
{
   UIApplication             *app;
   id <UIWindow>             window;
   struct UIScriptedEvent    *scriptEvent;
   UIEvent                   *event;
   NSUInteger                windowCount;

   UIEventPlayerLog( "");
   
   app = [UIApplication sharedInstance];
   
   // Get current event
   scriptEvent = mulle_structarray_get( &_events, _nextIndex);
   switch( scriptEvent->eventType)
   {
   case UIScriptedEventTypeTerminate :
      if( _stopAction != UIEventPlayerIgnoresTerminationScriptEvent)
      {
         UIEventPlayerLog( "terminate event firing, calling requestTerminate");
         [app requestTerminate];
      }
      goto next;
   }

   windowCount = [app numberOfWindows];
   if( scriptEvent->windowIndex >= windowCount)
   {
      mulle_fprintf( stderr, "Event script error: window index %lu invalid (only %lu windows)\n",
               scriptEvent->windowIndex, windowCount);

      if( _stopOnInvalidWindowIndex)
      {
         [self stopPlayback];
         return;
      }
      goto next;
   }

   window = [app windowAtIndex:scriptEvent->windowIndex];
   if( ! window)
   {
      mulle_fprintf( stderr, "Event script error: failed to get window at index %lu\n",
               scriptEvent->windowIndex);
      if( _stopOnInvalidWindowIndex)
      {
         [self stopPlayback];
         return;
      }
      goto next;
   }

   switch( scriptEvent->eventType)
   {
   case UIScriptedEventTypeCloseButton :
      UIEventPlayerLog( "closeButton event firing, calling requestClose on window");
      [window os_requestClose];
      goto next;
   }
   
   // Create UIEvent from script

   event = [self newEventWithScriptedEvent:scriptEvent];
   if( ! event)
   {
      mulle_fprintf( stderr, "Event script error: failed to create event\n");
      goto next;
   }
   
   UIEventPlayerEventLog( event, "Dispatching scripted event");
   [window receiveRetainedEvent:event];
   
next:
   _nextIndex++;
   if( _nextIndex < mulle_structarray_get_count( &_events))
   {
      [self scheduleNextEvent];
      return;
   }

   [self stopPlayback];
   if( _stopAction == UIEventPlayerTerminates)
      [app requestTerminate];
}


@end


// Event type table for parsing
static NS_ENUM_TABLE( UIScriptedEventType, 7) =
{
   { "mouseMove", UIScriptedEventTypeMouseMove },
   { "mouseDown", UIScriptedEventTypeMouseDown },
   { "mouseUp",   UIScriptedEventTypeMouseUp },
   { "keyDown",   UIScriptedEventTypeKeyDown },
   { "keyUp",     UIScriptedEventTypeKeyUp },
   { "terminate", UIScriptedEventTypeTerminate },
   { "closeButton", UIScriptedEventTypeCloseButton }
};


// Modifier shortcuts table for parsing
static NS_OPTIONS_TABLE( UIScriptModifier, 6) =
{
   NS_OPTIONS_ITEM( Shift),
   NS_OPTIONS_ITEM( Control),
   NS_OPTIONS_ITEM( Alt),
   NS_OPTIONS_ITEM( Super),
   NS_OPTIONS_ITEM( CapsLock),
   NS_OPTIONS_ITEM( NumLock)
};


// Key shortcuts table for parsing
static NS_ENUM_TABLE( UIScriptKey, 60) =
{
   NS_ENUM_ITEM( Space),
   NS_ENUM_ITEM( Enter),
   NS_ENUM_ITEM( Tab),
   NS_ENUM_ITEM( Backspace),
   NS_ENUM_ITEM( UIEventKeyEscape),  // windows redefines this
   NS_ENUM_ITEM( Delete),
   NS_ENUM_ITEM( Insert),
   NS_ENUM_ITEM( Home),
   NS_ENUM_ITEM( End),
   NS_ENUM_ITEM( PageUp),
   NS_ENUM_ITEM( PageDown),
   NS_ENUM_ITEM( Left),
   NS_ENUM_ITEM( Right),
   NS_ENUM_ITEM( Up),
   NS_ENUM_ITEM( Down),
   NS_ENUM_ITEM( F1),
   NS_ENUM_ITEM( F2),
   NS_ENUM_ITEM( F3),
   NS_ENUM_ITEM( F4),
   NS_ENUM_ITEM( F5),
   NS_ENUM_ITEM( F6),
   NS_ENUM_ITEM( F7),
   NS_ENUM_ITEM( F8),
   NS_ENUM_ITEM( F9),
   NS_ENUM_ITEM( F10),
   NS_ENUM_ITEM( F11),
   NS_ENUM_ITEM( F12),
   NS_ENUM_ITEM( A),
   NS_ENUM_ITEM( B),
   NS_ENUM_ITEM( C),
   NS_ENUM_ITEM( D),
   NS_ENUM_ITEM( E),
   NS_ENUM_ITEM( F),
   NS_ENUM_ITEM( G),
   NS_ENUM_ITEM( H),
   NS_ENUM_ITEM( I),
   NS_ENUM_ITEM( J),
   NS_ENUM_ITEM( K),
   NS_ENUM_ITEM( L),
   NS_ENUM_ITEM( M),
   NS_ENUM_ITEM( N),
   NS_ENUM_ITEM( O),
   NS_ENUM_ITEM( P),
   NS_ENUM_ITEM( Q),
   NS_ENUM_ITEM( R),
   NS_ENUM_ITEM( S),
   NS_ENUM_ITEM( T),
   NS_ENUM_ITEM( U),
   NS_ENUM_ITEM( V),
   NS_ENUM_ITEM( W),
   NS_ENUM_ITEM( X),
   NS_ENUM_ITEM( Y),
   NS_ENUM_ITEM( Z)
};

// Not sure who uses this this
// Mouse button shortcuts table for parsing (manual entries for custom names)
static NS_ENUM_TABLE( UIScriptMouseButton, 3) =
{
   { "Left",   UIEventMouseButtonLeft },
   { "Right",  UIEventMouseButtonRight },
   { "Middle", UIEventMouseButtonMiddle }
};

// #1#
//
// /home/src/srcO/MulleUI/MulleUIApplication/src/UIEventPlayer.m:72:4: error: redefinition of 'Escape'
//    72 |    Escape     = UIEventKeyEscape,
//       |    ^
// /opt/mulle-clang-project-windows/21.1.8.5/x86_64-w64-mingw32/include/wingdi.h:3018:24: note: previous definition is here
//  3018 |   WINGDIAPI int WINAPI Escape(HDC hdc,int iEscape,int cjIn,LPCSTR pvIn,LPVOID pvOut);
//
// But why does the preprocessor care ? Are we still doing C here ??
