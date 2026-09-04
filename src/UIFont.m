//
//  UIFont.m
//  MulleUIApplication
//
//  Copyright (c) 2020 Nat! - Mulle kybernetiK.
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
#define _GNU_SOURCE // for strrchr
#import "UIFont.h"


@implementation UIFont


+ (instancetype) fontWithNameUTF8String:(char *) name
{
   return( [self fontWithNameUTF8String:name
                                   size:12.0]);
}


+ (instancetype) fontWithNameUTF8String:(char *) name
                                   size:(CGFloat) pointSize
{
   UIFont   *font;

   font = [self alloc];
   font = [font init];
   font = [font autorelease];
   [font setFontNameUTF8String:name];
   [font setPointSize:pointSize];
   return( font);
}


+ (instancetype) boldSystemFontOfSize:(CGFloat) pointSize
{
   return( [self fontWithNameUTF8String:"sans"
                                   size:pointSize]);
}


- (void) dealloc
{
   struct mulle_allocator  *allocator;

   allocator = MulleObjCInstanceGetAllocator( self);
   mulle_allocator_free( allocator, _fontNameUTF8String);
   [super dealloc];
}


- (void) setFontNameUTF8String:(char *) s
{
   MulleObjCObjectSetDuplicatedUTF8String( self, &_fontNameUTF8String, s);
}

@end
