//
//  JSBubbleMessageCell.m
//
//  Created by Jesse Squires on 2/12/13.
//  Copyright (c) 2013 Hexed Bits. All rights reserved.
//
//  http://www.hexedbits.com
//
//
//  Largely based on work by Sam Soffes
//  https://github.com/soffes
//
//  SSMessagesViewController
//  https://github.com/soffes/ssmessagesviewcontroller
//
//
//  The MIT License
//  Copyright (c) 2013 Jesse Squires
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
//  associated documentation files (the "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
//  following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
//  LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
//  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <CoreGraphics/CoreGraphics.h>
#import "JSBubbleMessageCell.h"
#import "UIColor+JSMessagesView.h"

@interface JSBubbleMessageCell()

@property (strong, nonatomic) UILabel *timestampLabel;
@property (strong, nonatomic) UILabel *speakerLabel;
@property (strong, nonatomic) UILabel *readLabel;
@property (strong, nonatomic) UIImageView *imageAttachment;

- (void)setup;
- (void)configureTimestampLabel;
- (void)configureReadLabel:(CGFloat) yPosition;
- (void)configureSpeakerLabel:(CGFloat) yPosition;
- (void)configureImage;
- (void)configureWithStyle:(JSBubbleMessageStyle)style
              speakerLabel:(BOOL)hasSpeakerLabel
                 timeStamp:(BOOL)hasTimestamp
           imageAttachment:(BOOL)hasImage
          readNotification:(BOOL)hasRead;
@end



@implementation JSBubbleMessageCell

#pragma mark - Initialization
- (void)setup
{
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryType = UITableViewCellAccessoryNone;
    self.accessoryView = nil;
    
    self.imageView.image = nil;
    self.imageView.hidden = YES;
    self.textLabel.text = nil;
    self.textLabel.hidden = YES;
    self.detailTextLabel.text = nil;
    self.detailTextLabel.hidden = YES;


}

- (void)configureTimestampLabel
{
    self.timestampLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f,
                                                                    4.0f,
                                                                    [UIScreen mainScreen].bounds.size.width,
                                                                    14.5f)];
    self.timestampLabel.autoresizingMask =  UIViewAutoresizingNone;
    self.timestampLabel.backgroundColor = [UIColor clearColor];
    self.timestampLabel.textAlignment = NSTextAlignmentCenter;
    self.timestampLabel.textColor = [UIColor messagesTimestampColor];
    self.timestampLabel.shadowColor = [UIColor whiteColor];
    self.timestampLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    self.timestampLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:11.5f];
    
    [self.contentView addSubview:self.timestampLabel];
    [self.contentView bringSubviewToFront:self.timestampLabel];
}

- (void)configureReadLabel:(CGFloat) yPosition {
    self.readLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f,
                                                                  yPosition,
                                                                  [UIScreen mainScreen].bounds.size.width - 20.0f,
                                                                  12.5f)];
//    self.readLabel.autoresizingMask =   UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.readLabel.backgroundColor = [UIColor clearColor];
    self.readLabel.textAlignment = NSTextAlignmentRight;
    self.readLabel.textColor = [UIColor messagesTimestampColor];
    self.readLabel.shadowColor = [UIColor whiteColor];
    self.readLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    self.readLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:11.0f];
    self.readLabel.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight);
    
    [self.contentView addSubview:self.readLabel];
    [self.contentView bringSubviewToFront:self.readLabel];
}

- (void)configureSpeakerLabel:(CGFloat) yPosition
{
    self.speakerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f,
                                                                    yPosition,
                                                                    [UIScreen mainScreen].bounds.size.width,
                                                                    14.5f)];
    self.speakerLabel.autoresizingMask =  UIViewAutoresizingNone;
    self.speakerLabel.backgroundColor = [UIColor clearColor];
    self.speakerLabel.textAlignment = NSTextAlignmentLeft;
    self.speakerLabel.textColor = [UIColor messagesSpeakerColor];
    self.speakerLabel.shadowColor = [UIColor whiteColor];
    self.speakerLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    self.speakerLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:11.5f];
    
    [self.contentView addSubview:self.speakerLabel];
    [self.contentView bringSubviewToFront:self.speakerLabel];
}

