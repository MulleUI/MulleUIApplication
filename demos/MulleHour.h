//
//  MulleHour.h
//  RotationIOSWidget
//
//  Created by Nat! on 01.10.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#define M_PI_f     ((float) M_PI)
#define M_PI_2f    (2.0f * M_PI_f)
#define M_PI_HALFf (M_PI_f / 2.0f)

static inline CGFloat   mulle_deg2rad( CGFloat deg)
{
   deg = fmodf( deg, 360.0);
   return( deg * M_PI_f / 180.0f);
}


static inline CGFloat   mulle_rad2deg( CGFloat rad)
{
   rad = fmodf( rad, M_PI_2f);
   return( (CGFloat) (rad * 360.0f / M_PI_2f));
}


static inline CGFloat   mulle_rad2hour( CGFloat rad)
{
   CGFloat   hour;
   
   // make sure that π * 2 and 0.0 produce equal results
   if( rad == M_PI_2f)
      rad = 0.0;

   rad += M_PI_HALFf;
   hour = rad * 12.0f / M_PI_2f;
   hour = fmodf( hour, 12.0f);
   return( hour);
}


static inline CGFloat   mulle_hour2rad( CGFloat hour)
{
   CGFloat   rad;

   // make sure that 12.0 and 0.0 produce absolutely equal results
   if( hour == 12.0)
      hour = 0.0;
   
   hour += 9.0f;
   rad   = hour * M_PI_2f / 12.0f;
   rad   = fmodf( rad, M_PI_2f);
   return( rad);
}


CGPoint  mulle_unit_circle_point_for_hour( CGFloat hour);
CGFloat  mulle_hour_for_unit_circle_point( CGPoint point);

//
// duration is elapsed time in seconds
// speed is seconds per revolution (another duration)
// hour is our angle in 0-12
//
CGFloat  mulle_hour_for_duration_and_speed( CGFloat speed, CGFloat duration);
CGFloat  mulle_duration_for_hour_and_speed( CGFloat hour, CGFloat speed);
CGFloat  mulle_speed_for_duration_and_hour( CGFloat duration, CGFloat hour);
