#import <Foundation/Foundation.h>

#import "Book.h"

@interface TakeoffFileDownload : Book {
	NSString *downloadUrl;
	NSMutableData *downloadedData;
	double filesize;
	BOOL done;
	id<ProgressHandler>progress;
}



@end
