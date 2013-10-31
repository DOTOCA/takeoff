#import "DsIdx.h"

@implementation ClassDoc

@synthesize name, path, framework;

- (NSString *)description {
	return [NSString stringWithFormat:@"<ClassDoc: %@>", name];
}


@end

#pragma mark -

@implementation DsIdx

- (id)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        LogDebug(@"Reading class index from %@", path);
		db = [[SQLite3Db alloc] initWithPath:path];
    }

    return self;
}

- (NSArray *) allClasses {

	// WTF: Tokens have a parent node that link to something like
	// documentation/Performance/Reference/vImage_types/index.html
	// BUT: "index.html" immediately redirects to something like "reference.html" (depends)
	// so you cannot link to index.html#mycoolanchor. The only way to get the actual URL is to
	// query for subchapters Overview or Tasks, because these have the correct URL:
	//
	// vImage Data Types and Constants Reference <- documentation/Performance/Reference/vImage_types/index.html <- BAD!
	//   - Overview <- documentation/Performance/Reference/vImage_types/reference.html <- GOOD!
	//
	// The wtf-join resolves this. Oh my.
	//
	// ztokentype: cl = class, intf = protocol, cat = informal protocol

    __block BOOL xcode5 = NO;
    [db executeQuery:@"select count(type) from sqlite_master where type='table' and name='ZNODEURL';" withBlock:^(sqlite3_stmt *s) {
		while(sqlite3_step(s) == SQLITE_ROW) {
            xcode5 = sqlite3_column_int(s, 0);
        }
    }];

    NSString *query = @"select ztoken.ztokenname, zheader.zframeworkname, wtf.zkpath, znode.zkpath from ztoken left join znode on ztoken.zparentnode=znode.z_pk left join ztokenmetainformation on ztokenmetainformation.ztoken=ztoken.z_pk left join zheader on ztokenmetainformation.zdeclaredin=zheader.z_pk left join zorderedsubnode on zorderedsubnode.zparent=znode.z_pk left join znode as wtf on wtf.z_pk=zorderedsubnode.znode left join ztokentype on ztoken.ztokentype=ztokentype.z_pk where wtf.zkname='Overview' and ztokentype.ztypename in ('cl', 'intf', 'cat') order by zheader.zframeworkname, ztoken.ztokenname;";
    if (xcode5) {
        // added table ZNODEURL (instead of ZNODE.ZKPATH)
        query = @"select ztoken.ztokenname, zheader.zframeworkname, wtf_url.zpath, znodeurl.zpath from ztoken left join znode on ztoken.zparentnode=znode.z_pk left join znodeurl on znodeurl.znode=znode.z_pk left join ztokenmetainformation on ztokenmetainformation.ztoken=ztoken.z_pk left join zheader on ztokenmetainformation.zdeclaredin=zheader.z_pk left join zorderedsubnode on zorderedsubnode.zparent=znode.z_pk left join znode as wtf on wtf.z_pk=zorderedsubnode.znode left join znodeurl as wtf_url on wtf_url.znode=wtf.z_pk left join ztokentype on ztoken.ztokentype=ztokentype.z_pk where wtf.zkname='Overview' and ztokentype.ztypename in ('cl', 'intf', 'cat') order by zheader.zframeworkname, ztoken.ztokenname;";
    }

	return [db executeQuery:query withRowMapper:^(sqlite3_stmt *s) {

		ClassDoc *cl = [[ClassDoc alloc] init];
		cl.name = [NSString stringWithUTF8String:(char*)sqlite3_column_text(s, 0)];

		char* zframework = (char*)sqlite3_column_text(s, 1);
		if(zframework) {
			cl.framework = [NSString stringWithUTF8String:zframework];
		}

		char* zkpath = (char*)sqlite3_column_text(s, 2);
		if(!zkpath) {
			zkpath = (char*)sqlite3_column_text(s, 3);
		}
		if(!zkpath) {
			LogDebug(@"No path for: %@", cl.name);
			return (id)nil;
		}
		cl.path = [NSString stringWithUTF8String:zkpath];

		return (id)cl;
	}];
}


@end
