#import "UIEventPlayer.h"

#import "UIApplication.h"
#import "UIEvent.h"
#import "UIWindowTypes.h"
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>



#define UIEventPlayerLog( format, ...)                                      \
do                                                                          \
{                                                                           \
   if( self->_debuggingFlags & 0x1)                                         \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)

#define UIEventPlayerEventLog( event, format, ...)                                   \
do                                                                                   \
{                                                                                    \
   if( self->_debuggingFlags & 0x2)                                                  \
      if( ! event || ([event eventType] & ~(UIEventTypeMotion|UIEventTypeTracking))) \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,              \
                                          (char *) format, ## __VA_ARGS__);          \
}                                                                                    \
while( 0)


// Private enum for script event types
typedef NS_ENUM( NSUInteger, UIScriptedEventType)
{
   UIScriptedEventTypeMouseMove,
   UIScriptedEventTypeMouseDown,
   UIScriptedEventTypeMouseUp,
   UIScriptedEventTypeKeyDown,
   UIScriptedEventTypeKeyUp,
   UIScriptedEventTypeTerminate
};


// Table defined in .m file
extern NS_ENUM_TABLE( UIScriptedEventType, 6);


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
extern NS_OPTIONS_TABLE( UIScriptModifier, 6);


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
extern NS_ENUM_TABLE( UIScriptKey, 60);


// Private enum for mouse button shortcuts in scripts
typedef NS_ENUM( NSUInteger, UIScriptMouseButton)
{
   ButtonLeft   = UIEventMouseButtonLeft,
   ButtonRight  = UIEventMouseButtonRight,
   ButtonMiddle = UIEventMouseButtonMiddle
};


// Table defined in .m file
extern NS_ENUM_TABLE( UIScriptMouseButton, 3);


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
} Self;


static void   UIEventPlayerInitializeDebuggingFlags( Class self)
{
   char   *s;

   // don't rerun for subclass
   if( MulleObjCClassGetID( self) != @selector( UIEventPlayer))
      return;

   // __CLASS_NAME__ is a wished for compiler feature,
   s = getenv( MULLE_C_STRINGIFY( UIEventPlayer) "DebuggingFlags");
   if( ! s)
      s = getenv( "UIDebuggingFlags");
   if( s)
      Self._debuggingFlags = strtol( s, NULL, 0);
}


+ (void) setDebuggingFlags:(NSUInteger) flag   MULLE_OBJC_THREADSAFE_METHOD
{
   Self._debuggingFlags = flag;
}


+ (void) initialize
{
   UIEventPlayerInitializeDebuggingFlags( self);
}



- (instancetype) init
{
   _debuggingFlags            = Self._debuggingFlags;
   _abortOnInvalidWindowIndex = YES;
   _currentWindowIndex        = 0;

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
   _abortOnInvalidWindowIndex = flag;
}


- (BOOL) abortOnInvalidWindowIndex
{
   return( _abortOnInvalidWindowIndex);
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
   
   // Terminate event has no parameters
   if( event->eventType == UIScriptedEventTypeTerminate)
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
         char   keyName[ 64];
         char   modsName[ 256];
         int    scancode;
         
         // Set defaults
         event->params.keyboard.scancode = 0;
         event->params.keyboard.mods     = 0;
         
         // Parse key (required)
         if( sscanf( p, "key=%63s", keyName) != 1)
         {
            mulle_fprintf( stderr, "UIEventPlayer: Line %lu: Failed to parse key parameter: %s\n", lineNum, p);
            return( NO);
         }
         
         event->params.keyboard.key = parseKey( keyName);
         if( event->params.keyboard.key == NSUIntegerMax)
         {
            mulle_fprintf( stderr, "UIEventPlayer: Line %lu: Invalid key name: %s\n", lineNum, keyName);
            return( NO);
         }
         
         // Parse optional mods
         if( strstr( p, "mods="))
         {
            if( sscanf( strstr( p, "mods="), "mods=%255s", modsName) == 1)
            {
               event->params.keyboard.mods = parseModifiers( modsName);
               if( event->params.keyboard.mods == NSUIntegerMax)
               {
                  mulle_fprintf( stderr, "UIEventPlayer: Line %lu: Invalid modifiers: %s\n", lineNum, modsName);
                  return( NO);
               }
            }
         }
         
         // Parse optional scancode
         if( strstr( p, "scancode="))
         {
            if( sscanf( strstr( p, "scancode="), "scancode=%d", &scancode) == 1)
               event->params.keyboard.scancode = (NSUInteger) scancode;
         }
      }
      break;
      
   default:
      break;
   }
   
   return( YES);
}


- (BOOL) loadScriptFromUTF8String:(char *) scriptText
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
      if( ! [self parseScriptLine:lineStart event:&event lineNum:lineNum lineEnd:lineEnd])
         return( NO);
      
      // Add event
      mulle_structarray_add( &_events, &event);
   
   }
   
   return( YES);
}


