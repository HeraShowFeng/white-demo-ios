//
//  ViewController.m
//  white-demo-ios
//
//  Created by leavesster on 2018/8/19.
//  Copyright © 2018年 yleaf. All rights reserved.
//

#import "ViewController.h"
#import <White-SDK-iOS/WhiteSDK.h>

@interface ViewController ()
@property (nonatomic, copy) NSString *sdkToken;
@property (nonatomic, strong) WhiteRoom *room;
@property (nonatomic, strong) WhiteSDK *sdk;
@property (nonatomic, strong) WhiteBoardView *boardView;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.sdkToken = @"WHITEcGFydG5lcl9pZD1QNnR4cXJEQlZrZmJNZWRUdGVLenBURXRnZzhjbGZ6ZnZteUQmc2lnPWYzZjlkOTdhYTBmZmVhZTUxYzAxYTk0N2QwMWZmMzQ5ZGRhYjhmMmQ6YWRtaW5JZD0xJnJvbGU9YWRtaW4mZXhwaXJlX3RpbWU9MTU0OTYyNzcyMyZhaz1QNnR4cXJEQlZrZmJNZWRUdGVLenBURXRnZzhjbGZ6ZnZteUQmY3JlYXRlX3RpbWU9MTUxODA3MDc3MSZub25jZT0xNTE4MDcwNzcxMjg3MDA";
    self.view.backgroundColor = [UIColor whiteColor];
    if (self.roomUuid) {
        [self joinRoom];
    } else {
        [self createRoom];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self setTestingAPI];
}

#pragma mark - Room Action
- (void)createRoom
{
    self.title = NSLocalizedString(@"创建房间中...", nil);
    [self creatNewRoomRequestWithResult:^(BOOL success, id response) {
        if (success) {
            NSString *roomToken = response[@"msg"][@"roomToken"];
            NSString *uuid = response[@"msg"][@"room"][@"uuid"];
            [self joinRoomWithUuid:uuid roomToken:roomToken];
        } else {
            self.title = NSLocalizedString(@"创建失败", nil);
        }
    }];
}

- (void)joinRoom
{
    self.title = NSLocalizedString(@"加入房间中...", nil);
    [self getRoomTokenWithRoomUuid:self.roomUuid Result:^(BOOL success, id response) {
        if (success) {
            NSString *roomToken = response[@"msg"][@"roomToken"];
            [self joinRoomWithUuid:self.roomUuid roomToken:roomToken];
        } else {
            self.title = NSLocalizedString(@"加入失败", nil);
        }
    }];
}

- (void)joinRoomWithUuid:(NSString *)uuid roomToken:(NSString *)roomToken
{
    self.boardView = [[WhiteBoardView alloc] init];
    self.sdk = [[WhiteSDK alloc] initWithWhiteBoardView:self.boardView config:[WhiteSdkConfiguration defaultConfig]];
    [self.sdk joinRoomWithRoomUuid:uuid roomToken:roomToken callbacks:(id<WhiteRoomCallbackDelegate>)self completionHandler:^(BOOL success, WhiteRoom *room, NSError *error) {
        if (success) {
            self.title = nil;
            self.room = room;
            self.boardView.frame = self.view.bounds;
            self.boardView.autoresizingMask = UIViewAutoresizingFlexibleWidth |  UIViewAutoresizingFlexibleHeight;
            [self.view addSubview:self.boardView];
        } else {
            self.title = NSLocalizedString(@"加入失败", nil);
            //TODO: error
        }
    }];

}

#pragma mark - Set API
- (void)setTestingAPI
{
    [self.room setViewMode:WhiteViewModeBroadcaster];
    
    WhiteMemberState *mState = [[WhiteMemberState alloc] init];
    mState.currentApplianceName = ApplianceRectangle;
    [self.room setMemberState:mState];
    
//    WhitePptPage *pptPage = [[WhitePptPage alloc] init];
    //图片网址
//    pptPage.src = @"";
//    pptPage.width = 600;
//    pptPage.height = 600;
//    [self.room pushPptPages:@[pptPage]];
}

