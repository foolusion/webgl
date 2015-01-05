// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html' as html;
import 'dart:web_gl' as GL;
import 'dart:typed_data' as t_d;

GL.RenderingContext gl;
int viewportWidth;
int viewportHeight;
html.CanvasElement canvas;
GL.Program shaderProgram;
int vertexPositionAttribute;
GL.Buffer vertexBuffer;
int vBItemSize;
int vBNumberOfItems;

GL.RenderingContext createGLContext(html.CanvasElement canvas) {
  var names = ['webgl', 'experimental-webgl'];
  GL.RenderingContext context = null;
  for (var i=0; i < names.length; i++) {
    try {
      context = canvas.getContext(names[i]);
    } catch(e) {}
    if (context != null) {
      break;
    }
  }
  if (context != null) {
    viewportWidth = canvas.width;
    viewportHeight = canvas.height;
  } else {
    print('Failed to create WebGL context!');
  }
  return context;
}

GL.Shader loadShader(type, shaderSource) {
  GL.Shader shader = gl.createShader(type);
  gl.shaderSource(shader, shaderSource);
  gl.compileShader(shader);
  
  if (gl.getShaderParameter(shader, GL.COMPILE_STATUS) == null) {
    print('Error compiling shader ${gl.getShaderInfoLog(shader)}');
    gl.deleteShader(shader);
    return null;
  }
  return shader;
}

void setupShaders() {
  String vertexShaderSource =
'''attribute vec3 aVertexPosition;
void main() {
  gl_Position = vec4(aVertexPosition, 1.0);
}
''';
  String fragmentShaderSource = 
'''precision mediump float;
void main() {
  gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
}
''';
  var vertexShader = loadShader(GL.VERTEX_SHADER, vertexShaderSource);
  var fragmentShader = loadShader(GL.FRAGMENT_SHADER, fragmentShaderSource);
  
  shaderProgram = gl.createProgram();
  gl.attachShader(shaderProgram, vertexShader);
  gl.attachShader(shaderProgram, fragmentShader);
  gl.linkProgram(shaderProgram);
  
  if (!gl.getProgramParameter(shaderProgram, GL.LINK_STATUS)) {
    print('Failed to setup shaders');
  }
  
  gl.useProgram(shaderProgram);
  
  vertexPositionAttribute = gl.getAttribLocation(shaderProgram, "aVertexPosition");
}

void setupBuffers() {
  vertexBuffer = gl.createBuffer();
  gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
  var triangleVertices = [
       0.0,  0.5, 0.0,
      -0.5, -0.5, 0.0,
       0.5, -0.5, 0.0
  ];
  gl.bufferData(GL.ARRAY_BUFFER, new t_d.Float32List.fromList(triangleVertices), GL.STATIC_DRAW);
  vBItemSize = 3;
  vBNumberOfItems = 3;
}

void draw() {
  gl.viewport(0, 0, viewportWidth, viewportHeight);
  gl.clear(GL.COLOR_BUFFER_BIT);
  gl.vertexAttribPointer(vertexPositionAttribute, vBItemSize, GL.FLOAT, false, 0, 0);
  gl.enableVertexAttribArray(vertexPositionAttribute);
  gl.drawArrays(GL.TRIANGLES, 0, vBNumberOfItems);
}

void main() {
  canvas = html.querySelector('#screen');
  canvas.width = html.window.innerWidth;
  canvas.height = html.window.innerHeight;
  gl = createGLContext(canvas);
  setupShaders();
  setupBuffers();
  gl.clearColor(0.0, 0.0, 0.0, 1.0);
  draw();
}
