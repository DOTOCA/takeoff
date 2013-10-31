#import <Foundation/Foundation.h>

#import <sqlite3.h>
#import "Book.h"

@interface DocSet : Book {
}

@property (nonatomic, strong) NSPredicate *classDocPredicate;

- (id) initWithDocSetPath:(NSString *)pDocsetPath;

@end
