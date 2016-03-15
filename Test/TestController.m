//
//  TestController.m
//  irtc
//
//  Created by ideawu on 16-3-5.
//  Copyright (c) 2016年 ideawu. All rights reserved.
//

#import "TestController.h"
#import <AVFoundation/AVFoundation.h>
#import "LiveRecorder.h"
#import "VideoPlayer.h"
#import "AudioPlayer.h"
#import "AudioDecoder.h"
#import "VideoDecoder.h"
#import "VideoEncoder.h"
#import "VideoReader.h"

@interface TestController (){
	CALayer *_videoLayer;
	LiveRecorder *_recorder;
	VideoPlayer *_player;
	AudioPlayer *_audioPlayer;
	AudioDecoder *_audioDecoder;
	VideoDecoder *_decoder;
	VideoEncoder *_encoder;

}
@property int num;
@end

@implementation TestController

// CVImageBufferRef 即是 CVPixelBufferRef
- (CGImageRef)pixelBufferToImageRef:(CVImageBufferRef)imageBuffer{
	CVPixelBufferLockBaseAddress(imageBuffer, 0);
	uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
	size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
	size_t width = CVPixelBufferGetWidth(imageBuffer);
	size_t height = CVPixelBufferGetHeight(imageBuffer);

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(baseAddress,
												 width, height,
												 8, bytesPerRow,
												 colorSpace,
												 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst
												 );
	CGImageRef image = NULL;
	if(context){
		image = CGBitmapContextCreateImage(context);
	}
	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
	return image;
}

- (void)windowDidLoad {
    [super windowDidLoad];

	_videoLayer = [[CALayer alloc] init];
	_videoLayer.frame = self.videoView.bounds;
	_videoLayer.bounds = self.videoView.bounds;

	[[self.videoView layer] addSublayer:_videoLayer];
	_videoView.layer.backgroundColor = [NSColor blackColor].CGColor;


//	__weak typeof(self) me = self;

	_recorder = [[LiveRecorder alloc] init];
	_recorder.clipDuration = 0.2;
	//_recorder.bitrate = 800 * 1024;

	_player = [[VideoPlayer alloc] init];
	_player.layer = _videoLayer;
	[_player play];

	[_recorder setupVideo:^(VideoClip *clip) {
		NSData *data = clip.stream;
		NSLog(@"%2d frames[%.3f ~ %.3f], duration: %.3f, %5d bytes, key_frame: %@",
			  clip.frameCount, clip.startTime, clip.endTime, clip.duration, (int)data.length,
			  clip.hasKeyFrame?@"yes":@"no");
		if(_num ++ < 3){
//			return;
		}

		VideoClip *c = [[VideoClip alloc] init];
		[c parseStream:data];
		
		[_player addClip:c];
	}];

//	int raw_format = 1;
//	if(raw_format){
//		_audioPlayer = [[AudioPlayer alloc] init];
//		[_audioPlayer setSampleRate:44100 channels:2];
//	}else{
//		_audioPlayer = [AudioPlayer AACPlayerWithSampleRate:44100 channels:2];
//	}
//
//	_audioDecoder = [[AudioDecoder alloc] init];
//	[_audioDecoder start:^(NSData *pcm, double duration) {
//		[_audioPlayer appendData:pcm];
//	}];
//
//	[_recorder setupAudio:^(NSData *data, double pts, double duration) {
//		int i = [me incr];
//		if(i > 130 && i < 350){
//			//NSLog(@"return %d", i);
//			return;
//		}
//		NSLog(@"%d bytes, %f %f", (int)data.length, pts, duration);
//		if(raw_format){
//			[_audioDecoder decode:data];
//		}else{
//			[_audioPlayer appendData:data];
//		}
//	}];

	[_recorder start];
}

- (void)stop{
	log_debug(@"stop");
	[_recorder stop];
}

- (int)incr{
	static int i = 0;
	return i++;
}

@end
