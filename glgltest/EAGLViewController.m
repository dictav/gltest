//
//  eaglViewController.m
//  eagl
//
//  Created by Shintaro Abe on 10/09/22.
//  Copyright 2010 dictav. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "EAGLViewController.h"
#import "EAGLView.h"

#define PLANE_ROW 1
#define PLANE_COL 1
#define NUM_INDICIES (PLANE_ROW - 1) * 2 * PLANE_COL

// verticies
enum {
	VERT_X,
	VERT_Y,
	VERT_Z,
	TEX_X,
	TEX_Y,
	NUM_VERTICIES
};


// Uniform index.
enum {
    UNIFORM_TRANSLATE,
	TEXTURE,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXTURE_COORD,//ATTRIB_COLOR,
    NUM_ATTRIBUTES
};

// texture
struct texture_params {
    GLuint id;
    CGSize size;
};
typedef struct texture_params Texture;

@interface EAGLViewController ()
{
    GLuint myProgram;
	Texture myTexture;
}

@property (nonatomic, retain) EAGLContext *context;
@property (assign) IBOutlet EAGLView *glView;
@property (assign) IBOutlet UIImageView *imageView;
- (UIImage*)imageWithImageBufferContentsOfURL:(NSURL*)url;
@end

@interface EAGLViewController (GLMethods)
- (void)setupGL;
- (void)drawFrame;
- (void)loadTexture:(Texture*)texture image:(UIImage *)image;
- (void)loadTexture:(Texture*)texture pixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (GLuint)createTextuerUsingSize:(CGSize)size;
- (GLuint)createProgramWithShaderFiles:(NSArray*)filenames;
- (GLuint)compileShaderWithContentsOfFile:(NSString*)file type:(GLenum)type;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation EAGLViewController

@synthesize context;
@synthesize glView;
@synthesize imageView;
#pragma mark -
#pragma mark lifecycle
- (void)viewDidLoad {
	[super viewDidLoad];
    [self setupGL];
    
    //set texture using adjust image
//    NSURL *url = [[NSBundle mainBundle] URLForResource:@"buffer_640x480_2560_1228808" withExtension:nil];
//    UIImage *image = [self imageWithImageBufferContentsOfURL:url];
//    self.imageView.image = image;
//    [self loadTextureWithPixelBuffer:(CVPixelBufferRef)[[NSData dataWithContentsOfURL:url] bytes]];
    
    UIImage *image = [UIImage imageNamed:@"noise_gazou.bmp"];
    self.imageView.image = image;
    [self loadTexture:&myTexture image:image];
    
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
    if (myProgram)
    {
        glDeleteProgram(myProgram);
        myProgram = 0;
    }
    
    // Tear down context.
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	self.context = nil;	
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)dealloc
{
    if (myProgram)
    {
        glDeleteProgram(myProgram);
        myProgram = 0;
    }
    
    // Tear down context.
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
    
    [context release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self drawFrame];

}

- (void)viewWillDisappear:(BOOL)animated
{
    
    [super viewWillDisappear:animated];
}


#pragma mark -
- (UIImage*)imageWithImageBufferContentsOfURL:(NSURL*)url
{
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (!data) {
        return nil;
    }
    CVImageBufferRef imageBuffer = (CVImageBufferRef)[data bytes];
    
    size_t bytesPerRow = 2560;
    // ピクセルバッファの幅と高さを取得する
    size_t width = 640;
    size_t height = 480;
    // デバイス依存のRGB色空間を作成する
    static CGColorSpaceRef colorSpace = NULL;
    if (colorSpace == NULL) {
        colorSpace = CGColorSpaceCreateDeviceRGB(); if (colorSpace == NULL) {
            // エラーを適切に処理する
            return nil;
        } 
    }
    // ピクセルバッファのベースアドレスを取得する
    void *baseAddress = imageBuffer;
    // ピクセルバッファの連続したプレーンのデータサイズを取得する
    size_t bufferSize = 128808;
    // 用意されたデータを使用するQuartzの直接アクセスデータプロバイダを作成する 
    CGDataProviderRef dataProvider =
    CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL); // データプロバイダが提供するデータからビットマップ画像を作成する
    CGImageRef cgImage =
    CGImageCreate(width, height, 8, 32, bytesPerRow,
                  colorSpace, kCGImageAlphaNoneSkipFirst |
                  kCGBitmapByteOrder32Little,
                  dataProvider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    // Quartz画像を表現するための画像オブジェクトを作成して返す
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationRight];
    CGImageRelease(cgImage);
    NSAssert(image, @"image not found");
    NSLog(@"image size:%@", NSStringFromCGSize(image.size));
    return image;
}
@end

