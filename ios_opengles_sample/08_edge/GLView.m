//
//  GLView.m
//  ios_opengles_sample
//
//  Created by organlounge on 2014/06/28.
//  Copyright (c) 2014年 KAMEDAkyosuke. All rights reserved.
//

#import "GLView.h"

#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import <GLKit/GLKit.h>

#import "../Common/shader_compiler.h"

enum {
	PASS0_ATTRIB_POSITION = 0,
	PASS0_ATTRIB_COLOR,
    PASS0_ATTRIB_NORMAL,
};

enum {
    PASS0_UNIFORM_PROJECTION_MATRIX = 0,
    PASS0_UNIFORM_CAMERA_VIEW_MATRIX,
    PASS0_UNIFORM_MODEL_TRANS_MATRIX,
    PASS0_UNIFORM_MODEL_ROTATE_MATRIX,
};

enum {
	PASS1_ATTRIB_POSITION = 0,
	PASS1_ATTRIB_COLOR,
    PASS1_ATTRIB_NORMAL,
};

enum {
    PASS1_UNIFORM_PROJECTION_MATRIX = 0,
    PASS1_UNIFORM_CAMERA_VIEW_MATRIX,
    PASS1_UNIFORM_MODEL_TRANS_MATRIX,
    PASS1_UNIFORM_MODEL_ROTATE_MATRIX,
};

enum {
    PASS2_ATTRIB_POSITION = 0,
    PASS2_ATTRIB_TEXCOORD
};

enum {
    PASS2_UNIFORM_EDGE_TEX = 0,
    PASS2_UNIFORM_COLOR_TEX,
};

typedef struct {
    float position[3];
    float color[4];
    float normal[3];
    float texcoord[2];
}vertex_t;

static vertex_t pass0_vertex[] = {
    // front
    {{-0.5, 0.0, 0.5}, {0, 0, 1, 1}, {0, 0, 1}, {0, 0}},
    {{-0.5, 1.0, 0.5}, {0, 0, 1, 1}, {0, 0, 1}, {0, 0}},
    {{ 0.5, 0.0, 0.5}, {0, 0, 1, 1}, {0, 0, 1}, {0, 0}},
    {{ 0.5, 1.0, 0.5}, {0, 0, 1, 1}, {0, 0, 1}, {0, 0}},
    
    // back
    {{-0.5, 0.0,-0.5}, {0, 0, 1, 1}, {0, 0, -1}, {0, 0}},
    {{-0.5, 1.0,-0.5}, {0, 0, 1, 1}, {0, 0, -1}, {0, 0}},
    {{ 0.5, 0.0,-0.5}, {0, 0, 1, 1}, {0, 0, -1}, {0, 0}},
    {{ 0.5, 1.0,-0.5}, {0, 0, 1, 1}, {0, 0, -1}, {0, 0}},
    
    // left
    {{-0.5, 0.0,-0.5}, {0, 0, 1, 1}, {-1, 0, 0}, {0, 0}},
    {{-0.5, 1.0,-0.5}, {0, 0, 1, 1}, {-1, 0, 0}, {0, 0}},
    {{-0.5, 0.0, 0.5}, {0, 0, 1, 1}, {-1, 0, 0}, {0, 0}},
    {{-0.5, 1.0, 0.5}, {0, 0, 1, 1}, {-1, 0, 0}, {0, 0}},
    
    // right
    {{ 0.5, 0.0,-0.5}, {0, 0, 1, 1}, {1, 0, 0}, {0, 0}},
    {{ 0.5, 1.0,-0.5}, {0, 0, 1, 1}, {1, 0, 0}, {0, 0}},
    {{ 0.5, 0.0, 0.5}, {0, 0, 1, 1}, {1, 0, 0}, {0, 0}},
    {{ 0.5, 1.0, 0.5}, {0, 0, 1, 1}, {1, 0, 0}, {0, 0}},
    
    // top
    {{ 0.5, 1.0,-0.5}, {0, 0, 1, 1}, {0, 1, 0}, {0, 0}},
    {{ 0.5, 1.0, 0.5}, {0, 0, 1, 1}, {0, 1, 0}, {0, 0}},
    {{-0.5, 1.0,-0.5}, {0, 0, 1, 1}, {0, 1, 0}, {0, 0}},
    {{-0.5, 1.0, 0.5}, {0, 0, 1, 1}, {0, 1, 0}, {0, 0}},
    
    // bottom
    {{ 0.5, 0.0,-0.5}, {0, 0, 1, 1}, {0, -1, 0}, {0, 0}},
    {{ 0.5, 0.0, 0.5}, {0, 0, 1, 1}, {0, -1, 0}, {0, 0}},
    {{-0.5, 0.0,-0.5}, {0, 0, 1, 1}, {0, -1, 0}, {0, 0}},
    {{-0.5, 0.0, 0.5}, {0, 0, 1, 1}, {0, -1, 0}, {0, 0}},
};
static GLubyte pass0_indices[] = {
    // Front
    0, 1, 2,
    1, 2, 3,
    // Back
    4, 5, 6,
    5, 6, 7,
    // Left
    8,  9, 10,
    9, 10, 11,
    // Right
    12, 13, 14,
    13, 14, 15,
    // Top
    16, 17, 18,
    17, 18, 19,
    // Bottom
    20, 21, 22,
    21, 22, 23
};

