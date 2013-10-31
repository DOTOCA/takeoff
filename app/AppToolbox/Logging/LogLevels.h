#import <Foundation/Foundation.h>

#if DEBUG
#define LogDebug(log...) NSLog(log)
#else
#define LogDebug(log...) (void)0
#endif

#if TRACE
#define LogTrace(log...) NSLog(log)
#else
#define LogTrace(log...) (void)0
#endif