- (BOOL) loadScriptFromFile:(char *) path
{
   FILE   *fp;
   char   *content;
   long   size;
   BOOL   result;
   
   fp = fopen( path, "r");
   if( ! fp)
   {
      mulle_fprintf( stderr, "UIEventPlayer: Failed to open script file '%s': %s\n", 
               path, strerror( errno));
      return( NO);
   }
   
   // Get file size
   fseek( fp, 0, SEEK_END);
   size = ftell( fp);
   fseek( fp, 0, SEEK_SET);
   
   // Read file
   content = malloc( size + 1);
   if( ! content)
   {
      mulle_fprintf( stderr, "UIEventPlayer: Failed to allocate %ld bytes for script file\n", size);
      fclose( fp);
      return( NO);
   }
   
   if( fread( content, 1, size, fp) != (size_t) size)
   {
      mulle_fprintf( stderr, "UIEventPlayer: Failed to read script file '%s'\n", path);
      free( content);
      fclose( fp);
      return( NO);
   }
   
   content[ size] = '\0';
   fclose( fp);
   
   // Parse with filename for better error messages
   result = [self loadScriptFromUTF8String:content];
   free( content);
   
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
      inputState.locationInWindow = CGPointMake( scriptEvent->params.mouseButton.x,
                                                  scriptEvent->params.mouseButton.y);
      inputState.buttonStates     = scriptEvent->params.mouseButton.button;
      event = [[UIMouseButtonEvent alloc] initWithInputState:&inputState
                                                        button:scriptEvent->params.mouseButton.button
                                                        action:scriptEvent->eventType == UIScriptedEventTypeMouseDown
                                                                 ? UIEventButtonActionDown
                                                                 : UIEventButtonActionUp];
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
   
   // Handle terminate event
   if( scriptEvent->eventType == UIScriptedEventTypeTerminate)
   {
      [app requestTerminate];
      return;
   }
   
   // Validate window index
   windowCount = [app numberOfWindows];
   if( scriptEvent->windowIndex >= windowCount)
   {
      if( _abortOnInvalidWindowIndex)
      {
         mulle_fprintf( stderr, "Event script error: window index %lu invalid (only %lu windows)\n",
                  scriptEvent->windowIndex, windowCount);
         [app requestTerminate];
         return;
      }
      else
      {
         mulle_fprintf( stderr, "Event script warning: skipping event for invalid window %lu\n",
                  scriptEvent->windowIndex);
         _nextIndex++;
         [self scheduleNextEvent];
         return;
      }
   }
   
   // Get target window
   window = [app windowAtIndex:scriptEvent->windowIndex];
   if( ! window)
   {
      mulle_fprintf( stderr, "Event script error: failed to get window at index %lu\n",
               scriptEvent->windowIndex);
      _nextIndex++;
      [self scheduleNextEvent];
      return;
   }
   
   // Create UIEvent from script

   event = [self newEventWithScriptedEvent:scriptEvent];
   if( ! event)
   {
      mulle_fprintf( stderr, "Event script error: failed to create event\n");
      _nextIndex++;
      [self scheduleNextEvent];
      return;
   }
   
   UIEventPlayerEventLog( event, "Dispatching scripted event");

   // Dispatch event to window
   [window receiveRetainedEvent:event];
   
   _nextIndex++;
   if( _nextIndex >= mulle_structarray_get_count( &_events))
   {
      UIApplication  *app;

      app = [UIApplication sharedInstance];
      [app removeAllTimersForTimerReceiver:self];
      [app setEventPlayer:nil];
      [app requestTerminate];
   }
   else
      [self scheduleNextEvent];
}


@end


// Event type table for parsing
NS_ENUM_TABLE( UIScriptedEventType, 6) =
{
   { "mouseMove", UIScriptedEventTypeMouseMove },
   { "mouseDown", UIScriptedEventTypeMouseDown },
   { "mouseUp",   UIScriptedEventTypeMouseUp },
   { "keyDown",   UIScriptedEventTypeKeyDown },
   { "keyUp",     UIScriptedEventTypeKeyUp },
   { "terminate", UIScriptedEventTypeTerminate }
};


// Modifier shortcuts table for parsing
NS_OPTIONS_TABLE( UIScriptModifier, 6) =
{
   NS_OPTIONS_ITEM( Shift),
   NS_OPTIONS_ITEM( Control),
   NS_OPTIONS_ITEM( Alt),
   NS_OPTIONS_ITEM( Super),
   NS_OPTIONS_ITEM( CapsLock),
   NS_OPTIONS_ITEM( NumLock)
};


// Key shortcuts table for parsing
NS_ENUM_TABLE( UIScriptKey, 60) =
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


// Mouse button shortcuts table for parsing (manual entries for custom names)
struct UIScriptMouseButton__item UIScriptMouseButton__table[ 3] =
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
