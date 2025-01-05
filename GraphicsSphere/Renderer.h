//
//  Renderer.h
//  GraphicsSphere
//
//  Created by Anton Ivanov on 04.01.2025.
//

#import "Shader.h"

#import <MetalKit/MetalKit.h>

#define FOV 45

@interface Renderer : NSObject <MTKViewDelegate>

- (instancetype)initWithDevice:(id<MTLDevice>)device;

@end
