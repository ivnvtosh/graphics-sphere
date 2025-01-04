//
//  Renderer.h
//  GraphicsSphere
//
//  Created by Anton Ivanov on 04.01.2025.
//

#import <MetalKit/MetalKit.h>

@interface Renderer : NSObject <MTKViewDelegate>

- (instancetype)initWithDevice:(id<MTLDevice>)device;

@end
