## 0.1.0




feature: add OS window graphics capability resolution

* new `effectiveWindowStyleMask:graphicsHints:` class method on the UIOSWindow protocol lets callers resolve which style bits a backend can honor before creating a window; the returned mask is binding
* new `osGraphicsContextClass` method lets an OS window report the concrete UIGraphicsContext subclass it needs
* `UIApplicationRunWindow()` global function removed in favor of `-runWindow:` — **BREAKING**


### 0.0.1

Various small improvements
