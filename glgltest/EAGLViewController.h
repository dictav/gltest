//
//  eaglViewController.h
//  eagl
//
//  Created by Shintaro Abe on 10/09/22.
//  Copyright 2010 dictav. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <OpenGLES/EAGL.h>

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
@interface EAGLViewController : UIViewController
{
    EAGLContext *context;
    GLuint program;
    
	GLfloat *verticies;
	GLushort *indicies;
	GLuint textureId;	

}

@end
