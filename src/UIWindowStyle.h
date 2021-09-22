//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#ifndef ui_window_style_h__
#define ui_window_style_h__


enum UIWindowStyleMask
{
//  UIWindowStyleClosable        = 0x1,
//  UIWindowStyleMiniaturizable  = 0x2,
  UIWindowStyleResizable             = 0x4,
  UIWindowStyleInvisible             = 0x8,
  UIWindowStyleNoEdgeAntialias       = 0x10,  // nanvg
  UIWindowStyleNoStencilStrokes      = 0x20,  // nanovg
  UIWindowStyleRenderNonRetainedOnly = 0x40   // backbuffer is always UIWindowBackingStoreNonRetained
};

typedef NSUInteger   UIWindowStyleMask;


enum UIWindowBackingStoreType  
{
   UIWindowBackingStoreBuffered,        // safe default
   UIWindowBackingStoreNonRetained
};

typedef NSUInteger   UIWindowBackingStoreType;

#endif
