//
//  UIFont.h
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
#import "import.h"


// A UIFont is a fontNameUTF8String + fontSize (and maybe other attributes)
// the actual font will be available during rendering only as a CGFont
// that's maintained by the CGContext.
//
// Mixing emoji with roboto ? It's apparently tricky:
// https://forum.xda-developers.com/android/help/combine-2-fonts-roboto-emoji-t3501020
// Nanovg does this with the fallback font!
//

@interface UIFont : NSObject

// for the built-in fonts there will be no data or ?

@property( assign) char *   fontNameUTF8String;
@property( assign) CGFloat  pointSize;


// will be default size 12
+ (instancetype) fontWithNameUTF8String:(char *) name;

+ (instancetype) fontWithNameUTF8String:(char *) name
                                   size:(CGFloat) pointSize;

+ (instancetype) boldSystemFontOfSize:(CGFloat) pointSize;


@end