@implementation EAGLViewController (GLMethods)
#pragma mark -
#pragma mark Draw GL Methods
- (void)drawFrame
{
    // Bind frame buffer
    [self.glView setFramebuffer];
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Validate program before drawing. This is a good check, but only really necessary in a debug build.
    // DEBUG macro must be defined in your debug configurations if that's not already the case.
#if defined(DEBUG)
    if (![self validateProgram:myProgram])
    {
        LOG(@"Failed to validate program: %d", myProgram);
        return;
    }
#endif
    
    // Draw
    GLushort indicies_[] = {
        0,1,2,0,2,3
    };

    glDrawElements(GL_TRIANGLE_STRIP, 6, GL_UNSIGNED_SHORT, indicies_);    
    
    [self.glView presentFramebuffer];
}

- (void)setupGL
{
    EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    NSAssert(aContext, @"Failed to create ES context");
    self.context = aContext;
    [aContext release];
    
    [self.glView setContext:self.context];
    [self.glView setFramebuffer];
    NSArray *shaders = [NSArray arrayWithObjects:@"Shader.vsh", @"Shader.fsh", @"inverse.fsh", nil];
    myProgram = [self createProgramWithShaderFiles:shaders];
    
//    GLfloat const verticies_[] = {
//        //x  ,   y  ,  z  ,  s  ,  t 
//        -1.0f, -1.0f, 0.0f, 1.0f, 1.0f,
//        -1.0f,  1.0f, 0.0f, 0.0f, 1.0f,
//        1.0f,  1.0f, 0.0f, 0.0f, 0.0f,
//        1.0f, -1.0f, 0.0f, 1.0f, 0.0f
//    };

    GLfloat const verticies_[] = {
        //x  ,   y  ,  z  ,  s  ,  t 
        -1.0f, -1.0f, 0.0f, 0.0f, 1.0f,
        -1.0f,  1.0f, 0.0f, 0.0f, 0.0f,
        1.0f,  1.0f, 0.0f, 1.0f, 0.0f,
        1.0f, -1.0f, 0.0f, 1.0f, 1.0f
    };

    // Use shader program.
    glUseProgram(myProgram);

    // Update uniform value.
    glUniform1i(uniforms[TEXTURE], 0);

    // Load the vertex position
    glVertexAttribPointer ( ATTRIB_VERTEX, 3, GL_FLOAT, 
                           GL_FALSE, NUM_VERTICIES * sizeof(GLfloat), verticies_ );
    glEnableVertexAttribArray(ATTRIB_VERTEX);

    // Load the texture coordinate
    glVertexAttribPointer ( ATTRIB_TEXTURE_COORD, 2, GL_FLOAT,
                           GL_FALSE, NUM_VERTICIES * sizeof(GLfloat), &verticies_[3] );
    glEnableVertexAttribArray(ATTRIB_TEXTURE_COORD);

    
    // Fill red color
    glClearColor(1.0f, 0.0f, 0.0f, 1.0f);

   
}

- (GLuint)compileShaderWithContentsOfFile:(NSString *)file type:(GLenum)type
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        LOG(@"Failed to load shader");
        return FALSE;
    }
    
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(shader, logLength, &logLength, log);
        LOG(@"Shader compile log: %@\n%s", file, log);
        free(log);
    }