- (void)configureWithStyle:(JSBubbleMessageStyle)style
              speakerLabel:(BOOL)hasSpeakerLabel
                 timeStamp:(BOOL)hasTimestamp
           imageAttachment:(BOOL)hasImage
          readNotification:(BOOL)hasRead  
{
    CGFloat bubbleY = 0.0f;
    CGFloat bubbleheight = 0.0f;

    
    if(!hasTimestamp && hasSpeakerLabel && !hasRead) {
        [self configureSpeakerLabel:4.0f];
        bubbleY = 14.0f;
        bubbleheight = 14.5f;
    } else if(hasTimestamp && hasSpeakerLabel && !hasRead) {
        [self configureSpeakerLabel:18.0f];
        [self configureTimestampLabel];
        bubbleY = 26.0f;
        bubbleheight = 26.5f;
    } else if(hasTimestamp && !hasSpeakerLabel && !hasRead ){
        [self configureTimestampLabel];

        bubbleY = 15.0f;
        bubbleheight = 22.5f;
    } else if(hasTimestamp && !hasSpeakerLabel && hasRead){
        [self configureReadLabel:31.5f];
        [self configureTimestampLabel];

        bubbleY = 20.0f;
        bubbleheight = 26.5f;
    } else if(!hasTimestamp && !hasSpeakerLabel && hasRead){
        [self configureReadLabel:30.0f];
        bubbleY = 8.0f;
        bubbleheight = 9.5f;
    }

//    else
//    if (hasTimestamp && !hasSpeakerLabel) {
//        [self configureTimestampLabel];
//        [self configureReadLabel:4.0f];
//        bubbleY = 28.0f;
//        bubbleheight = 29.5f;
//    }


    CGRect frame = CGRectMake(0.0f,
                              bubbleY,
                              self.contentView.frame.size.width,
                              self.contentView.frame.size.height - bubbleheight);
    
    self.bubbleView = [[JSBubbleView alloc] initWithFrame:frame
                                              bubbleStyle:style];
    
    self.bubbleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self.contentView addSubview:self.bubbleView];
    [self.contentView sendSubviewToBack:self.bubbleView];

}

- (id)initWithBubbleStyle:(JSBubbleMessageStyle)style
             hasTimestamp:(BOOL)hasTimestamp
          hasSpeakerLabel:(BOOL)hasSpeakerLabel
       hasImageAttachment:(BOOL)hasImage
      hasReadNotification:(BOOL)hasReadNotification
          reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if(self) {
        [self setup];
        [self configureWithStyle:style
                    speakerLabel:hasSpeakerLabel
                       timeStamp:hasTimestamp
                 imageAttachment:hasImage
                readNotification:hasReadNotification];
    }
    return self;
}
#pragma mark - Setters
- (void)setBackgroundColor:(UIColor *)color
{
    [super setBackgroundColor:color];
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentView setBackgroundColor:color];
    [self.bubbleView setBackgroundColor:color];
}

#pragma mark - Message Cell
- (void)setMessage:(NSString *)msg
{
    self.bubbleView.text = msg;
}

- (void)setTimestamp:(NSDate *)date
{
    self.timestampLabel.text = [NSDateFormatter localizedStringFromDate:date
                                                              dateStyle:NSDateFormatterMediumStyle
                                                              timeStyle:NSDateFormatterShortStyle];
}

- (void)setSpeaker:(NSString*) name
{
    self.speakerLabel.text = name;
}

- (void)setPicture:(UIImage *) picture
{
    self.bubbleView.attachmentView = [[UIImageView alloc] initWithImage:picture];
}

- (void)setNotification:(NSDate *)readNotifDate {

    NSString *date;
    if (readNotifDate == nil) {
        date = @"sent";
    }
    else {
        date = [@"read at " stringByAppendingString:[NSDateFormatter localizedStringFromDate:readNotifDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
    }
    self.readLabel.text = date;
}

-(void)setFailureMessage{
    self.readLabel.text = @"failed";
}

@end