//
//  TUIConversationCell.m
//  TXIMSDK_TUIKit_iOS
//
//  Created by annidyfeng on 2019/5/16.
//

#import "TUIConversationCell.h"
#import "MMLayout/UIView+MMLayout.h"
#import "TIMUserProfile+DataProvider.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "TUIKit.h"
#import "CreatGroupAvatar.h"
#import "ReactiveObjC/ReactiveObjC.h"
#import "UIColor+TUIDarkMode.h"
#import "UIImage+TUIDarkMode.h"

@implementation TUIConversationCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [UIColor d_colorWithColorLight:TCell_Nomal dark:TCell_Nomal_Dark];

        _headImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:_headImageView];

        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont systemFontOfSize:12];
        _timeLabel.textColor = [UIColor d_systemGrayColor];
        _timeLabel.layer.masksToBounds = YES;
        [self.contentView addSubview:_timeLabel];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:16];
        _titleLabel.textColor = [UIColor d_colorWithColorLight:TText_Color dark:TText_Color_Dark];
        _titleLabel.layer.masksToBounds = YES;
        [self.contentView addSubview:_titleLabel];

        _unReadView = [[TUnReadView alloc] init];
        [self.contentView addSubview:_unReadView];

        _subTitleLabel = [[UILabel alloc] init];
        _subTitleLabel.layer.masksToBounds = YES;
        _subTitleLabel.font = [UIFont systemFontOfSize:14];
        _subTitleLabel.textColor = [UIColor d_systemGrayColor];
        [self.contentView addSubview:_subTitleLabel];
        
        _disturbImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:_disturbImageView];

        [self setSeparatorInset:UIEdgeInsetsMake(0, TConversationCell_Margin, 0, 0)];

        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
        //[self setSelectionStyle:UITableViewCellSelectionStyleDefault];
        
        // selectedIcon
        _selectedIcon = [[UIImageView alloc] init];
        [self.contentView addSubview:_selectedIcon];
    }
    return self;
}
- (void)fillWithData:(TUIConversationCellData *)convData
{
    [super fillWithData:convData];
    self.convData = convData;

    self.timeLabel.text = [convData.time tk_messageString];
    self.subTitleLabel.attributedText = convData.subTitle;
    
    if (convData.isNotDisturb) {
        self.disturbImageView.hidden = NO;
        self.unReadView.hidden = YES;
        UIImage *image = [UIImage d_imageWithImageLight:TUIKitResource(@"message_not_disturb") dark:TUIKitResource(@"message_not_disturb_dark")];
        [self.disturbImageView setImage:image];
    } else {
        self.disturbImageView.hidden = YES;
        self.unReadView.hidden = NO;
        [self.unReadView setNum:convData.unreadCount];
    }

    if (convData.isOnTop) {
        self.contentView.backgroundColor = [UIColor d_colorWithColorLight:TCell_OnTop dark:TCell_OnTop_Dark];
    } else {
        self.contentView.backgroundColor = [UIColor d_colorWithColorLight:TCell_Nomal dark:TCell_Nomal_Dark];
    }
    
    if ([TUIKit sharedInstance].config.avatarType == TAvatarTypeRounded) {
        self.headImageView.layer.masksToBounds = YES;
        self.headImageView.layer.cornerRadius = self.headImageView.frame.size.height / 2;
    } else if ([TUIKit sharedInstance].config.avatarType == TAvatarTypeRadiusCorner) {
        self.headImageView.layer.masksToBounds = YES;
        self.headImageView.layer.cornerRadius = [TUIKit sharedInstance].config.avatarCornerRadius;
    }

    @weakify(self)
    [[[RACObserve(convData, title) takeUntil:self.rac_prepareForReuseSignal]
      distinctUntilChanged] subscribeNext:^(NSString *x) {
        @strongify(self)
        self.titleLabel.text = x;
    }];
    
    // ??????????????????
    if (convData.groupID.length > 0) {
        // ??????, ??????????????????????????????????????????????????????
        NSString *key = [NSString stringWithFormat:@"TUIConversationLastGroupMember_%@", convData.groupID];
        NSInteger member = [NSUserDefaults.standardUserDefaults integerForKey:key];
        UIImage *avatar = [CreatGroupAvatar getCacheAvatarForGroup:convData.groupID number:(UInt32)member];
        if (avatar) {
            convData.avatarImage = avatar;
        }
    }
    
    [[RACObserve(convData,faceUrl) takeUntil:self.rac_prepareForReuseSignal] subscribeNext:^(NSString *x) {
        @strongify(self)
        if (self.convData.groupID.length > 0) { //??????
            // fix: ??????getCacheGroupAvatar??????????????????????????????????????????????????????headImageView?????????????????????????????????????????????????????????????????????????????????????????????????????????
            self.headImageView.image = self.convData.avatarImage;
            [CreatGroupAvatar getCacheGroupAvatar:convData.groupID callback:^(UIImage *avatar) {
                @strongify(self)
                if (avatar != nil) { //?????????????????????
                    self.headImageView.image = avatar;
                } else { //?????????????????????
                    [self.headImageView sd_setImageWithURL:[NSURL URLWithString:x]
                                          placeholderImage:self.convData.avatarImage];
                    [CreatGroupAvatar fetchGroupAvatars:convData.groupID placeholder:convData.avatarImage callback:^(BOOL success, UIImage *image, NSString *groupID) {
                        @strongify(self)
                        if ([groupID isEqualToString:self.convData.groupID]) {
                            // ????????????????????????????????????
                            [self.headImageView sd_setImageWithURL:[NSURL URLWithString:x] placeholderImage:image];
                        }
                    }];
                }
            }];
        } else {//????????????
            [self.headImageView sd_setImageWithURL:[NSURL URLWithString:x]
                                  placeholderImage:self.convData.avatarImage];
        }
    }];
    
    NSString *imageName = (convData.showCheckBox && convData.selected) ? TUIKitResource(@"icon_contact_select_selected") : TUIKitResource(@"icon_contact_select_normal");
    self.selectedIcon.image = [UIImage imageNamed:imageName];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat height = [self.convData heightOfWidth:self.mm_w];
    self.mm_h = height;
    CGFloat imgHeight = height-2*(TConversationCell_Margin);

    if (self.convData.showCheckBox) {
        _selectedIcon.mm_width(20).mm_height(20);
        _selectedIcon.mm_x = 10;
        _selectedIcon.mm_centerY = self.headImageView.mm_centerY;
        _selectedIcon.hidden = NO;
    } else {
        _selectedIcon.mm_width(0).mm_height(0);
        _selectedIcon.mm_x = 0;
        _selectedIcon.mm_y = 0;
        _selectedIcon.hidden = YES;
    }
    
    CGFloat margin = self.convData.showCheckBox ? _selectedIcon.mm_maxX : 0;
    self.headImageView.mm_width(imgHeight).mm_height(imgHeight).mm_left(TConversationCell_Margin + 3 + margin).mm_top(TConversationCell_Margin);
    if ([TUIKit sharedInstance].config.avatarType == TAvatarTypeRounded) {
        self.headImageView.layer.masksToBounds = YES;
        self.headImageView.layer.cornerRadius = imgHeight / 2;
    } else if ([TUIKit sharedInstance].config.avatarType == TAvatarTypeRadiusCorner) {
        self.headImageView.layer.masksToBounds = YES;
        self.headImageView.layer.cornerRadius = [TUIKit sharedInstance].config.avatarCornerRadius;
    }

    self.timeLabel.mm_sizeToFit().mm_top(TConversationCell_Margin_Text).mm_right(TConversationCell_Margin + 4);
    self.titleLabel.mm_sizeToFitThan(120, 30).mm_top(TConversationCell_Margin_Text - 5).mm_left(self.headImageView.mm_maxX+TConversationCell_Margin);
    self.unReadView.mm_right(TConversationCell_Margin + 4).mm_bottom(TConversationCell_Margin - 1);
    self.disturbImageView.mm_width(TConversationCell_Margin_Disturb).mm_height(TConversationCell_Margin_Disturb).mm_right(16).mm_bottom(15);
    self.subTitleLabel.mm_sizeToFit().mm_left(self.titleLabel.mm_x).mm_bottom(TConversationCell_Margin_Text).mm_flexToRight(self.mm_w-self.unReadView.mm_x);
}

