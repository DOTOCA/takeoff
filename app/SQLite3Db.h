#import <Foundation/Foundation.h>

#import <sqlite3.h>

typedef void (^BlockWithStatement)(sqlite3_stmt *stmt);
typedef id (^RowMapper)(sqlite3_stmt *stmt);

@interface SQLite3Db : NSObject {
	sqlite3 *db;
}

- (id)initWithPath:(NSString *)path;
- (void) executeQuery:(NSString *)sql withBlock:(BlockWithStatement)block;
- (NSMutableArray *) executeQuery:(NSString *)sql withRowMapper:(RowMapper)block;

@end
