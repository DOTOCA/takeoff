#import "Entry.h"

#import "Book.h"
#import "URLMapping.h"
#import "Foundation+Additions.h"

#define KEY_TITLE          @"title"
#define KEY_URL            @"url"
#define KEY_ENTRIES        @"entries"
#define KEY_ICON           @"icon"

@implementation Entry

@synthesize parent, entries, icon, title, url, match, filteredEntries, ranking;

NSArray *EMPTY_ARRAY = nil;

+ (void) initialize {
	if(self == [Entry class]) {
		EMPTY_ARRAY = [NSArray new];
	}
}

- (id) init {
    self = [super init];
    if (self) {
		entries = EMPTY_ARRAY;
		filteredEntries = EMPTY_ARRAY;
		match = YES;
    }
    return self;
}

- (id) initWithParent:(Entry *)aParent {
    self = [self init];
    if (self) {
		if (aParent) {
			self.parent = aParent;
		}
    }
    return self;
}

- (void) setParent:(Entry *)entry {
	// remove from old parent
	if (parent) {
		parent.entries = [parent.entries arrayByRemovingObject:self];
	}

	// update field
	parent = entry; // weak

	// add to new parent
	parent.entries = [parent.entries arrayByAddingObject:self];
}

- (id) initWithDictionary:(NSDictionary *)aDictionary parent:(Entry *)aParent {
    self = [self initWithParent:aParent];
    if (self) {
		self.icon = [aDictionary objectForKey:KEY_ICON];
		self.title = [aDictionary objectForKey:KEY_TITLE];
		self.url = [aDictionary objectForKey:KEY_URL];

		NSArray *entryDictList = [aDictionary objectForKey:KEY_ENTRIES];
		if (entryDictList && [entryDictList count]>0) {
			for(id item in entryDictList) {
				[[Entry alloc] initWithDictionary:item parent:self];
			}
		}
		filteredEntries = entries ? entries : EMPTY_ARRAY;
    }
    return self;
}

- (void) setPropertiesFromLineString:(NSString *)line {
	if ([line hasPrefix:@"["]) {
		NSRange end = [line rangeOfString:@"]"];
		self.icon = [line substringWithRange:NSMakeRange(1, end.location - 1)];
		line = [line substringFromIndex:end.location + 2];
	}
	NSArray *parts = [line componentsSeparatedByString:@"=>"];
	self.title = [[parts objectAtIndex:0] trim];
	if ([parts count] > 1) {
		self.url = [[parts objectAtIndex:1] trim];
	}
}

+ (Entry *) parseDebugString:(NSString *)string {
	Entry *root = nil;
	Entry *entry = nil;

	NSArray *lines = [string componentsSeparatedByString:@"\n"];

	for (__strong NSString *line in lines) {
		int lineIndent = 0;
		while([line hasPrefix:@"\t"]) {
			line = [line substringFromIndex:1];
			lineIndent++;
		}

		while(lineIndent < entry.level) {
			entry = entry.parent;
		}

		if (lineIndent == 0 && entry == nil) {
			root = entry = [self new];
		}
		else if (lineIndent == entry.level) {
			entry = [[Entry alloc] initWithParent:entry.parent];
		}
		else if (lineIndent == entry.level + 1) {
			entry = [[Entry alloc] initWithParent:entry];
		}
		else
			NSAssert(NO, @"Invalid indentation");

		[entry setPropertiesFromLineString:line];
	}
	[root filter:nil];
    return root;
}

+ (Entry *) entryWithDictionary:(NSDictionary *)aDictionary {
	return [[Entry alloc] initWithDictionary:aDictionary parent:nil];
}

+ (Entry *) entryWithParent:(Entry *)parent {
	return [[Entry alloc] initWithParent:parent];
}

+ (Entry *) entryWithParent:(Entry *)parent title:(NSString *)title {
	Entry *entry = [Entry entryWithParent:parent];
	entry.title = title;
	return entry;
}

- (Entry *) entryForTitlePathComponents:(NSArray *)path {
	NSString *pathPart = [path objectAtIndex:0];

	for(Entry *child in entries) {
		if ([child.title isEqualTo:pathPart]) {
			if (path.count == 1) {
				return child;
			} else {
				Entry *result = [child entryForTitlePathComponents:[path subarrayWithRange:NSMakeRange(1, path.count - 1)]];
				if (result)
					return result;
			}

		}
	}

	return nil;
}

- (Entry *) entryForTitlePath:(NSString *)path {
	return [self entryForTitlePathComponents:path.pathComponents];
}

- (Entry*) findDepthFirst:(NSPredicate *)predicate filtered:(BOOL)filtered {
	for(Entry *entry in (filteredEntries && filtered ? filteredEntries : entries)) {
		if([predicate evaluateWithObject:entry]) {
			return entry;
		}
		Entry *result = [entry findDepthFirst:predicate filtered:filtered];
		if (result)
			return result;
	}
	return nil;
}

