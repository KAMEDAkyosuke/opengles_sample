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
	PASS0_ATTRIB_POSITION = 0,
	PASS0_ATTRIB_COLOR,
};

enum {
    PASS1_ATTRIB_POSITION = 0,
    PASS1_ATTRIB_TEXCOORD
};

enum {
    PASS1_UNIFORM_TEX = 0,
};

typedef struct {
    float position[3];
    float color[4];
    float texcoord[2];
}vertex_t;

static vertex_t pass0_vertex[1024];
static GLushort pass0_indices[1024];

static vertex_t pass1_vertex[] = {
    {{-1.0f,-1.0, 0.0}, {0.0f, 0.0f, 0.0f, 0.0f}, {0.0f, 0.0f}},
    {{-1.0f, 1.0, 0.0}, {0.0f, 0.0f, 0.0f, 0.0f}, {0.0f, 1.0f}},
    {{ 1.0f,-1.0, 0.0}, {0.0f, 0.0f, 0.0f, 0.0f}, {1.0f, 0.0f}},
    {{ 1.0f, 1.0, 0.0}, {0.0f, 0.0f, 0.0f, 0.0f}, {1.0f, 1.0f}},
};

static GLubyte pass1_indices[] = {
    0, 1, 2, 3,
};

typedef struct {
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
            pass0_vertex[i].position[0] = (2 * (double)i/1024.0) - 1;
            pass0_vertex[i].position[1] = sin(2 * M_PI * (double)i/1024.0);
            pass0_vertex[i].position[2] = 0.0f;
            
            pass0_vertex[i].color[0] = 1.0f;
            pass0_vertex[i].color[1] = sin((M_PI * (double)i/1024.0) / 2);
            pass0_vertex[i].color[2] = 0.0f;
            pass0_vertex[i].color[3] = 1.0f;
            
            pass0_vertex[i].texcoord[0] = 0.0f;
            pass0_vertex[i].texcoord[1] = 0.0f;
            
            pass0_indices[i] = i;
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
    
    {// pass0
        glGenRenderbuffers(1, &pass0_buffers.colorrenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, pass0_buffers.colorrenderbuffer);
        
        glGenFramebuffers(1, &pass0_buffers.framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, pass0_buffers.framebuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                                  GL_RENDERBUFFER, pass0_buffers.colorrenderbuffer);
        
        GLsizei width  = self.frame.size.width;
        GLsizei height = self.frame.size.height;
        
        glGenTextures(1, &pass0_buffers.texture);
        glBindTexture(GL_TEXTURE_2D, pass0_buffers.texture);
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_RGB,
                     width,
                     height,
                     0,
                     GL_RGB,
                     GL_UNSIGNED_SHORT_5_6_5,
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
    }
    
    {// pass1
        glGenRenderbuffers(1, &pass1_buffers.colorrenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, pass1_buffers.colorrenderbuffer);
        
        glGenFramebuffers(1, &pass1_buffers.framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, pass1_buffers.framebuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                                  GL_RENDERBUFFER, pass1_buffers.colorrenderbuffer);
        
        glGenBuffers(1, &pass1_buffers.vertexbuffer);
        glBindBuffer(GL_ARRAY_BUFFER, pass1_buffers.vertexbuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(pass1_vertex), pass1_vertex, GL_STATIC_DRAW);
        
        glGenBuffers(1, &pass1_buffers.indexbuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, pass1_buffers.indexbuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(pass1_indices), pass1_indices, GL_STATIC_DRAW);
        
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
        
        pass1_buffers.uniforms[PASS1_UNIFORM_TEX] = glGetUniformLocation(pass1_buffers.program, "tex");

    }
    
    CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
    eaglLayer.opaque = YES;
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
    
    {// pass0
        glBindFramebuffer(GL_FRAMEBUFFER, pass0_buffers.framebuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, pass0_buffers.colorrenderbuffer);
        glBindBuffer(GL_ARRAY_BUFFER, pass0_buffers.vertexbuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, pass0_buffers.indexbuffer);
        glUseProgram(pass0_buffers.program);
        
        glClearColor(0.0f, 104.0f/255.0f, 55.0f/255.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        glViewport(0, 0, self.frame.size.width, self.frame.size.height);
        
        glEnableVertexAttribArray(PASS0_ATTRIB_POSITION);
        glVertexAttribPointer(PASS0_ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, sizeof(vertex_t), 0);
        glEnableVertexAttribArray(PASS0_ATTRIB_COLOR);
        glVertexAttribPointer(PASS0_ATTRIB_COLOR, 4, GL_FLOAT, GL_FALSE, sizeof(vertex_t), (GLvoid*) (sizeof(float) * 3));
        
        glDrawElements(GL_LINE_STRIP, sizeof(pass0_indices)/sizeof(pass0_indices[0]), GL_UNSIGNED_SHORT, 0);
    }
    {// pass1
        glBindFramebuffer(GL_FRAMEBUFFER, pass1_buffers.framebuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, pass1_buffers.colorrenderbuffer);
        glBindBuffer(GL_ARRAY_BUFFER, pass1_buffers.vertexbuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, pass1_buffers.indexbuffer);
        glUseProgram(pass1_buffers.program);
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        glViewport(0, 0, self.frame.size.width, self.frame.size.height);
        
        glEnableVertexAttribArray(PASS1_ATTRIB_POSITION);
        glVertexAttribPointer(PASS1_ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, sizeof(vertex_t), 0);
        glEnableVertexAttribArray(PASS1_ATTRIB_TEXCOORD);
        glVertexAttribPointer(PASS1_ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, sizeof(vertex_t), (GLvoid*) (sizeof(float) * 7));
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, pass0_buffers.texture);
        glUniform1i(pass1_buffers.uniforms[PASS1_UNIFORM_TEX], 0);
        
        glDrawElements(GL_TRIANGLE_STRIP, sizeof(pass1_indices)/sizeof(pass1_indices[0]), GL_UNSIGNED_BYTE, 0);
    }
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
