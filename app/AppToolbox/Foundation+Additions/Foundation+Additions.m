#import "Foundation+Additions.h"

@implementation NSArray (Additions)

- (NSArray *)map:(id (^)(id object))block {
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
	for(id obj in self) {
		[result addObject:block(obj)];
	}

	return [NSArray arrayWithArray:result];
}

- (NSArray *)select:(BOOL (^)(id object))block {
	return [self filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^(id evaluatedObject, NSDictionary *bindings) {
		return block(evaluatedObject);
	}]];
}

- (NSArray *)find:(BOOL (^)(id object))block {
	for(id obj in self) {
		if (block(obj)) {
			return obj;
		}
	}
	return nil;
}

- (NSArray *)last:(BOOL (^)(id object))block {
	for(id obj in self.reverseObjectEnumerator) {
		if (block(obj)) {
			return obj;
		}
	}
	return nil;
}

- (NSArray *)arrayByRemovingObject:(id)anObject {
	NSParameterAssert(anObject);
    NSMutableArray* newArray = [NSMutableArray arrayWithArray:self];
    [newArray removeObject:anObject];
    return [NSArray arrayWithArray:newArray];
}

@end

@implementation NSString (Additions)

- (NSString *) times:(int)times {
	NSMutableString *result = [NSMutableString stringWithCapacity:self.length * times];

	for (int i = 0; i < times; i++) {
		[result appendString:self];
	}

	return [NSString stringWithString:result];
}

- (NSString *) trim {
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end

@implementation NSURL (Additions)

- (NSURL *) URLByRemovingFragment {
    NSString *urlString = [self absoluteString];
    NSRange fragmentRange = [urlString rangeOfString:@"#" options:NSBackwardsSearch];
    if (fragmentRange.location != NSNotFound) {
        NSString* newURLString = [urlString substringToIndex:fragmentRange.location];
        return [NSURL URLWithString:newURLString];
    } else {
        return self;
    }
}

@end
