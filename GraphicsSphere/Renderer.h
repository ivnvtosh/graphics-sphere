//
//  Renderer.h
//  GraphicsSphere
//
//  Created by Anton Ivanov on 04.01.2025.
//

#import "Shader.h"

#import <MetalKit/MetalKit.h>

#define FOV 90

@interface Renderer : NSObject <MTKViewDelegate>

- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (void)renderUsingRayCasting;
- (void)renderUsingRayTracing;

- (void)keyDown:(unsigned short)keyCode;
- (void)keyUp:(unsigned short)keyCode;
- (void)mouseDown:(NSPoint)point;
- (void)mouseDragged:(NSPoint)point;
- (void)mouseUp:(NSPoint)point;
- (void)rightMouseDown:(NSPoint)point;
- (void)rightMouseDragged:(NSPoint)point;
- (void)rightMouseUp:(NSPoint)point;

@end
