//
//  MulleHour.m
//  RotationIOSWidget
//
//  Created by Nat! on 01.10.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import "MulleHour.h"


CGPoint  mulle_unit_circle_point_for_hour( CGFloat hour)
{
   CGFloat   radians;
   CGPoint   point;
   
   radians  = mulle_hour2rad( hour);
   
   point.x = cosf( radians);
   point.y = sinf( radians);
   
   return( point);
}


CGFloat  mulle_hour_for_unit_circle_point( CGPoint point)
{
   CGFloat   hour;
   CGFloat   radians;
   int       minus;
   
   radians = asinf( point.y);
   if( isnan( radians))
   {
      radians = acoshf( point.x);
      if( isnan( radians))
         radians = (float) -M_PI / 2.0f;
   }
   
   minus = point.x < 0;
   if( minus)
      radians = -radians + (float) M_PI;
   
   hour = mulle_rad2hour( radians);
   
   return( hour);
}


CGFloat  mulle_hour_for_duration_and_speed( CGFloat speed, CGFloat duration)
{
   CGFloat   hour;
   
   if( speed == 0.0)
      return( 0.0);
   
   hour = duration * 12.0f / speed;  // h = d / s * 12;
   return( fmodf( hour, 12));
}


CGFloat  mulle_duration_for_hour_and_speed( CGFloat hour, CGFloat speed)
{
   return( speed * hour / 12.0f);  // d = s * h / 12.0
}



CGFloat  mulle_speed_for_duration_and_hour( CGFloat duration, CGFloat hour)
{
   if( hour == 0.0)
      return( 0.0);
   return( duration * 12.0f / hour);    // s = d * 12.0 / h;
}
