#ifndef demos_version_h__
#define demos_version_h__

/*
 *  version:  major, minor, patch
 */
#define DEMOS_VERSION  ((0 << 20) | (7 << 8) | 56)


static inline unsigned int   demos_get_version_major( void)
{
   return( DEMOS_VERSION >> 20);
}


static inline unsigned int   demos_get_version_minor( void)
{
   return( (DEMOS_VERSION >> 8) & 0xFFF);
}


static inline unsigned int   demos_get_version_patch( void)
{
   return( DEMOS_VERSION & 0xFF);
}

#endif
