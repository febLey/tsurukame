// Copyright 2018 David Sansome
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "TKMAttributedModelItem.h"
#import "TKMAudio.h"

NS_ASSUME_NONNULL_BEGIN

@class TKMAudio;

@interface TKMReadingModelItem : TKMAttributedModelItem

- (void)setAudio:(TKMAudio *)audio subjectID:(int)subjectID;
- (void)playAudio;

@property(nonatomic, readonly) TKMAudio *audio;
@property(nonatomic, readonly) int audioSubjectID;
@property(nonatomic, weak) id<TKMAudioDelegate> audioDelegate;

@end

NS_ASSUME_NONNULL_END