- (Entry*) entryForAbsoluteURL:(NSURL *)findURL {
	if(findURL.fragment) {
		NSURL *urlWithoutFragment = [findURL URLByRemovingFragment];
		// if there is an entry with a matching fragment, we want to get it
		// if there is no such entry, one without a matching fragment does as well
		__block Entry *matchWithoutFragment = nil;
		Entry *matchWithFragment = [self findDepthFirst:[NSPredicate predicateWithBlock:^(Entry *entry, NSDictionary *bindings){
			NSURL *entryURL = entry.absoluteURL;
			if ([[entryURL URLByRemovingFragment] isEqualTo:urlWithoutFragment]) {
				if (!matchWithoutFragment) {
					matchWithoutFragment = entry;
				}
				return [entryURL isEqualTo:findURL];
			}
			return NO;
		}] filtered:NO];
		return matchWithFragment ? matchWithFragment : matchWithoutFragment;
	}

	return [self findDepthFirst:[NSPredicate predicateWithFormat:@"absoluteURL=%@", findURL] filtered:NO];
}

- (Book *) book {
	return parent.book;
}

- (Entry *) drillUp:(BOOL(^)(Entry *entry))block includeSelf:(BOOL)includeSelf {
	Entry *p = includeSelf ? self : self.parent;
	while(p != nil) {
		if(block(p))
			return p;
		p = p.parent;
	}

	return nil;
}

- (void) setUrl:(NSString *)newUrl {
	url = newUrl;
	absoluteURL = nil;
}

- (NSURL *) computeAbsoluteURL {
	if (!url)
		return nil;

	if ([url rangeOfString:@"://"].location != NSNotFound) {
		return [NSURL URLWithString:url];
	}

	Entry *upEntryWithUrl = [self drillUp:^(Entry *e){ return (BOOL)(e->url!=nil); } includeSelf:NO];

	if ([url hasPrefix:@"#"]) {
		return [NSURL URLWithString:[[upEntryWithUrl.absoluteURL URLByRemovingFragment].absoluteString stringByAppendingString:url]];
	}

	if (upEntryWithUrl)
		return [[NSURL URLWithString:url relativeToURL:upEntryWithUrl.absoluteURL] absoluteURL];
	else
		return [self.book.storage URLForPath:url];
}

- (NSURL *) absoluteURL {
	if (!absoluteURL)
		absoluteURL = [self computeAbsoluteURL];

	return absoluteURL;
}

- (NSString *) titlePath {
	return [[self.path map:^(Entry *entry){ return entry.title ? entry.title : @""; }] componentsJoinedByString:@"/"];
}

- (NSString *) debugStringDepth:(int)depth mapper:(EntryToStringMapping)mapper {
	NSString *chString = (filteredEntries ? [[filteredEntries map:^(Entry *e){ return [e debugStringDepth:depth+1 mapper:mapper]; }] componentsJoinedByString:@"\n"] : @"");
	if ([chString length] > 0)
		 chString = [NSString stringWithFormat:@"\n%@", chString];
	return [NSString stringWithFormat:@"%@%@%@", [@"\t" times:depth], mapper(self), chString];
}

- (NSString *) debugString {
	return [self debugStringDepth:0 mapper:^(Entry *entry){
		NSString *text = entry.title;
		if (entry.icon) {
			text = [NSString stringWithFormat:@"[%@] %@", entry.icon, text];
		}
		if (entry.url) {
			text = [NSString stringWithFormat:@"%@ => %@", text, entry.url];
		}
		return text;
	}];
}

- (NSString *) debugString:(EntryToStringMapping)mapper {
	return [self debugStringDepth:0 mapper:mapper];
}

- (NSString *) debugRankingString {
	return [self debugString:^(Entry *entry){ return [NSString stringWithFormat:@"%@ => %.2f", entry.title, entry.ranking]; }];
}

- (NSArray *) path {
	NSMutableArray *path = [NSMutableArray array];

	[self drillUp:^(Entry *entry){
		[path insertObject:entry atIndex:0];
		return NO;
	} includeSelf:YES];

	return path;
}

- (NSUInteger) titlePathLength {
	if(!parent)
		return title.length;
	else
		return parent.titlePathLength + title.length;
}

- (NSMutableDictionary *) dictionary {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setValue:title forKey:KEY_TITLE];
	[dict setValue:url forKey:KEY_URL];
	if (icon)
		[dict setValue:icon forKey:KEY_ICON];
	if (entries)
		[dict setValue:[entries map:^(id node){ return (id)[node dictionary]; }] forKey:KEY_ENTRIES];
	return dict;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"<Entry: %@>", [self titlePath]];
}

