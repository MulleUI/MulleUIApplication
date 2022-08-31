#import "mulle-pointerarray+ObjC.h"


void  mulle_pointerarray_release_all( struct mulle_pointerarray *array)
{
   struct mulle_pointerarrayenumerator   rover;
   id     obj;

   rover = mulle_pointerarray_enumerate( array);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &obj))
      [obj release];
   mulle_pointerarrayenumerator_done( &rover);
}


void  mulle_pointerarray_autorelease_all( struct mulle_pointerarray *array)
{
   struct mulle_pointerarrayenumerator   rover;
   id     obj;

   rover = mulle_pointerarray_enumerate( array);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &obj))
      [obj autorelease];
   mulle_pointerarrayenumerator_done( &rover);
}



void  mulle_pointerarray_retain_all( struct mulle_pointerarray *array)
{
   struct mulle_pointerarrayenumerator   rover;
   id     obj;

   rover = mulle_pointerarray_enumerate( array);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &obj))
      [obj retain];
   mulle_pointerarrayenumerator_done( &rover);
}


void  mulle_pointerarray_call_all( struct mulle_pointerarray *array,
                                   SEL sel,
                                   void *param)
{
   struct mulle_pointerarrayenumerator   rover;
   id     obj;

   rover = mulle_pointerarray_enumerate( array);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &obj))
      MulleObjCObjectPerformSelector( obj, sel, param);
   mulle_pointerarrayenumerator_done( &rover);
}



void  mulle_pointerarray_copy_all( struct mulle_pointerarray *array, id *dst)
{
   struct mulle_pointerarrayenumerator   rover;
   id     obj;

   rover = mulle_pointerarray_enumerate( array);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &obj))
      *dst++ = obj;
   mulle_pointerarrayenumerator_done( &rover);
}


void  mulle_pointerarray_copy_range( struct mulle_pointerarray *array,
                                     id *dst,
                                     struct mulle_range range)
{
   uintptr_t   i;
   uintptr_t   last;

   i    = range.location;
   last = range.location + range.length;
   while( i < last)
   {
      *dst++ = mulle_pointerarray_get( array, (unsigned int) i);
      ++i;
   }
}