///// ???????????????9?????????
//- (void)prefetchGroupMembers {
//    @weakify(self)
//    [[V2TIMManager sharedInstance] getGroupMemberList:self.convData.groupID filter:V2TIM_GROUP_MEMBER_FILTER_ALL nextSeq:0 succ:^(uint64_t nextSeq, NSArray<V2TIMGroupMemberFullInfo *> *memberList) {
//        @strongify(self)
//        int i = 0;
//        NSMutableArray *groupMemberAvatars = [NSMutableArray arrayWithCapacity:1];
//        for (V2TIMGroupMemberFullInfo* member in memberList) {
//            if (member.faceURL.length > 0) {
//                [groupMemberAvatars addObject:member.faceURL];
//                i++;
//            }
//            if (i == 9) {
//                break;
//            }
//        }
//        [self createGroupAvatar:groupMemberAvatars];
//
//        // ??????????????????????????????????????????
//        NSString *key = [NSString stringWithFormat:@"TUIConversationLastGroupMember_%@", self.convData.groupID];
//        [NSUserDefaults.standardUserDefaults setInteger:groupMemberAvatars.count forKey:key];
//        [NSUserDefaults.standardUserDefaults synchronize];
//
//    } fail:^(int code, NSString *msg) {
//        @strongify(self)
//        [self.headImageView sd_setImageWithURL:[NSURL URLWithString:self.convData.faceUrl]
//                              placeholderImage:self.convData.avatarImage];
//    }];
//}
//
///// ????????????????????????
//- (void)createGroupAvatar:(NSMutableArray*)groupMemberAvatars{
//    @weakify(self)
//    [CreatGroupAvatar createGroupAvatar:groupMemberAvatars finished:^(NSData *groupAvatar) {
//        @strongify(self)
//        UIImage *avatar = [UIImage imageWithData:groupAvatar];
//        self.headImageView.image = avatar;
//        [self cacheGroupAvatar:avatar number:(UInt32)groupMemberAvatars.count];
//    }];
//}
//
///// ??????????????????
///// @param avatar ??????
///// ????????????????????????????????????ID & ???????????????????????????
///// ???????????????????????????
//- (void)cacheGroupAvatar:(UIImage*)avatar number:(UInt32)memberNum {
//    if (self.convData.groupID.length == 0) {
//        return;
//    }
//    NSString* tempPath = NSTemporaryDirectory();
//    NSString *filePath = [NSString stringWithFormat:@"%@groupAvatar_%@_%d.png",tempPath,
//                          self.convData.groupID,memberNum];
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//
//    // check to delete old file
//    NSNumber *oldValue = [defaults objectForKey:self.convData.groupID];
//    if ( oldValue != nil) {
//        UInt32 oldMemberNum = [oldValue unsignedIntValue];
//        NSString *oldFilePath = [NSString stringWithFormat:@"%@groupAvatar_%@_%d.png",tempPath,
//        self.convData.groupID,oldMemberNum];
//         NSFileManager *fileManager = [NSFileManager defaultManager];
//        [fileManager removeItemAtPath:oldFilePath error:nil];
//    }
//
//    // Save image.
//    BOOL success = [UIImagePNGRepresentation(self.headImageView.image) writeToFile:filePath atomically:YES];
//    if (success) {
//        [defaults setObject:@(memberNum) forKey:self.convData.groupID];
//    }
//}
//
///// ????????????????????????
///// ?????????????????????????????????ID & ???????????????????????????
///// ?????????????????????????????????
//- (void)getCacheGroupAvatar:(void(^)(UIImage *))imageCallBack {
//    [[V2TIMManager sharedInstance] getGroupsInfo:@[self.convData.groupID] succ:^(NSArray<V2TIMGroupInfoResult *> *groupResultList) {
//        V2TIMGroupInfoResult *groupInfo = groupResultList.firstObject;
//        if (!groupInfo) {
//            imageCallBack(nil);
//            return;
//        }
//        UInt32 memberNum = groupInfo.info.memberCount;
//        //??????1-9?????????
//        memberNum = MAX(1, memberNum);
//        memberNum = MIN(memberNum, 9);;
//        NSString* tempPath = NSTemporaryDirectory();
//        NSString *filePath = [NSString stringWithFormat:@"%@groupAvatar_%@_%u.png",tempPath,
//                              self.convData.groupID,(unsigned int)memberNum];
//        NSFileManager *fileManager = [NSFileManager defaultManager];
//        UIImage *avatar = nil;
//        BOOL success = [fileManager fileExistsAtPath:filePath];
//
//        if (success) {
//            avatar= [[UIImage alloc] initWithContentsOfFile:filePath];
//            // ??????????????????????????????????????????
//            NSString *key = [NSString stringWithFormat:@"TUIConversationLastGroupMember_%@", self.convData.groupID];
//            [NSUserDefaults.standardUserDefaults setInteger:memberNum forKey:key];
//            [NSUserDefaults.standardUserDefaults synchronize];
//        }
//        imageCallBack(avatar);
//    } fail:^(int code, NSString *msg) {
//        imageCallBack(nil);
//    }];
//}
//
//
///// ???????????????????????????????????????
///// @param groupId ???id
///// @param memberNum ???????????????, ????????????9????????????????????????
//- (UIImage *)getCacheAvatarForGroup:(NSString *)groupId number:(UInt32)memberNum {
//    //??????1-9?????????
//    memberNum = MAX(1, memberNum);
//    memberNum = MIN(memberNum, 9);;
//    NSString* tempPath = NSTemporaryDirectory();
//    NSString *filePath = [NSString stringWithFormat:@"%@groupAvatar_%@_%u.png",tempPath,
//                          groupId,(unsigned int)memberNum];
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    UIImage *avatar = nil;
//    BOOL success = [fileManager fileExistsAtPath:filePath];
//
//    if (success) {
//        avatar= [[UIImage alloc] initWithContentsOfFile:filePath];
//    }
//    return avatar;
//}

@end
