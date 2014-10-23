/*
 * Copyright 2010-2014 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import "Constants.h"

/*  Contains all access information for AWS to store files
 *  
 */

NSString *const AWSAccountID = @"911189109494";
NSString *const CognitoPoolID = @"us-east-1:6f59216a-0041-491e-954f-853b1cc35391";
NSString *const CognitoRoleAuth = nil;
NSString *const CognitoRoleUnauth = @"arn:aws:iam::911189109494:role/Cognito_lufthouse_awsUnauth_DefaultRole";

NSString *const S3BucketName = @"lufthouse-memories";

NSString *const S3KeyUploadName = @"audio.wav";


NSString *const StatusLabelReady = @"Ready";
NSString *const StatusLabelUploading = @"Uploading...";
NSString *const StatusLabelDownloading = @"Downloading...";
NSString *const StatusLabelFailed = @"Failed";
NSString *const StatusLabelCompleted = @"Completed";
