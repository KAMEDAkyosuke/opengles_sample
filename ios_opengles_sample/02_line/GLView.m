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

#import "../Common/shader_compiler.h"

enum {
	ATTRIB_POSITION = 0,
	ATTRIB_COLOR,
};

typedef struct {
    float position[3];
    float color[4];
}vertex_t;

static vertex_t vertex[1024];
static GLushort indices[1024];

static GLuint colorrenderbuffer;
static GLuint framebuffer;
static GLuint vertexbuffer;
static GLuint indexbuffer;
static GLuint program;


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
        for(int i=0; i<1024; ++i){
            vertex[i].position[0] = (2 * (double)i/1024.0) - 1;
            vertex[i].position[1] = sin(2 * M_PI * (double)i/1024.0);
            vertex[i].position[2] = 0.0f;
            
            vertex[i].color[0] = 1.0f;
            vertex[i].color[1] = sin((M_PI * (double)i/1024.0) / 2);
            vertex[i].color[2] = 0.0f;
            vertex[i].color[3] = 1.0f;
            
            indices[i] = i;
        }
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
    glGenRenderbuffers(1, &colorrenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorrenderbuffer);
    
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, colorrenderbuffer);
    
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
    glUseProgram(program);

    CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
    eaglLayer.opaque = YES;
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];

    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    glEnableVertexAttribArray(ATTRIB_POSITION);
    glVertexAttribPointer(ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, sizeof(vertex_t), 0);
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glVertexAttribPointer(ATTRIB_COLOR, 4, GL_FLOAT, GL_FALSE, sizeof(vertex_t), (GLvoid*) (sizeof(float) * 3));
    
    glDrawElements(GL_LINE_STRIP, sizeof(indices)/sizeof(indices[0]), GL_UNSIGNED_SHORT, 0);
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