static vertex_t pass2_vertex[] = {
    {{-1.0f,-1.0, 0.0}, {0.0f, 0.0f, 0.0f, 0.0f}, {0, 0, 0}, {0.0f, 0.0f}},
    {{-1.0f, 1.0, 0.0}, {0.0f, 0.0f, 0.0f, 0.0f}, {0, 0, 0}, {0.0f, 1.0f}},
    {{ 1.0f,-1.0, 0.0}, {0.0f, 0.0f, 0.0f, 0.0f}, {0, 0, 0}, {1.0f, 0.0f}},
    {{ 1.0f, 1.0, 0.0}, {0.0f, 0.0f, 0.0f, 0.0f}, {0, 0, 0}, {1.0f, 1.0f}},
};

static GLubyte pass2_indices[] = {
    0, 1, 2, 3,
};

typedef struct {
    GLuint depthrenderbuffer;
    GLuint colorrenderbuffer;
    GLuint framebuffer;
    GLuint vertexbuffer;
    GLuint indexbuffer;
    GLuint program;
    GLuint texture;
    int    uniforms[256];
} buffers_t;

static buffers_t pass0_buffers;
static buffers_t pass1_buffers;
static buffers_t pass2_buffers;

@interface GLView ()

@property(nonatomic, strong)EAGLContext *context;

@end

@implementation GLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

