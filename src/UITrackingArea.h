#include "import.h"


// mulle addition
struct UITrackingArea
{
   CGRect    rect;
   id        userInfo;
   struct
   {
      unsigned  receivesObscuredEvents : 1;
   } flag;
};



static inline void    UITrackingAreaInit( struct UITrackingArea *p, CGRect rect, id userInfo)
{
   p->rect     = rect;
   p->userInfo = [userInfo retain];
   p->flag.receivesObscuredEvents = NO;
}

static inline void    UITrackingAreaDone( struct UITrackingArea *p)
{
   [p->userInfo autorelease];
}


static inline void    UITrackingAreaSetRect( struct UITrackingArea *p,
                                                CGRect rect)
{
   p->rect = rect;
}


static inline CGRect    UITrackingAreaGetRect( struct UITrackingArea *p)
{
   return( p->rect);
}


static inline void    UITrackingAreaSetUserInfo( struct UITrackingArea *p,
                                                    id userInfo)
{
   [p->userInfo autorelease];
   p->userInfo = [userInfo retain];
}

static inline id    UITrackingAreaGetUserInfo( struct UITrackingArea *p)
{
   return( p->userInfo);
}



// not that useful for public consumption, therefore not typedef
struct UITrackingAreaArray
{
   NSUInteger                  n;
   NSUInteger                  size;
   struct mulle_allocator      *allocator;
   struct UITrackingArea    *items;
};


void
   UITrackingAreaArrayInit( struct UITrackingAreaArray *array,
                               struct mulle_allocator *allocator);

void
   UITrackingAreaArrayDone( struct UITrackingAreaArray *array);

static inline NSUInteger
   UITrackingAreaArrayGetCount( struct UITrackingAreaArray *array)
{
   return( array ? array->n : 0);
}

struct UITrackingArea   *
   UITrackingAreaArrayNewItem( struct UITrackingAreaArray *array);

void
   UITrackingAreaArrayRemoveItem( struct UITrackingAreaArray *array,
                                     struct UITrackingArea *item);


// pointer only valid, as long as nothing gets added or removed.
static inline struct UITrackingArea   *
   UITrackingAreaArrayGetItemAtIndex( struct UITrackingAreaArray *array,
                                         NSUInteger  index)
{
   assert( index < array->n);
   return( &array->items[ index]);
}

struct UITrackingArea   *
   UITrackingAreaArrayGetItemWithRect( struct UITrackingAreaArray *array,
                                          CGRect rect);
