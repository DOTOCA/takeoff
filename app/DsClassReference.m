#import "DsClassReference.h"

@implementation DsClassReference

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
		NSError *error;
		NSString *str = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];

		if(str) {
            doc = [[NSXMLDocument alloc] initWithXMLString:str options:NSXMLDocumentTidyHTML error:&error];
			NSAssert(doc, @"Error parsing %@: %@", url, error);
		} else {
			LogDebug(@"DsClassReference Document %@ not found", url);
		}
    }

    return self;
}

- (NSString *) framework {
	for(NSXMLElement *e in [doc nodesForXPath:@"//*[@class='FrameworkPath']/ancestor::tr//a" error:nil]) {
		return [e.stringValue stringByDeletingPathExtension];
	}
	return nil;
}

- (Entry *) tasks {
	Entry *tasks = nil;
	Entry *parent = nil;
	NSCharacterSet *trimChars = [NSCharacterSet characterSetWithCharactersInString:@"+–  \n\t"];

	for(NSXMLElement *e in [doc nodesForXPath:@"//*[@id='Tasks_section']//a" error:nil]) {
		NSString *nameAttr = [[[e attributeForName:@"name"] stringValue] stringByTrimmingCharactersInSet:trimChars];
		NSString *titleAttr = [[[e attributeForName:@"title"] stringValue] stringByTrimmingCharactersInSet:trimChars];
		NSString *text = [e.stringValue stringByTrimmingCharactersInSet:trimChars];
		if (!tasks) {
			parent = tasks = [Entry entryWithParent:nil title:titleAttr];
		} else if (nameAttr && titleAttr && titleAttr.length>0) {
			parent = [Entry entryWithParent:tasks title:titleAttr];
			parent.icon = @"i";
		} else if (text && text.length > 0) {
			NSAssert(parent, @"parent");
			Entry* entry = [Entry entryWithParent:parent title:text];
			entry.url = [[e attributeForName:@"href"] stringValue];
			entry.icon = @"m";
		} else {
			LogDebug(@"Ignored %@", e);
		}
	}

	[tasks filter:nil];
	return tasks;
}

@end
