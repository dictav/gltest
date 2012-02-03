//
//  EAGLView.h
//  eagl
//
//  Created by Shintaro Abe on 10/09/22.
//  Copyright 2010 dictav. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

// This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
// The view content is basically an EAGL surface you render your OpenGL scene into.
// Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
@interface EAGLView : UIView

@property (nonatomic, retain) EAGLContext *context;
// The pixel dimensions of the CAEAGLLayer.
@property (nonatomic, readonly) CGSize framebufferSize;
- (void)setFramebuffer;
- (BOOL)presentFramebuffer;
@end
