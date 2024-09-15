//
//  DicomLoader.h
//  MetalTest
//
//  Created by John Brewer on 7/1/19.
//  Copyright © 2019 Jera Design LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface DicomLoader : NSObject
- (id<MTLTexture>) createDICOMTextureForDevice:(id<MTLDevice>)device;
@end

NS_ASSUME_NONNULL_END
