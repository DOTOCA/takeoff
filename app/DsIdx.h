#import <Foundation/Foundation.h>

#import "SQLite3Db.h"

@interface ClassDoc : NSObject {
}

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *framework;

@end


@interface DsIdx : NSObject {
	SQLite3Db *db;
}

- (id)initWithPath:(NSString *)path;

@property (nonatomic, readonly) NSArray *allClasses;

@end
