#import "UITrackingArea.h"

#import "import-private.h"


# pragma mark - struct UITrackingAreaArray

void
   UITrackingAreaArrayInit( struct UITrackingAreaArray *array,
                               struct mulle_allocator *allocator)
{
   assert( array);

   array->size      = 0;
   array->n         = 0;
   array->allocator = allocator;
   array->items     = NULL;
}


static void
   UITrackingAreaDoneItems( struct UITrackingAreaArray *array)
{
   struct UITrackingArea   *p;
   struct UITrackingArea   *sentinel;

   assert( array);

   p        = array->items;
   sentinel = &p[ array->n];
   while( p < sentinel)
   {
      UITrackingAreaDone( p);
      ++p;
   }
}


void
   UITrackingAreaArrayDone( struct UITrackingAreaArray *array)
{
   assert( array);

   UITrackingAreaDoneItems( array);
   mulle_allocator_free( array->allocator, array->items);

   // this is important
   array->items = NULL;
   array->n     = 0;
   array->size  = 0;
}


struct UITrackingArea   *
   UITrackingAreaArrayNewItem( struct UITrackingAreaArray *array)
{
   struct UITrackingArea   *p;

   assert( array);

   if( array->n == array->size)
   {
      array->size += array->size;
      if( array->size < 4)
         array->size = 4;

      array->items = mulle_allocator_realloc( array->allocator,
                                              array->items,
                                              sizeof( struct UITrackingArea) * array->size);
   }

   p = &array->items[ array->n++];
   memset( p, 0, sizeof( struct UITrackingArea));
   return( p);
}


struct UITrackingArea *
   UITrackingAreaArrayGetItemWithRect( struct UITrackingAreaArray *array,
                                          CGRect rect)
{
   struct UITrackingArea   *p;
   struct UITrackingArea   *sentinel;

   assert( array);

   p        = &array->items[ 0];
   sentinel = &array->items[ array->n];

   while( p < sentinel)
   {
      if( CGRectEqualToRect( UITrackingAreaGetRect( p), rect))
      {
         return( p);
      }
      ++p;
   }
   return( NULL);
}



void
   UITrackingAreaArrayRemoveItem( struct UITrackingAreaArray *array,
                                     struct UITrackingArea *item)
{
   ptrdiff_t   index;
   int         tocopy;

   if( ! item)
      return;

   assert( array);

   index = item - array->items;
   assert( index >= 0 && index < array->n);

   UITrackingAreaDone( item);

   //
   // assume: 4 entries (0,1,2,3), removing entry 2, have to compact 1 from behind
   //
   tocopy = array->n - index - 1;      // 4 - 2 - 1 = 2
   if( tocopy > 0)
   {
      memmove( &array->items[ index],
               &array->items[ index + 1],
               tocopy * sizeof( struct UITrackingArea));
   }
   --array->n;
}



