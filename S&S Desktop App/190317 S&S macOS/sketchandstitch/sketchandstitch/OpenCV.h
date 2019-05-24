#import <Cocoa/Cocoa.h>

@interface OpenCV : NSObject

+ (nonnull NSImage *)resize:(nonnull NSImage *)image :(double) s;

+ (nonnull NSImage *)filterByBounds:(nonnull NSImage *)image :(double) bl :(double) gl :(double) rl :(double) bh :(double) gh :(double) rh :(int) noise :(int) noiseval :(int) coloring :(int) colorSpace :(int) prenoise :(int) prenoiseval;

+ (nonnull NSImage *)whiteBackground:(nonnull NSImage *)image;

+ (nonnull NSImage *)colorImage:(nonnull NSImage *)image : (int) color : (int) b : (int) g : (int) r;

+(nonnull NSArray*)getMarkers:(nonnull NSImage*)image;

+(nonnull NSArray*)getMarkerCenter:(nonnull NSImage*)image :(int)index;

+(nonnull NSImage*)cropHoop:(nonnull NSImage*)image :(int)x :(int)y :(int)botx :(int)height :(int)topx  :(int) nightmode;

+(nonnull NSImage*)getBlackAndWhiteVersion: (nonnull NSImage*)image;

+(nonnull NSImage*)deNoise: (nonnull NSImage*)image :(int) value;
@end
