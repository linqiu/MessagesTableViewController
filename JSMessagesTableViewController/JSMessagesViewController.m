//
//  JSMessagesViewController.m
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
#import <SDWebImage/UIImageView+WebCache.h>
#import <QuartzCore/QuartzCore.h>

#import "JSMessagesViewController.h"
#import "NSString+JSMessagesView.h"
#import "UIView+AnimationOptionsForCurve.h"
#import "UIColor+JSMessagesView.h"
#import "ImageWorker.h"

#define INPUT_HEIGHT 40.0f

@interface JSMessagesViewController ()

- (void)setup;

@end


@implementation JSMessagesViewController
@synthesize imageWorker;
@synthesize placeHolderImage;

#pragma mark - Initialization
- (void)setup{
    self.placeHolderImage = [UIImage imageNamed:@"defaultImage.png"];
    self.imageWorker = [[ImageWorker alloc] initWithWidth:100 height:100];
    [self.imageWorker addImageCache];

    CGSize size = self.view.frame.size;

    CGRect tableFrame = CGRectMake(0.0f, 0.0f, size.width, size.height - INPUT_HEIGHT);
    self.tableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];

    [self setBackgroundColor:[UIColor messagesBackgroundColor]];

    CGRect inputFrame = CGRectMake(0.0f, size.height - INPUT_HEIGHT, size.width, INPUT_HEIGHT);
    self.inputView = [[JSMessageInputView alloc] initWithFrame:inputFrame delegate:self];

    UIButton *sendButton = [self sendButton];
    sendButton.enabled = NO;
    sendButton.frame = CGRectMake(self.inputView.frame.size.width - 65.0f, 8.0f, 59.0f, 26.0f);
    [sendButton addTarget:self
                   action:@selector(sendPressed:)
         forControlEvents:UIControlEventTouchUpInside];

    [self.inputView setSendButton:sendButton];

    UIButton *imageButton = [self attachImageButton];
    imageButton.enabled = YES;
    [imageButton addTarget:self
                    action:@selector(attachImage:)
          forControlEvents:UIControlEventTouchUpInside];

    [self.inputView setAttachImageButton:imageButton];


    [self.view addSubview:self.inputView];

    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipe.direction = UISwipeGestureRecognizerDirectionDown;
    swipe.numberOfTouchesRequired = 1;
    [self.inputView addGestureRecognizer:swipe];
}

- (UIButton *)sendButton {
    return [UIButton defaultSendButton];
}


#pragma mark - View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)viewWillAppear:(BOOL)animated {
    [self scrollToBottomAnimated:NO];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillShowKeyboard:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillHideKeyboard:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"*** %@: didReceiveMemoryWarning ***", self.class);
}

#pragma mark - View rotation
- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.tableView reloadData];
    [self.tableView setNeedsLayout];
}

#pragma mark - Actions
- (void)sendPressed:(UIButton *)sender {
    [self.delegate sendPressed:sender
                      withText:[self.inputView.textView.text trimWhitespace]];
}

- (void)handleSwipe:(UIGestureRecognizer *)guestureRecognizer {
    [self.inputView.textView resignFirstResponder];
}

//- (void)tapImage:(UITapGestureRecognizer *) gesture {
//    UIImage *img = gesture.view;
//    
//    NSLog(@"touched this img: %@", img);
//}

