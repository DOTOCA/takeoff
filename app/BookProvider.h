#import <Foundation/Foundation.h>

@protocol BookProvider <NSObject>

@property (readonly, nonatomic) NSArray *availableBooks;

@end
