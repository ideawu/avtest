//
//  ViewController.m
//  recorder
//
//  Created by ideawu on 16-2-28.
//  Copyright (c) 2016年 ideawu. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>

#import "ViewController.h"
#import "LiveRecorder.h"
#import "IKit/IKit.h"
#import "IObj/Http.h"
#import "VideoPlayer.h"

@interface ViewController (){
	NSMutableArray *_chunks;
	BOOL _uploading;
	VideoPlayer *_player;
}

@property LiveRecorder *recorder;
@property AVCaptureVideoPreviewLayer *videoLayer;
@property IView *mainView;
@property IView *videoView;

@property IInput *ipInput;
@property IButton *submit;

@property NSString *ip;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.navigationItem.title = @"Recorder";

	_chunks = [[NSMutableArray alloc] init];
	_uploading = false;

	_mainView = [IView namedView:@"main"];
	_videoView = [_mainView getViewById:@"video"];
	[self addIViewRow:_mainView];
	[self reload];
	[_mainView layoutIfNeeded];
	
	__weak typeof(self) me = self;
	_ipInput = (IInput *)[_mainView getViewById:@"ip"];
	_submit = (IButton *)[_mainView getViewById:@"submit"];
	
	[_submit bindEvent:IEventClick handler:^(IEventType event, IView *view) {
		[me start];
	}];
	
	[self loadIp];
}

- (void)loadIp{
	_ip = _ipInput.value;
	if(!_ip || _ip.length == 0){
		_ip = [[NSUserDefaults standardUserDefaults] objectForKey:@"ip"];
		if(!_ip || _ip.length == 0){
			_ip = @"127.0.0.1";
		}
	}
	[[NSUserDefaults standardUserDefaults] setObject:_ip forKey:@"ip"];
	_ipInput.value = _ip;
}

- (void)start{
	if(_recorder){
		return;
	}
	_submit.button.enabled = NO;
	[self loadIp];
	
	_recorder = [[LiveRecorder alloc] init];
	_recorder.clipDuration = 0.2;
	//_recorder.width = 640;

	//_player = [[VideoPlayer alloc] init];

	if(_player){
		_videoLayer = [[AVCaptureVideoPreviewLayer alloc] init];
		_player.layer = _videoLayer;
		[_player play];
	}else{
		_videoLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_recorder.session];
	}
	_videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	_videoLayer.frame = self.videoView.bounds;
	_videoLayer.bounds = self.videoView.bounds;
	
	[_videoView.layer addSublayer:_videoLayer];

	__weak typeof(self) me = self;
	[_recorder setupVideo:^(VideoClip *clip) {
		NSData *data = clip.data;
		log_debug(@"%2d frames[%.3f ~ %.3f], duration: %.3f, %5d bytes, key_frame: %@",
			  clip.frameCount, clip.startTime, clip.endTime, clip.duration, (int)data.length,
			  clip.hasKeyFrame?@"yes":@"no");
		if(_player){
			VideoClip *c = [[VideoClip alloc] init];
			[c parseData:data];
			[_player addClip:c];
		}else{
			[me onChunkReady:data];
		}
	}];
//	[_recorder setupAudio:^(NSData *data, double pts, double duration) {
//		log_debug(@"%d bytes, %f %f", (int)data.length, pts, duration);
//	}];

	[_recorder start];
	log_debug(@"started");
}

static NSString *base64_encode_data(NSData *data){
	data = [data base64EncodedDataWithOptions:0];
	NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	return ret;
}

// 注意! _chunks 变量只能在 main queue 中操作!
- (void)onChunkReady:(NSData *)data{
	// http 请求必须放在 main queue
	dispatch_async(dispatch_get_main_queue(), ^{
		[_chunks addObject:data];
		[self uploadChunk];
	});
}

- (void)uploadChunk{
	dispatch_async(dispatch_get_main_queue(), ^{
		if(_uploading){
			return;
		}
		NSData *data = _chunks.firstObject;
		if(!data){
			return;
		}

		NSString *url = [NSString stringWithFormat:@"http://%@:8000/push", _ip]; // icomet
		NSString *data_str = base64_encode_data(data);
		NSDictionary *params = @{
								 @"content" : data_str,
								 };
		_uploading = YES;
		http_post_raw(url, params, ^(NSData *data) {
			NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			log_debug(@"uploaded, resp: %@", str);

			_uploading = NO;
			[_chunks removeObjectAtIndex:0];
			if(_chunks.count > 0){
				[self uploadChunk];
			}
		});
	});
}

@end
