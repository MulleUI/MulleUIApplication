#import "import.h"

void  mulle_pointerarray_autorelease_all( struct mulle_pointerarray *array);
void  mulle_pointerarray_release_all( struct mulle_pointerarray *array);
void  mulle_pointerarray_retain_all( struct mulle_pointerarray *array);
void  mulle_pointerarray_copy_all( struct mulle_pointerarray *array, id *dst);
void  mulle_pointerarray_copy_range( struct mulle_pointerarray *array,
                                     id *dst,
                                     struct mulle_range range);
void  mulle_pointerarray_call_all( struct mulle_pointerarray *array,
                                   SEL sel,
                                   void *param);