#import "UIView+CAAnimation.h"

#import "import-private.h"



@implementation UIView ( CAAnimation)


+ (void) beginAnimations:(char *) animationID
                 context:(void *) context
{
   CATransaction   *transaction;

   transaction = [CATransaction new];

   [transaction setAnimationID:animationID];
   [transaction setContext:context];
   [transaction setAnimationDuration:2.0];
   [transaction setAnimationRepeatCount:1.0];
   [transaction setAnimationCurve:UIViewAnimationCurveEaseInOut];
   [transaction begin];
}


+ (void) commitAnimations
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   [transaction commit];
   [transaction autorelease];
}



+ (BOOL) areAnimationsEnabled
{
   return( UIViewAreAnimationsEnabled());
}


+ (void) addAnimatableObject:(id <CAImplicitlyAnimatableObject>) layer
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   [transaction addAnimatableObject:layer];
}

/* "properties" */


+ (id) animationDelegate
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   return( [transaction animationDelegate]);
}


+ (SEL) animationDidStopSelector
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   return( [transaction animationDidStopSelector]);
}


+ (SEL) animationWillStartSelector
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   return( [transaction animationWillStartSelector]);
}


+ (void) setAnimationDelegate:(id) value
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   [transaction setAnimationDelegate:value];
}


+ (void) setAnimationDidStopSelector:(SEL) value
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   [transaction setAnimationDidStopSelector:value];
}


+ (void) setAnimationWillStartSelector:(SEL) value
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   [transaction setAnimationWillStartSelector:value];
}



//
+ (CARelativeTime) animationDelay
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   return( [transaction animationDelay]);
}


+ (void) setAnimationDelay:(CARelativeTime) delay
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   [transaction setAnimationDelay:delay];
}



+ (CARelativeTime) animationDuration
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   return( [transaction animationDuration]);
}


+ (void) setAnimationDuration:(CARelativeTime) duration
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   [transaction setAnimationDelay:duration];
}


+ (NSUInteger) animationCurve
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   return( [transaction animationCurve]);
}


+ (void) setAnimationCurve:(NSUInteger) value
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);

   [transaction setAnimationCurve:value];
}


+ (CATweenFunction *) animationTweenFunction
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   return( [transaction animationTweenFunction]);
}


+ (void) setAnimationTweenFunction:(CATweenFunction *) tween
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   [transaction setAnimationTweenFunction:tween];   
}


+ (BOOL) animationRepeatAutoreverses
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   return( [transaction animationAutoreverses]);
}


+ (void) setAnimationRepeatAutoreverses:(BOOL) flag
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   [transaction setAnimationAutoreverses:flag];
}


+ (BOOL) animationAutoreverses
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   return( [transaction animationAutoreverses]);
}


+ (void) setAnimationAutoreverses:(BOOL) flag
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   [transaction setAnimationAutoreverses:flag];
}


// incompatible
+ (float) animationRepeatCount
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   return( [transaction animationRepeatCount]);
}


+ (void) setAnimationRepeatCount:(float) value
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   [transaction setAnimationRepeatCount:value];
}


// incompatible
+ (BOOL) mulleAnimationRepeats
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   return( [transaction animationRepeatCount] >= 1.0);
}


+ (void) mulleSetAnimationRepeats:(BOOL) flag
{
   CATransaction   *transaction;

   transaction = CATransactionGetCurrentTransaction();
   assert( transaction);
   [transaction setAnimationRepeatCount:flag ? INFINITY : 0.0];
}

@end