- (int) level {
	__block int level = 0;
	[self drillUp:^(Entry *entry){ level++; return NO; } includeSelf:NO];
	return level;
}

- (void) setFilterIncludeAllEntries {
	match = YES;
	if (!entries || [entries count]==0) {
		filteredEntries = EMPTY_ARRAY;
	} else {
		filteredEntries = entries;
		for(Entry *e in entries) {
			[e setFilterIncludeAllEntries];
		}
	}
}

- (void) sortEntriesByTitle {
	// copying to avoid changing an object thats enumerated
	self.entries = [self.entries sortedArrayUsingComparator:(NSComparator)^(Entry *obj1, Entry* obj2){
		return [obj1.title localizedCaseInsensitiveCompare:obj2.title];
	}];
}

- (void) setRanking:(float)r {
	ranking = r;
	r *= 0.9;
	if (parent && r > parent.ranking) {
		parent.ranking = r;
	}
}

- (void) setFilterTerms:(NSSet *)filterTerms termLength:(NSUInteger)termLength {
	match = YES;

	NSSet *childrenFilterTerms = filterTerms;

	int matchLength = 0;
	for(NSString *term in filterTerms) {
		NSRange termRange = [title rangeOfString:term options:NSLiteralSearch | NSCaseInsensitiveSearch];
		BOOL termMatch = title && termRange.location != NSNotFound;
		if (termMatch) {
			matchLength += termRange.length;
			if (childrenFilterTerms == filterTerms) {
				childrenFilterTerms = [NSMutableSet setWithSet:filterTerms];
			}
			[(NSMutableSet*)childrenFilterTerms removeObject:term];
		}
		match &= termMatch;
	}

	self.ranking = match ? termLength / (float)self.titlePathLength : 0;

	if (match && parent) {
		[self setFilterIncludeAllEntries];
		return;
	}

	if (!entries || [entries count]==0) {
		filteredEntries = EMPTY_ARRAY;
	} else {
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_apply([entries count], queue, ^(size_t index){
			[[entries objectAtIndex:index] setFilterTerms:childrenFilterTerms termLength:termLength];
		});

		NSArray *newFilteredEntries = [entries filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Entry *entry, NSDictionary *bindings) {
			return (entry.match || entry.filteredEntries.count>0);
		}]];

		if (newFilteredEntries.count == 0) {
			newFilteredEntries = EMPTY_ARRAY;
		} else {
			NSMutableArray *mutableFilteredEntries = [NSMutableArray arrayWithArray:newFilteredEntries];

			[mutableFilteredEntries sortUsingComparator:^(Entry *obj1, Entry *obj2) {
				NSComparisonResult result = NSOrderedSame;
				if (obj1.ranking > obj2.ranking) result = NSOrderedAscending;
				if (obj1.ranking < obj2.ranking) result = NSOrderedDescending;
				return result;
			}];
			// show 1-3 top hits as long as they are very closely in ranking to the top hit, rest
			// gets alphabetically sorted
			if ([mutableFilteredEntries count] > 1) {
				int i = 1;
				NSUInteger maxi = [mutableFilteredEntries count];
				if (maxi>4)
					maxi = 4;
				for(; i < maxi; i++) {
					if(((Entry*)[mutableFilteredEntries objectAtIndex:i]).ranking < ((Entry*)[mutableFilteredEntries objectAtIndex:0]).ranking - 0.05)
						break;
				}

				NSRange restRange = NSMakeRange(i, mutableFilteredEntries.count - i);
				NSArray *rest = [mutableFilteredEntries subarrayWithRange:restRange];
				[mutableFilteredEntries removeObjectsInRange:restRange];
				[mutableFilteredEntries addObjectsFromArray:[rest sortedArrayUsingComparator:(NSComparator)^(Entry *obj1, Entry* obj2){
					return [obj1.title localizedCaseInsensitiveCompare:obj2.title];
				}]];
			}
			newFilteredEntries = [NSArray arrayWithArray:mutableFilteredEntries];
		}
		self.filteredEntries = newFilteredEntries;
	}

	LogTrace(@"refilter:%@ match:%i filterTerm:%@ => filteredEntries:%@", self, self.match, filterTerms, filteredEntries);
}

- (void) filter:(NSString *)newFilterTerm {
	newFilterTerm = [newFilterTerm trim];
	if (!newFilterTerm || [newFilterTerm length] == 0) {
		[self setFilterIncludeAllEntries];
	} else {
		NSSet *newFilterTerms = [NSSet setWithArray:[newFilterTerm componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
		[self setFilterTerms:newFilterTerms termLength:newFilterTerm.length];
	}
}

@end