-(void) layoutSubviews {
    [super layoutSubviews];
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES3;
    self.context = [[EAGLContext alloc] initWithAPI:api];
    NSCAssert(self.context != nil, @"[[EAGLContext alloc] initWithAPI:api] fail");
    
    BOOL r = [EAGLContext setCurrentContext:self.context];
    NSCAssert(r, @"[EAGLContext setCurrentContext:self.context] fail");
    
    {// pass0
        glGenRenderbuffers(1, &pass0_buffers.depthrenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, pass0_buffers.depthrenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
        
        glGenRenderbuffers(1, &pass0_buffers.colorrenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, pass0_buffers.colorrenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA, self.frame.size.width, self.frame.size.height);
        
        glGenFramebuffers(1, &pass0_buffers.framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, pass0_buffers.framebuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                                  GL_RENDERBUFFER, pass0_buffers.colorrenderbuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                                  GL_RENDERBUFFER, pass0_buffers.depthrenderbuffer);
        
        GLsizei width  = self.frame.size.width;
        GLsizei height = self.frame.size.height;
        
        glGenTextures(1, &pass0_buffers.texture);
        glBindTexture(GL_TEXTURE_2D, pass0_buffers.texture);
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_RGBA8,
                     width,
                     height,
                     0,
                     GL_RGBA,
                     GL_UNSIGNED_BYTE,
                     0);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pass0_buffers.texture, 0);

        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        NSCAssert(status == GL_FRAMEBUFFER_COMPLETE, @"0x%X", status);
        
        glGenBuffers(1, &pass0_buffers.vertexbuffer);
        glBindBuffer(GL_ARRAY_BUFFER, pass0_buffers.vertexbuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(pass0_vertex), pass0_vertex, GL_STATIC_DRAW);
        
        glGenBuffers(1, &pass0_buffers.indexbuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, pass0_buffers.indexbuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(pass0_indices), pass0_indices, GL_STATIC_DRAW);
        
        pass0_buffers.program = glCreateProgram();
        {// vertex
            NSString* path = [[NSBundle mainBundle] pathForResource:@"pass0_vertex_shader"
                                                             ofType:@"glsl"];
            NSError* error = nil;
            NSString* src = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
            GLuint shader = SC_compile(src.UTF8String, GL_VERTEX_SHADER);
            glAttachShader(pass0_buffers.program, shader);
        }
        {// fragment
            NSString* path = [[NSBundle mainBundle] pathForResource:@"pass0_fragment_shader"
                                                             ofType:@"glsl"];
            NSError* error = nil;
            NSString* src = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
            GLuint shader = SC_compile(src.UTF8String, GL_FRAGMENT_SHADER);
            glAttachShader(pass0_buffers.program, shader);
        }
        glLinkProgram(pass0_buffers.program);
        pass0_buffers.uniforms[PASS0_UNIFORM_PROJECTION_MATRIX]   = glGetUniformLocation(pass0_buffers.program, "projection");
        pass0_buffers.uniforms[PASS0_UNIFORM_CAMERA_VIEW_MATRIX]  = glGetUniformLocation(pass0_buffers.program, "cameraview");
        pass0_buffers.uniforms[PASS0_UNIFORM_MODEL_TRANS_MATRIX]  = glGetUniformLocation(pass0_buffers.program, "modeltrans");
        pass0_buffers.uniforms[PASS0_UNIFORM_MODEL_ROTATE_MATRIX] = glGetUniformLocation(pass0_buffers.program, "modelrotate");
    }
    
    {// pass1
        glGenRenderbuffers(1, &pass1_buffers.depthrenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, pass1_buffers.depthrenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
        
        glGenRenderbuffers(1, &pass1_buffers.colorrenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, pass1_buffers.colorrenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA, self.frame.size.width, self.frame.size.height);
        
        glGenFramebuffers(1, &pass1_buffers.framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, pass1_buffers.framebuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                                  GL_RENDERBUFFER, pass1_buffers.colorrenderbuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                                  GL_RENDERBUFFER, pass1_buffers.depthrenderbuffer);
        
        GLsizei width  = self.frame.size.width;
        GLsizei height = self.frame.size.height;
        
        glGenTextures(1, &pass1_buffers.texture);
        glBindTexture(GL_TEXTURE_2D, pass1_buffers.texture);
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_RGBA8,
                     width,
                     height,
                     0,
                     GL_RGBA,
                     GL_UNSIGNED_BYTE,
                     0);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pass1_buffers.texture, 0);
        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        NSCAssert(status == GL_FRAMEBUFFER_COMPLETE, @"0x%X", status);
        
        glGenBuffers(1, &pass1_buffers.vertexbuffer);
        glBindBuffer(GL_ARRAY_BUFFER, pass1_buffers.vertexbuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(pass0_vertex), pass0_vertex, GL_STATIC_DRAW);
        
        glGenBuffers(1, &pass1_buffers.indexbuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, pass1_buffers.indexbuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(pass0_indices), pass0_indices, GL_STATIC_DRAW);
        
        pass1_buffers.program = glCreateProgram();
        {// vertex
            NSString* path = [[NSBundle mainBundle] pathForResource:@"pass1_vertex_shader"
                                                             ofType:@"glsl"];
            NSError* error = nil;
            NSString* src = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
            GLuint shader = SC_compile(src.UTF8String, GL_VERTEX_SHADER);
            glAttachShader(pass1_buffers.program, shader);
        }
        {// fragment
            NSString* path = [[NSBundle mainBundle] pathForResource:@"pass1_fragment_shader"
                                                             ofType:@"glsl"];
            NSError* error = nil;
            NSString* src = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
            GLuint shader = SC_compile(src.UTF8String, GL_FRAGMENT_SHADER);
            glAttachShader(pass1_buffers.program, shader);
        }
        glLinkProgram(pass1_buffers.program);
        pass1_buffers.uniforms[PASS1_UNIFORM_PROJECTION_MATRIX]   = glGetUniformLocation(pass1_buffers.program, "projection");
        pass1_buffers.uniforms[PASS1_UNIFORM_CAMERA_VIEW_MATRIX]  = glGetUniformLocation(pass1_buffers.program, "cameraview");
        pass1_buffers.uniforms[PASS1_UNIFORM_MODEL_TRANS_MATRIX]  = glGetUniformLocation(pass1_buffers.program, "modeltrans");
        pass1_buffers.uniforms[PASS1_UNIFORM_MODEL_ROTATE_MATRIX] = glGetUniformLocation(pass1_buffers.program, "modelrotate");
    }
    
    {// pass2
        glGenRenderbuffers(1, &pass2_buffers.colorrenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, pass2_buffers.colorrenderbuffer);
        
        glGenFramebuffers(1, &pass2_buffers.framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, pass2_buffers.framebuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                                  GL_RENDERBUFFER, pass2_buffers.colorrenderbuffer);
        
        glGenBuffers(1, &pass2_buffers.vertexbuffer);
        glBindBuffer(GL_ARRAY_BUFFER, pass2_buffers.vertexbuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(pass2_vertex), pass2_vertex, GL_STATIC_DRAW);
        
        glGenBuffers(1, &pass2_buffers.indexbuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, pass2_buffers.indexbuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(pass2_indices), pass2_indices, GL_STATIC_DRAW);
        
        pass2_buffers.program = glCreateProgram();
        {// vertex
            NSString* path = [[NSBundle mainBundle] pathForResource:@"pass2_vertex_shader"
                                                             ofType:@"glsl"];
            NSError* error = nil;
            NSString* src = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
            GLuint shader = SC_compile(src.UTF8String, GL_VERTEX_SHADER);
            glAttachShader(pass2_buffers.program, shader);
        }
        {// fragment
            NSString* path = [[NSBundle mainBundle] pathForResource:@"pass2_fragment_shader"
                                                             ofType:@"glsl"];
            NSError* error = nil;
            NSString* src = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
            GLuint shader = SC_compile(src.UTF8String, GL_FRAGMENT_SHADER);
            glAttachShader(pass2_buffers.program, shader);
        }
        glLinkProgram(pass2_buffers.program);
        
        pass2_buffers.uniforms[PASS2_UNIFORM_EDGE_TEX]  = glGetUniformLocation(pass2_buffers.program, "edge_tex");
        pass2_buffers.uniforms[PASS2_UNIFORM_COLOR_TEX] = glGetUniformLocation(pass2_buffers.program, "color_tex");
    }
    
    CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
    eaglLayer.opaque = YES;
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
    
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)render:(CADisplayLink*)displayLink
{
    {// pass0
        glBindFramebuffer(GL_FRAMEBUFFER, pass0_buffers.framebuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, pass0_buffers.colorrenderbuffer);
        glBindBuffer(GL_ARRAY_BUFFER, pass0_buffers.vertexbuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, pass0_buffers.indexbuffer);
        glUseProgram(pass0_buffers.program);
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glEnable(GL_DEPTH_TEST);
        glViewport(0, 0, self.frame.size.width, self.frame.size.height);
        
        glEnableVertexAttribArray(PASS0_ATTRIB_POSITION);
        glVertexAttribPointer(PASS0_ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, sizeof(vertex_t), 0);
        glEnableVertexAttribArray(PASS0_ATTRIB_COLOR);
        glVertexAttribPointer(PASS0_ATTRIB_COLOR, 4, GL_FLOAT, GL_FALSE, sizeof(vertex_t), (GLvoid*) (sizeof(float) * 3));
        glEnableVertexAttribArray(PASS0_ATTRIB_NORMAL);
        glVertexAttribPointer(PASS0_ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, sizeof(vertex_t), (GLvoid*) (sizeof(float) * 7));
        
        GLKMatrix4 projectionMatrix = GLKMatrix4Identity;
        GLKMatrix4 camera = GLKMatrix4Identity;
        GLKMatrix4 modelrotate = GLKMatrix4Identity;
        GLKMatrix4 modelView = GLKMatrix4Identity;
        // projection
        {
            float aspect = fabsf(self.bounds.size.width / self.bounds.size.height);
            projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(20.0f), aspect, 13.0f, 17.0f);
            glUniformMatrix4fv(pass0_buffers.uniforms[PASS0_UNIFORM_PROJECTION_MATRIX], 1, 0, projectionMatrix.m);
        }
        // camera
        {
            static float f = 0.0;
            f += 1;
            camera = GLKMatrix4Translate(camera, 0, 0, -15.0f);
            camera = GLKMatrix4RotateX(camera, GLKMathDegreesToRadians(45));
            glUniformMatrix4fv(pass0_buffers.uniforms[PASS0_UNIFORM_CAMERA_VIEW_MATRIX], 1, 0, camera.m);
        }
        // model rotate
        {
            static float f = 0.0;
            f += 1;
            modelrotate = GLKMatrix4RotateY(modelrotate, GLKMathDegreesToRadians(f));
            glUniformMatrix4fv(pass0_buffers.uniforms[PASS0_UNIFORM_MODEL_ROTATE_MATRIX], 1, 0, modelrotate.m);
        }
        // model
        {
            glUniformMatrix4fv(pass0_buffers.uniforms[PASS0_UNIFORM_MODEL_TRANS_MATRIX], 1, 0, modelView.m);
        }
        glDrawElements(GL_TRIANGLES, sizeof(pass0_indices)/sizeof(pass0_indices[0]), GL_UNSIGNED_BYTE, 0);
    }
    {// pass1
        glBindFramebuffer(GL_FRAMEBUFFER, pass1_buffers.framebuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, pass1_buffers.colorrenderbuffer);
        glBindBuffer(GL_ARRAY_BUFFER, pass1_buffers.vertexbuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, pass1_buffers.indexbuffer);
        glUseProgram(pass1_buffers.program);
        
        glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glEnable(GL_DEPTH_TEST);
        glViewport(0, 0, self.frame.size.width, self.frame.size.height);
        
        glEnableVertexAttribArray(PASS1_ATTRIB_POSITION);
        glVertexAttribPointer(PASS1_ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, sizeof(vertex_t), 0);
        glEnableVertexAttribArray(PASS1_ATTRIB_COLOR);
        glVertexAttribPointer(PASS1_ATTRIB_COLOR, 4, GL_FLOAT, GL_FALSE, sizeof(vertex_t), (GLvoid*) (sizeof(float) * 3));
        glEnableVertexAttribArray(PASS1_ATTRIB_NORMAL);
        glVertexAttribPointer(PASS1_ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, sizeof(vertex_t), (GLvoid*) (sizeof(float) * 7));
        
        GLKMatrix4 projectionMatrix = GLKMatrix4Identity;
        GLKMatrix4 camera = GLKMatrix4Identity;
        GLKMatrix4 modelrotate = GLKMatrix4Identity;
        GLKMatrix4 modelView = GLKMatrix4Identity;
        // projection
        {
            float aspect = fabsf(self.bounds.size.width / self.bounds.size.height);
            projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(20.0f), aspect, 13.0f, 17.0f);
            glUniformMatrix4fv(pass1_buffers.uniforms[PASS1_UNIFORM_PROJECTION_MATRIX], 1, 0, projectionMatrix.m);
        }
        // camera
        {
            static float f = 0.0;
            f += 1;
            camera = GLKMatrix4Translate(camera, 0, 0, -15.0f);
            camera = GLKMatrix4RotateX(camera, GLKMathDegreesToRadians(45));
            glUniformMatrix4fv(pass1_buffers.uniforms[PASS1_UNIFORM_CAMERA_VIEW_MATRIX], 1, 0, camera.m);
        }
        // model rotate
        {
            static float f = 0.0;
            f += 1;
            modelrotate = GLKMatrix4RotateY(modelrotate, GLKMathDegreesToRadians(f));
            glUniformMatrix4fv(pass1_buffers.uniforms[PASS1_UNIFORM_MODEL_ROTATE_MATRIX], 1, 0, modelrotate.m);
        }
        // model
        {
            glUniformMatrix4fv(pass1_buffers.uniforms[PASS1_UNIFORM_MODEL_TRANS_MATRIX], 1, 0, modelView.m);
        }
        glDrawElements(GL_TRIANGLES, sizeof(pass0_indices)/sizeof(pass0_indices[0]), GL_UNSIGNED_BYTE, 0);
    }
    {// pass2
        glBindFramebuffer(GL_FRAMEBUFFER, pass2_buffers.framebuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, pass2_buffers.colorrenderbuffer);
        glBindBuffer(GL_ARRAY_BUFFER, pass2_buffers.vertexbuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, pass2_buffers.indexbuffer);
        glUseProgram(pass2_buffers.program);
        
        glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        glDisable(GL_DEPTH_TEST);
        glViewport(0, 0, self.frame.size.width, self.frame.size.height);
        
        glEnableVertexAttribArray(PASS2_ATTRIB_POSITION);
        glVertexAttribPointer(PASS2_ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, sizeof(vertex_t), 0);
        glEnableVertexAttribArray(PASS2_ATTRIB_TEXCOORD);
        glVertexAttribPointer(PASS2_ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, sizeof(vertex_t), (GLvoid*) (sizeof(float) * 10));
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, pass0_buffers.texture);
        glUniform1i(pass2_buffers.uniforms[PASS2_UNIFORM_EDGE_TEX], 0);
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, pass1_buffers.texture);
        glUniform1i(pass2_buffers.uniforms[PASS2_UNIFORM_COLOR_TEX], 1);
        
        glDrawElements(GL_TRIANGLE_STRIP, sizeof(pass2_indices)/sizeof(pass2_indices[0]), GL_UNSIGNED_BYTE, 0);
    }
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