- (void)attachImage:(UIButton *)sender {
    [self.delegate attachImage:sender];
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    JSBubbleMessageStyle style = [self.delegate messageStyleForRowAtIndexPath:indexPath];
    BOOL hasTimestamp = [self shouldHaveTimestampForRowAtIndexPath:indexPath];
    BOOL hasSpeakerLabel = [self shouldHaveSpeakerForRowAtIndexPath:indexPath];
    BOOL hasImageAttachment = [self shouldHaveImageAttachmentForRowAtIndexPath:indexPath];
    BOOL hasReadNotification = [self shouldHaveReadNotificationForRowAtIndexPath:indexPath];

    NSString *CellID = [NSString stringWithFormat:@"MessageCell_%d_%d_%d_%d_%d", style, hasTimestamp, hasSpeakerLabel, hasImageAttachment, hasReadNotification];

    JSBubbleMessageCell *cell = (JSBubbleMessageCell *) [tableView dequeueReusableCellWithIdentifier:CellID];

    if (!cell) {
        cell = [[JSBubbleMessageCell alloc] initWithBubbleStyle:style
                                                   hasTimestamp:hasTimestamp
                                                hasSpeakerLabel:hasSpeakerLabel
                                             hasImageAttachment:hasImageAttachment
                                            hasReadNotification:hasReadNotification
                                                reuseIdentifier:CellID];
    }

    cell.imageView.userInteractionEnabled = YES;
    cell.imageView.tag = indexPath.row;



    if (hasImageAttachment) {
        NSString *filePath = [self.dataSource imageUrlForRowAtIndex:indexPath];
        [cell setPicture:self.placeHolderImage];

        [self.imageWorker loadImageFromFilePath:filePath success:^(UIImage *image) {
            [cell setPicture:image];
            UITapGestureRecognizer *tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
            tapped.numberOfTapsRequired = 1;
            [cell addGestureRecognizer:tapped];

        }];
    }

    if (hasTimestamp) {
        [cell setTimestamp:[self.dataSource timestampForRowAtIndexPath:indexPath]];
    }

    if (hasSpeakerLabel) {
        [cell setSpeaker:[self.dataSource speakerNameForRowAtIndexPath:indexPath]];
    }

    if (hasReadNotification) {
        [cell setNotification:[self.dataSource readNotificationForRowAtIndex:indexPath]];
    }

    [cell setMessage:[self.dataSource textForRowAtIndexPath:indexPath]];
    [cell setBackgroundColor:tableView.backgroundColor];
    return cell;

}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - Table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat dateHeight = [self shouldHaveTimestampForRowAtIndexPath:indexPath] ? DATE_LABEL_HEIGHT : 0.0f;
    CGFloat speakerHeight = [self shouldHaveSpeakerForRowAtIndexPath:indexPath] ? DATE_LABEL_HEIGHT : 0.0f;
    CGFloat imageHeight = [self shouldHaveImageAttachmentForRowAtIndexPath:indexPath] ? 80.0f : 0.0f;

    return [JSBubbleView cellHeightForText:[self.dataSource textForRowAtIndexPath:indexPath]] + dateHeight + speakerHeight + imageHeight;
}

#pragma mark - Messages view controller
- (BOOL)shouldHaveSpeakerForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self.delegate speakerPolicyForMessagesView:indexPath]) {
        case JSMessageViewSpeakerPolicyShowOthers:
            return YES;
        case JSMessageViewSpeakerPolicyDoNotShowMe:
            return NO;
    }
    return NO;
}

- (BOOL)shouldHaveImageAttachmentForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self.delegate imageAttachmentPolicyForMessagesView:indexPath]) {
        case JSMessageViewImageAttachmentPolicyNoImage:
            return NO;
            break;
        case JSMessageViewImageAttachmentPolicyYesImage:
            return YES;
    }
    return NO;
}

- (BOOL)shouldHaveReadNotificationForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self.delegate readNotificationPolicyForMessagesView:indexPath]) {
        case JSMessageViewReadNotificationPolicyYes:
            return YES;
        case JSMessageViewReadNotificationPolicyNo:
            return NO;
    }
    return NO;
}

- (BOOL)shouldHaveTimestampForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self.delegate timestampPolicyForMessagesView]) {
        case JSMessagesViewTimestampPolicyAll:
            return YES;
        case JSMessagesViewTimestampPolicyAlternating:
            return indexPath.row % 2 == 0;
        case JSMessagesViewTimestampPolicyEveryThree:
            return indexPath.row % 3 == 0;
        case JSMessagesViewTimestampPolicyEveryFive:
            return indexPath.row % 5 == 0;
        case JSMessagesViewTimestampPolicyCustom:
            return NO;
    }

    return NO;
}