#pragma mark - Get API
- (void)getTestingAPI
{
    [self.room getPptImagesWithResult:^(NSArray<NSString *> *pptPages) {
        NSLog(@"%@", pptPages);
        
    }];
    
    [self.room getTransformWithResult:^(WhiteLinearTransformationDescription *transform) {
        NSLog(@"%@", [transform jsonString]);
    }];
    
    [self.room getGlobalStateWithResult:^(WhiteGlobalState *state) {
        NSLog(@"%@", [state jsonString]);
    }];
    
    [self.room getMemberStateWithResult:^(WhiteMemberState *state) {
        NSLog(@"%@", [state jsonString]);
    }];
    
    [self.room getBroadcastStateWithResult:^(WhiteBroadcastState *state) {
        NSLog(@"%@", [state jsonString]);
    }];
    
    [self.room getRoomMembersWithResult:^(NSArray<WhiteRoomMember *> *roomMembers) {
        for (WhiteRoomMember *m in roomMembers) {
            NSLog(@"%@", [m jsonString]);
        }
    }];
}


#pragma mark - WhiteRoomCallbackDelegate
- (void)firePhaseChanged:(WhiteRoomPhase)phase
{
    NSLog(@"%s, %ld", __FUNCTION__, (long)phase);
}

- (void)fireRoomStateChanged:(WhiteRoomState *)magixPhase;
{
    NSLog(@"%s, %@", __func__, [magixPhase jsonString]);
    if ([magixPhase.pptImages count] > 0) {
        //传入ppt时，立刻跳到对应页
        WhiteGlobalState *state = [[WhiteGlobalState alloc] init];
        state.currentSceneIndex = [magixPhase.pptImages count] - 1;
        [self.room setGlobalState:state];
    }
}

- (void)fireBeingAbleToCommitChange:(BOOL)isAbleToCommit
{
    NSLog(@"%s, %d", __func__, isAbleToCommit);
}

- (void)fireDisconnectWithError:(NSString *)error
{
    NSLog(@"%s, %@", __func__, error);
    
}

- (void)fireKickedWithReason:(NSString *)reason
{
    NSLog(@"%s, %@", __func__, reason);
}

- (void)fireCatchErrorWhenAppendFrame:(NSUInteger)userId error:(NSString *)error
{
    NSLog(@"%s, %luu %@", __func__,(unsigned long) (unsigned long)userId, error);
}


#pragma mark - Room server request
//向服务器请求，提供RoomUUID，获取RoomToken
- (void)creatNewRoomRequestWithResult:(void (^) (BOOL success, id response))result;
{
    //更换为自己的服务器请求
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://cloudcapiv3.herewhite.com/room?token=%@", self.sdkToken]]];
    NSMutableURLRequest *modifyRequest = [request mutableCopy];
    [modifyRequest setHTTPMethod:@"POST"];
    [modifyRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [modifyRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    NSDictionary *params = @{@"name": @"test", @"limit": @110, @"width": @1024, @"height": @768};
    NSData *postData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    [modifyRequest setHTTPBody:postData];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:modifyRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error && result) {
                result(NO, nil);
            } else if (result) {
                NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                result(YES, responseObject);
            }
        });
    }];
    [task resume];
}

//向服务器端请求，获取RoomUUID，RoomToken
- (void)getRoomTokenWithRoomUuid:(NSString *)uuid Result:(void (^) (BOOL success, id response))result
{
    //更换为自己的服务器请求
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://cloudcapiv3.herewhite.com/room/join?uuid=%@&token=%@", uuid,self.sdkToken]]];
    NSMutableURLRequest *modifyRequest = [request mutableCopy];
    [modifyRequest setHTTPMethod:@"POST"];
    [modifyRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:modifyRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error && result) {
                result(NO, nil);
            } else if (result) {
                NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                result(YES, responseObject);
            }
        });
    }];
    [task resume];
}

@end
