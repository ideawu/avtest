//
//  VideoEncoder.m
//  Encoder Demo
//
//  Created by Geraint Davies on 14/01/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "VideoEncoder.h"

@implementation VideoEncoder

@synthesize path = _path;

+ (VideoEncoder*) encoderForPath:(NSString*) path Height:(int) height andWidth:(int) width
{
    VideoEncoder* enc = [VideoEncoder alloc];
    [enc initPath:path Height:height andWidth:width];
    return enc;
}


- (void) initPath:(NSString*)path Height:(int) height andWidth:(int) width
{
    self.path = path;
	_bitrate = 44100.0;
    
    [[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
    NSURL* url = [NSURL fileURLWithPath:self.path];
	
	NSLog(@"encoder %@", url.absoluteString);
    _writer = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeMPEG4 error:nil];
	//_writer = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeMPEG4 error:nil];
	NSDictionary* settings;
	settings = @{
				 AVVideoCodecKey: AVVideoCodecH264,
				 AVVideoWidthKey: @(width),
				 AVVideoHeightKey: @(height),
				 AVVideoCompressionPropertiesKey: @{
						 AVVideoAverageBitRateKey: @(_bitrate),
						 AVVideoMaxKeyFrameIntervalKey: @(150),
						 AVVideoAllowFrameReorderingKey: @YES,
						 AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel,
						 },
				 // belows require OS X 10.10+
				 //AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCAVLC,
				 //AVVideoExpectedSourceFrameRateKey: @(30),
				 //AVVideoAllowFrameReorderingKey: @NO,
				 };
#if TARGET_OS_MAC
#ifdef NSFoundationVersionNumber10_9_2
	if(NSFoundationVersionNumber <= NSFoundationVersionNumber10_9_2){
//		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:settings];
//		// AVVideoCodecH264 not working right with OS X 10.9-
//		[dict setObject:AVVideoCodecJPEG forKey:AVVideoCodecKey];
//		settings = dict;
	}
#endif
#endif
    _writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
    _writerInput.expectsMediaDataInRealTime = YES;
    [_writer addInput:_writerInput];
}

- (void) finishWithCompletionHandler:(void (^)(void))handler
{
    [_writer finishWritingWithCompletionHandler: handler];
}

- (BOOL) encodeFrame:(CMSampleBufferRef) sampleBuffer
{
    if (CMSampleBufferDataIsReady(sampleBuffer))
    {
        if (_writer.status == AVAssetWriterStatusUnknown)
        {
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            [_writer startWriting];
            [_writer startSessionAtSourceTime:startTime];
        }
        if (_writer.status == AVAssetWriterStatusFailed)
        {
            NSLog(@"writer error %@", _writer.error.localizedDescription);
            return NO;
        }
        if (_writerInput.readyForMoreMediaData == YES)
        {
            [_writerInput appendSampleBuffer:sampleBuffer];
            return YES;
        }
    }
    return NO;
}

@end
