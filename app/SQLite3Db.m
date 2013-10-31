#import "SQLite3Db.h"

@implementation SQLite3Db

- (id)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
		int rc = sqlite3_open_v2([path UTF8String], &db, SQLITE_OPEN_READONLY, nil);
		if(rc) {
			sqlite3_close(db);
			[NSException raise:@"Sqlite3Error" format:@"Can't open database %@ %s", path, sqlite3_errmsg(db)];
		}

    }

    return self;
}

- (void) executeQuery:(NSString *)sql withBlock:(BlockWithStatement)block {
	sqlite3_stmt *stmt;
	NSParameterAssert(sqlite3_prepare_v2(db, [sql UTF8String], -1, &stmt, NULL) == SQLITE_OK);

	block(stmt);

	sqlite3_finalize(stmt);
}

- (NSMutableArray *) executeQuery:(NSString *)sql withRowMapper:(RowMapper)block {
	NSMutableArray *results = [NSMutableArray array];
	[self executeQuery:sql withBlock:^(sqlite3_stmt *stmt) {
		while(sqlite3_step(stmt) == SQLITE_ROW) {
			id rowObject = block(stmt);
			if (rowObject)
				[results addObject:rowObject];
		}
	}];
	return results;
}

- (void)dealloc {
	sqlite3_close(db);
}

@end
