# 🎵 MulleUIBase

#### 🎵 MulleUIBase provides abstract classes like UIApplication and UIEvent





### You are here

There is no actual "drawing" code in MulleUIBase. Use "MulleGraphics" for
drawing. See "MulleUIControl" for widgets.


```
  .-----------------------------------------.
  | MulleUIFoundation                       |
  '-----------------------------------------'
  .-----------------------------------------.
  | MulleUIControl                          |
  '-----------------------------------------'
  .-----------------. .=====================.
  | MulleUIImage    | | MulleUIBase         |
  '-----------------' '==============.======.
  .--------------------------------. | glfw |
  | MulleGraphics                  | | X11  |
  '--------------------------------' '------'
  .-----------------. .------------.
  | MulleCG         | | MulleCA    |
  '-----------------' '------------'
  .--------------------------------.
  | MulleLayout                    |
  '--------------------------------'
```

MulleUIBase is only based on [MulleObjCLockFoundation](//github.com/MulleFoundation/MulleObjCFoundation). Foundation datatypes like `NSString` are not available.
