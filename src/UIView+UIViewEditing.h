#import "UIView.h"



@interface UIView( UIViewEditing)

- (BOOL) isDescendantOfView:(UIView *) view;

- (void) sendSubviewToBack:(UIView *) view;
- (void) bringSubviewToFront:(UIView *) view;
- (void) removeFromSuperview;

- (void) insertSubview:(UIView *) view
               atIndex:(NSInteger) index;
- (void) insertSubview:(UIView *) view
          aboveSubview:(UIView *) other;
- (void) insertSubview:(UIView *) view
          belowSubview:(UIView *) other;
- (void) exchangeSubviewAtIndex:(NSInteger) index1
             withSubviewAtIndex:(NSInteger) index2;

@end

