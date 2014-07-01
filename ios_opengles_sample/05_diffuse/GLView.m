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
	ATTRIB_POSITION = 0,
	ATTRIB_COLOR,
    ATTRIB_NORMAL,
};

enum {
    UNIFORM_PROJECTION_MATRIX = 0,
    UNIFORM_CAMERA_VIEW_MATRIX,
    UNIFORM_MODEL_TRANS_MATRIX,
    UNIFORM_MODEL_ROTATE_MATRIX,
    UNIFORM_SIZE,
};

typedef struct {
    float position[3];
    float color[4];
    float normal[3];
}vertex_t;

static const vertex_t vertex[] = {
    // front
    {{-0.5, 0.0, 0.5}, {0, 0, 1, 1}, {0, 0, 1}},
    {{-0.5, 1.0, 0.5}, {0, 0, 1, 1}, {0, 0, 1}},
    {{ 0.5, 0.0, 0.5}, {0, 0, 1, 1}, {0, 0, 1}},
    {{ 0.5, 1.0, 0.5}, {0, 0, 1, 1}, {0, 0, 1}},
    
    // back
    {{-0.5, 0.0,-0.5}, {0, 0, 1, 1}, {0, 0, -1}},
    {{-0.5, 1.0,-0.5}, {0, 0, 1, 1}, {0, 0, -1}},
    {{ 0.5, 0.0,-0.5}, {0, 0, 1, 1}, {0, 0, -1}},
    {{ 0.5, 1.0,-0.5}, {0, 0, 1, 1}, {0, 0, -1}},
    
    // left
    {{-0.5, 0.0,-0.5}, {0, 0, 1, 1}, {-1, 0, 0}},
    {{-0.5, 1.0,-0.5}, {0, 0, 1, 1}, {-1, 0, 0}},
    {{-0.5, 0.0, 0.5}, {0, 0, 1, 1}, {-1, 0, 0}},
    {{-0.5, 1.0, 0.5}, {0, 0, 1, 1}, {-1, 0, 0}},
    
    // right
    {{ 0.5, 0.0,-0.5}, {0, 0, 1, 1}, {1, 0, 0}},
    {{ 0.5, 1.0,-0.5}, {0, 0, 1, 1}, {1, 0, 0}},
    {{ 0.5, 0.0, 0.5}, {0, 0, 1, 1}, {1, 0, 0}},
    {{ 0.5, 1.0, 0.5}, {0, 0, 1, 1}, {1, 0, 0}},
    
    // top
    {{ 0.5, 1.0,-0.5}, {0, 0, 1, 1}, {0, 1, 0}},
    {{ 0.5, 1.0, 0.5}, {0, 0, 1, 1}, {0, 1, 0}},
    {{-0.5, 1.0,-0.5}, {0, 0, 1, 1}, {0, 1, 0}},
    {{-0.5, 1.0, 0.5}, {0, 0, 1, 1}, {0, 1, 0}},
    
    // bottom
    {{ 0.5, 0.0,-0.5}, {0, 0, 1, 1}, {0, -1, 0}},
    {{ 0.5, 0.0, 0.5}, {0, 0, 1, 1}, {0, -1, 0}},
    {{-0.5, 0.0,-0.5}, {0, 0, 1, 1}, {0, -1, 0}},
    {{-0.5, 0.0, 0.5}, {0, 0, 1, 1}, {0, -1, 0}},
};

static const GLubyte indices[] = {
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

static GLuint depthrenderbuffer;
static GLuint colorrenderbuffer;
static GLuint framebuffer;
static GLuint vertexbuffer;
static GLuint indexbuffer;
static GLuint program;
static int    uniforms[UNIFORM_SIZE];

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

    glGenRenderbuffers(1, &depthrenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, depthrenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
    
    glGenRenderbuffers(1, &colorrenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorrenderbuffer);
    
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, colorrenderbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                              GL_RENDERBUFFER, depthrenderbuffer);
    
    glGenBuffers(1, &vertexbuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertex), vertex, GL_STATIC_DRAW);
    
    glGenBuffers(1, &indexbuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexbuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    program = glCreateProgram();
    {// vertex
        NSString* path = [[NSBundle mainBundle] pathForResource:@"vertex_shader"
                                                         ofType:@"glsl"];
        NSError* error = nil;
        NSString* src = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error];
        GLuint shader = SC_compile(src.UTF8String, GL_VERTEX_SHADER);
        glAttachShader(program, shader);
    }
    {// fragment
        NSString* path = [[NSBundle mainBundle] pathForResource:@"fragment_shader"
                                                         ofType:@"glsl"];
        NSError* error = nil;
        NSString* src = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error];
        GLuint shader = SC_compile(src.UTF8String, GL_FRAGMENT_SHADER);
        glAttachShader(program, shader);
    }
    glLinkProgram(program);
    
    uniforms[UNIFORM_PROJECTION_MATRIX]   = glGetUniformLocation(program, "projection");
    uniforms[UNIFORM_CAMERA_VIEW_MATRIX]  = glGetUniformLocation(program, "cameraview");
    uniforms[UNIFORM_MODEL_TRANS_MATRIX]  = glGetUniformLocation(program, "modeltrans");
    uniforms[UNIFORM_MODEL_ROTATE_MATRIX] = glGetUniformLocation(program, "modelrotate");
    
    glUseProgram(program);

    CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
    eaglLayer.opaque = YES;
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];

    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)render:(CADisplayLink*)displayLink
{
    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    glEnableVertexAttribArray(ATTRIB_POSITION);
    glVertexAttribPointer(ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, sizeof(vertex_t), 0);
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glVertexAttribPointer(ATTRIB_COLOR, 4, GL_FLOAT, GL_FALSE, sizeof(vertex_t), (GLvoid*) (sizeof(float) * 3));
    glEnableVertexAttribArray(ATTRIB_NORMAL);
    glVertexAttribPointer(ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, sizeof(vertex_t), (GLvoid*) (sizeof(float) * 7));
    
    // projection
    {
        float aspect = fabsf(self.bounds.size.width / self.bounds.size.height);
        GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(80.0f), aspect, 0.1f, 10.0f);
        glUniformMatrix4fv(uniforms[UNIFORM_PROJECTION_MATRIX], 1, 0, projectionMatrix.m);
    }
    // camera
    {
        GLKMatrix4 camera = GLKMatrix4Identity;
        camera = GLKMatrix4Translate(camera, 0, 0, -5.0f);
        camera = GLKMatrix4RotateX(camera, GLKMathDegreesToRadians(45));
        glUniformMatrix4fv(uniforms[UNIFORM_CAMERA_VIEW_MATRIX], 1, 0, camera.m);
    }
    // model rotate
    {
        static float f = 0.0;
        f += 1;
        GLKMatrix4 modelView = GLKMatrix4Identity;
        modelView = GLKMatrix4RotateY(modelView, GLKMathDegreesToRadians(f));
        glUniformMatrix4fv(uniforms[UNIFORM_MODEL_ROTATE_MATRIX], 1, 0, modelView.m);
    }
    // model
    {
        static float f = 0.0;
        f += 1;
        GLKMatrix4 modelView = GLKMatrix4Identity;
        modelView = GLKMatrix4Translate(modelView, cos(f/60) * 2, sin(f/120)*2, sin(f/60) * 2);
        glUniformMatrix4fv(uniforms[UNIFORM_MODEL_TRANS_MATRIX], 1, 0, modelView.m);
    }
    
    glDrawElements(GL_TRIANGLES, sizeof(indices)/sizeof(indices[0]), GL_UNSIGNED_BYTE, 0);
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
