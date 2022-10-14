#import "mulle-pointerarray+ObjC.h"


void   mulle_pointerarray_release_all( struct mulle_pointerarray *array)
{
   id   obj;

   mulle_pointerarray_for( array, obj)
   {
      [obj release];
   }
}


void   mulle_pointerarray_autorelease_all( struct mulle_pointerarray *array)
{
   id   obj;

   mulle_pointerarray_for( array, obj)
   {
      [obj autorelease];
   }
}


void   mulle_pointerarray_retain_all( struct mulle_pointerarray *array)
{
   id   obj;

   mulle_pointerarray_for( array, obj)
   {
      [obj retain];
   }
}


void   mulle_pointerarray_call_all( struct mulle_pointerarray *array,
                                    SEL sel,
                                    void *param)
{
   id   obj;

   mulle_pointerarray_for( array, obj)
   {
      MulleObjCObjectPerformSelector( obj, sel, param);
   }   
}



void   mulle_pointerarray_copy_all( struct mulle_pointerarray *array, id *dst)
{
   id   obj;

   mulle_pointerarray_for( array, obj)
   {
      *dst++ = obj;
   }     
}


void   mulle_pointerarray_copy_range( struct mulle_pointerarray *array,
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