- (void)finishSend {
    [self.inputView.textView setText:nil];
    [self textViewDidChange:self.inputView.textView];
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];
}

- (void)setBackgroundColor:(UIColor *)color {
    self.view.backgroundColor = color;
    self.tableView.backgroundColor = color;
    self.tableView.separatorColor = color;
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    NSInteger rows = [self.tableView numberOfRowsInSection:0];

    if (rows > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows - 1 inSection:0]
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:animated];
    }
}

-(void) handleTap:(UITapGestureRecognizer *)recognizer {
    [self.delegate handleTap:recognizer];
}


#pragma mark - Text view delegate
- (void)textViewDidBeginEditing:(UITextView *)textView {
    [textView becomeFirstResponder];

    if (!self.previousTextViewContentHeight)
        self.previousTextViewContentHeight = textView.contentSize.height;

    [self scrollToBottomAnimated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [textView resignFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView {
    CGFloat maxHeight = [JSMessageInputView maxHeight];
    CGFloat textViewContentHeight = textView.contentSize.height;
    BOOL isShrinking = textViewContentHeight < self.previousTextViewContentHeight;
    CGFloat changeInHeight = textViewContentHeight - self.previousTextViewContentHeight;

    changeInHeight = (textViewContentHeight + changeInHeight >= maxHeight) ? 0.0f : changeInHeight;

    if (!isShrinking)
        [self.inputView adjustTextViewHeightBy:changeInHeight];

    if (changeInHeight != 0.0f) {
        [UIView animateWithDuration:0.25f
                         animations:^{
                             UIEdgeInsets insets = UIEdgeInsetsMake(0.0f, 0.0f, self.tableView.contentInset.bottom + changeInHeight, 0.0f);
                             self.tableView.contentInset = insets;
                             self.tableView.scrollIndicatorInsets = insets;

                             [self scrollToBottomAnimated:NO];

                             CGRect inputViewFrame = self.inputView.frame;
                             self.inputView.frame = CGRectMake(0.0f,
                                     inputViewFrame.origin.y - changeInHeight,
                                     inputViewFrame.size.width,
                                     inputViewFrame.size.height + changeInHeight);
                         }
                         completion:^(BOOL finished) {
                             if (isShrinking)
                                 [self.inputView adjustTextViewHeightBy:changeInHeight];
                         }];

        self.previousTextViewContentHeight = MIN(textViewContentHeight, maxHeight);
    }

    self.inputView.sendButton.enabled = ([textView.text trimWhitespace].length > 0);
}

#pragma mark - Keyboard notifications
- (void)handleWillShowKeyboard:(NSNotification *)notification {
    [self keyboardWillShowHide:notification];
}

- (void)handleWillHideKeyboard:(NSNotification *)notification {
    [self keyboardWillShowHide:notification];
}

- (void)keyboardWillShowHide:(NSNotification *)notification {
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIViewAnimationCurve curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:[UIView animationOptionsForCurve:curve]
                     animations:^{
                         CGFloat keyboardY = [self.view convertRect:keyboardRect fromView:nil].origin.y;

                         CGRect inputViewFrame = self.inputView.frame;
                         self.inputView.frame = CGRectMake(inputViewFrame.origin.x,
                                 keyboardY - inputViewFrame.size.height,
                                 inputViewFrame.size.width,
                                 inputViewFrame.size.height);

                         UIEdgeInsets insets = UIEdgeInsetsMake(0.0f,
                                 0.0f,
                                 self.view.frame.size.height - self.inputView.frame.origin.y - INPUT_HEIGHT,
                                 0.0f);

                         self.tableView.contentInset = insets;
                         self.tableView.scrollIndicatorInsets = insets;
                     }
                     completion:^(BOOL finished) {
                     }];
}

@end