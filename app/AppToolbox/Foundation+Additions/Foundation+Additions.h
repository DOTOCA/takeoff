#import <Foundation/Foundation.h>

@interface NSArray (Additions)

- (NSArray *)map:(id (^)(id object))block;
- (NSArray *)select:(BOOL (^)(id object))block;
- (id)find:(BOOL (^)(id object))block;
- (id)last:(BOOL (^)(id object))block;
- (NSArray *)arrayByRemovingObject:(id)anObject;

@end


@interface NSString (Additions)

- (NSString *) times:(int)times;
- (NSString *) trim;

@end


@interface NSURL (Additions)

- (NSURL *) URLByRemovingFragment;

@end
