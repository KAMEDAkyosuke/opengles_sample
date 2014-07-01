//
//  shader_compiler.c
//  ios_opengles_sample
//
//  Created by organlounge on 2014/06/29.
//  Copyright (c) 2014年 KAMEDAkyosuke. All rights reserved.
//

#include "shader_compiler.h"

#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

GLuint SC_compile(const char* src, GLenum shader_type)
{
    GLuint shader = glCreateShader(shader_type);
    int len = (int)strlen(src);
    glShaderSource(shader, 1, &src, &len);
    glCompileShader(shader);
    
    GLint status;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE) {
        GLint infolen = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infolen);
        GLchar *info = malloc(infolen);
        glGetShaderInfoLog(shader, infolen, 0, info);
        NSCAssert(false, @"%s", info);
    }
    return shader;
}