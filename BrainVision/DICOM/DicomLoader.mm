//
//  DicomLoader.m
//  MetalTest
//
//  Created by John Brewer on 7/1/19.
//  Copyright © 2019 Jera Design LLC. All rights reserved.
//

#import "DicomLoader.h"
#import "JeraDicomParser.h"
#import <Metal/Metal.h>

#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <cmath>

using namespace std;

@implementation DicomLoader

int SourceSizeX;
int SourceSizeY;
constexpr int DestSize = 128;

struct Color {
    float r;
    float g;
    float b;
    float a;
};

// Layers start with 0 for top layer for both "from" and "to".
- (void) copyLayerFrom:(const vector<uint8_t>&)from windowStart:(double)windowStart windowEnd:(double)windowEnd
                    to:(vector<Color>&)to fromLayer:(int)fromLayer
               toLayer:(int)toLayer spacingBetweenSlices:(double)spacingBetweenSlices
{
//    cout << "fromLayer: " << fromLayer << ", toLayer: " << toLayer << endl;
    int numLayers = static_cast<int>(from.size() / (SourceSizeX * SourceSizeY * 2));
    if (fromLayer < 0 || fromLayer >= numLayers || toLayer < 0 || toLayer >= DestSize) {
        return;
    }
    
//    windowStart += 300; // TODO WTF?
    
    const float yMin = 0;
    const float yMax = 1.0f;
    
    for (int y = 0; y < DestSize; y++) {
        for (int x = 0; x < DestSize; x++) {
            int fromIndex = 2 * (fromLayer * SourceSizeX * SourceSizeY + y * SourceSizeX + x);
            
            int colorValue = from[fromIndex] + 256 * from[fromIndex + 1];
            
//            histogram[colorValue]++;
            
            Color c { 0, 0, 0, 1 };
            
            if (colorValue == 0) {
                c.a = 0;
            }
            else {
                float scaledValue;
                if (colorValue <= windowStart) {
                    scaledValue = yMin;
                } else if (colorValue > windowEnd) {
                    scaledValue = yMax;
                } else {
                    scaledValue = (float)(((colorValue - windowStart) / (windowEnd - windowStart)) *
                                          (yMax - yMin) + yMin);
                }
                
                c.r = scaledValue;
                c.g = scaledValue;
                c.b = scaledValue;
                c.a = 1.0f;
            }
            
            int toIndex;
            if (spacingBetweenSlices < 0) {
                toIndex = x + (DestSize - toLayer - 1) * DestSize + (y * DestSize * DestSize);
            }
            else {
                toIndex = x + toLayer * DestSize + (y * DestSize * DestSize);
            }
            
            if (toIndex >= 0 && toIndex < to.size()) {
                to[toIndex] = c;
            }
            
            //                if (fromLayer == 0) {
            //                    print("colorValue: " + colorValue + ", y: " + y + ", x: " + x +
            //                          ", fromIndex: " + fromIndex + ", toIndex: " + toIndex + ", c: " + c);
            //                }
        }
    }
}

- (id<MTLTexture>) createDICOMTextureForDevice:(id<MTLDevice>)device
{
    NSString* path = [[NSBundle mainBundle] pathForResource:@"BREWER^JOHN _140028" ofType:@"dcm"];
    std::ifstream file([path UTF8String], std::ios::binary | std::ios::ate);
    std::streamsize size = file.tellg();
    file.seekg(0, std::ios::beg);

    std::vector<uint8_t> buffer(static_cast<size_t>(size));
    file.read(reinterpret_cast<char*>(buffer.data()), buffer.size());
    JeraDicomParser parser(std::move(buffer));

    if (size == 0) {
        cout << "Empty DICOM file!" << endl;
        return nil;
    }
    cout << "DICOM file size: " << size << endl;

    auto windowCenter = parser.GetDoubleForTag(JeraDicomParser::TagWindowCenter);
    auto windowWidth = parser.GetDoubleForTag(JeraDicomParser::TagWindowWidth);
    cout << "windowCenter = " << windowCenter << endl;
    cout << "windowWidth  = " << windowWidth << endl;

    double windowStart = windowCenter - 0.5 - (windowWidth - 1) / 2;
    double windowEnd = windowCenter - 0.5 + (windowWidth - 1) / 2;
    cout << "windowStart = " <<  windowStart << endl;
    cout << "windowEnd   = " << windowEnd << endl;

    auto spacingBetweenSlices = parser.GetDoubleForTag(JeraDicomParser::TagSpacingBetweenSlices);
    auto pixelSpacing = parser.GetDoublePairForTag(JeraDicomParser::TagPixelSpacing);
    cout << "rowSpacing = " << pixelSpacing.first << ", columnSpacing = " << pixelSpacing.second << endl;
    cout << "Study Description: " << parser.GetStringForTag(JeraDicomParser::TagStudyDescription) << endl;

    SourceSizeX = parser.GetUShortForTag(JeraDicomParser::TagColumns);
    SourceSizeY = parser.GetUShortForTag(JeraDicomParser::TagRows);
    cout << "rows: " << SourceSizeY << ", columns: " << SourceSizeX << endl;

    auto pixelBytes = parser.GetPixelData();
    
    vector<Color> colorArray(DestSize * DestSize * DestSize);

    int scaleFactor = (int)(fabs(spacingBetweenSlices) / pixelSpacing.first + 0.5);
    for (int layer = 0; layer < DestSize; layer++) {
        //            CopyLayer(c2D, colorArray, layer, layer + 20);
        for (int j = 0; j < scaleFactor; j++) {
            [self copyLayerFrom:pixelBytes
                    windowStart:windowStart windowEnd:windowEnd
                             to:colorArray
                      fromLayer:layer
                        toLayer:scaleFactor * layer + j
           spacingBetweenSlices:spacingBetweenSlices];
        }
    }

    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.textureType = MTLTextureType3D;
    textureDescriptor.pixelFormat = MTLPixelFormatRGBA32Float;
    textureDescriptor.width = DestSize;
    textureDescriptor.height = DestSize;
    textureDescriptor.depth = DestSize;
    textureDescriptor.usage = MTLTextureUsageShaderRead;
    auto texture3D = [device newTextureWithDescriptor:textureDescriptor];

    [texture3D replaceRegion:MTLRegionMake3D(0, 0, 0, DestSize, DestSize, DestSize)
                 mipmapLevel:0
                       slice:0
                   withBytes:colorArray.data()
                 bytesPerRow:DestSize * sizeof(float) * 4
               bytesPerImage:DestSize * DestSize * sizeof(float) * 4];

    return texture3D;
}

@end