#endif
    
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(shader);
        return FALSE;
    }
    
    return shader;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        LOG(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        LOG(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (GLuint)createProgramWithShaderFiles:(NSArray*)filenames
{
    NSMutableArray *shaders = [NSMutableArray array];
    GLuint shader = 0;
    BOOL isLinked = NO;
    
    // Create shader program.
    GLuint program = glCreateProgram();
    NSAssert(program, @"Failed to create program");
    
    for (NSString *file in filenames) {
        // Preprocess
        NSString *extension = [file pathExtension];
        NSString *path = [[NSBundle mainBundle] pathForResource:file ofType:nil];
        GLenum type;
        if ([extension isEqualToString:@"vsh"]) {
            type = GL_VERTEX_SHADER;
        } else if ([extension isEqualToString:@"fsh"]) {
            type = GL_FRAGMENT_SHADER;
        } else {
            LOG(@"File extension is failed. Shader extension must be 'vsh' or 'fsh': %@", file);
            break;
        }
        
        // Load and compile program
        shader = [self compileShaderWithContentsOfFile:path type:type];

        if (shader) {
            // Attach shader to program.
            glAttachShader(program, shader);
            [shaders addObject:[NSNumber numberWithUnsignedInt:shader]];
        } else {
            LOG(@"Failed to compile vertex shader: %@", file);
            break;
        }
    }

    // Link program if all files are compiled.
    if (shaders.count == filenames.count) {
        isLinked = [self linkProgram:program];
        if (!isLinked) {
            LOG(@"Failed to link program: %d", program);
        }
    } else {
        LOG(@"Failed to compile shaders");
    }

    if (isLinked) {
        // Bind attribute locations.
        // This needs to be done prior to linking.
        glBindAttribLocation(program, ATTRIB_VERTEX, "position");
        glBindAttribLocation(program, ATTRIB_TEXTURE_COORD, "texCoord");
        
        
        // Get uniform locations.
        uniforms[TEXTURE] = glGetUniformLocation(program, "texture");
    } else {
        glDeleteProgram(program);
        program = 0;
    }
        
    // Release vertex and fragment shaders.
    for (NSNumber *num in shaders) {
        glDeleteShader([num unsignedIntValue]);
    }
        
    return program;    
}

#pragma mark -
-(GLuint)createTextuerUsingSize:(CGSize)size
{
    GLuint handle;
    glGenTextures(1, &handle);
    glBindTexture(GL_TEXTURE_2D, handle);
    
    // S方向(横方向)で元のテクスチャ画像外の位置が指定されたときの処理方法
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    // T方向(縦方向)で元のテクスチャ画像外の位置が指定されたときの処理方法
    //	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    // テクスチャ拡大時の補完方法を指定
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);       
    // テクスチャ縮小時の補完方法を指定
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
	int dataSize = size.width * size.height * 4;
	uint8_t* textureData = (uint8_t*)malloc(dataSize);
    NSAssert(textureData != NULL, @"could not allocate texture data");
	memset(textureData, 128, dataSize);
    glBindTexture(GL_TEXTURE_2D, handle);	
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, size.width, size.height, 0, GL_BGRA_EXT, 
				 GL_UNSIGNED_BYTE, textureData);
    

	free(textureData);
    
    return handle;
}

- (void)loadTexture:(Texture*)texture image:(UIImage *)image
{
    if (!CGSizeEqualToSize(texture->size, image.size)) {
        if (texture->id) {
            glDeleteTextures(1, &texture->id);
        }
        texture->id = [self createTextuerUsingSize:image.size];
        texture->size = image.size;
    }
    
    size_t width = image.size.width;
    size_t height = image.size.height;
    
	GLvoid *imageData = (GLvoid*)malloc(4 * width * height);
    NSAssert(imageData != NULL, @"could not allocate image data");

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef cntx = CGBitmapContextCreate(imageData, width, height, 8, 4 * width, colorSpace,
											  kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big);
	{
		CGColorSpaceRelease( colorSpace );
		CGContextClearRect( cntx, CGRectMake( 0, 0, width, height ) );
		CGContextDrawImage( cntx, CGRectMake( 0, 0, width, height ), image.CGImage);
        NSAssert(texture->id != 0, @"texute id was not generated");
		glBindTexture(GL_TEXTURE_2D, texture->id);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
	}
	CGContextRelease(cntx);
}

- (void)loadTexture:(Texture*)texture pixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CGSize bufferSize = CGSizeMake(640, 480);
    if (!CGSizeEqualToSize(texture->size, bufferSize)) {
        if (texture->id) {
            glDeleteTextures(1, &texture->id);
        }
        texture->id = [self createTextuerUsingSize:bufferSize];
        texture->size = bufferSize;
    }

    glBindTexture(GL_TEXTURE_2D, texture->id);
    
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, bufferSize.width, bufferSize.height, GL_BGRA_EXT, GL_UNSIGNED_BYTE, pixelBuffer);

}

@end
