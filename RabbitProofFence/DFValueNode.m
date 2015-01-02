//
//  DFValueNode.m
//  RabbitProofFence
//
//  Created by Sinha, Gyanendra on 11/20/14.
//  Copyright (c) 2014 Sinha, Gyanendra. All rights reserved.
//

#import "DFValueNode.h"
#import "DFIdentityOperation.h"
#import "EXTKeyPathCoding.h"
#import "DFPort.h"
#import "DFWorkspace.h"

@interface DFValueNode ()

@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation DFValueNode

+ (instancetype)nodeWithInfo:(DFNodeInfo *)info
{
    DFIdentityOperation *operation = nil;
    DFValueNode *node = [super nodeWithInfo:info];
    DFPort *inputPort = [node portForName:@keypath(operation.input)];
    inputPort.hidden = YES;
    return node;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

-(IBAction)editingEnded:(id)sender
{
    [sender resignFirstResponder];
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{}

- (void)startGear
{}

- (void)prepare_:(NSMutableSet *)preparedNodes
{
    [super prepare_:preparedNodes];
    DFIdentityOperation *identityOperation = (DFIdentityOperation *)self.operation;
    identityOperation.input = self.textField.text;
    [identityOperation excludePortFromFreePorts:@keypath(identityOperation.input)];
}

@end
