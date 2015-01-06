// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html' as html;
import 'dart:web_gl' as GL;
import 'dart:typed_data';

GL.RenderingContext gl;
int viewportWidth;
int viewportHeight;
html.CanvasElement canvas;
GL.Program shaderProgram;
int vertexPositionAttribute;
int vertexColorAttribute;
GL.Buffer hexagonVertexBuffer;
int hexagonVertexBufferItemSize = 3;
int hexagonVertexBufferNumberOfItems = 7;
GL.Buffer triangleVertexBuffer;
int triangleVertexBufferItemSize = 3;
int triangleVertexBufferNumberOfItems = 3;
GL.Buffer triangleVertexColorBuffer;
int triangleVertexColorBufferItemSize = 4;
int triangleVertexColorBufferNumberOfItems = 3;
GL.Buffer stripVertexBuffer;
int stripVertexBufferItemSize = 3;
int stripVertexBufferNumberOfItems = 22;
GL.Buffer stripElementBuffer;
int stripElementBufferNumberOfItems = 25;

GL.RenderingContext createGLContext(html.CanvasElement canvas) {
  var names = ['webgl', 'experimental-webgl'];
  GL.RenderingContext context = null;
  for (var i = 0; i < names.length; i++) {
    try {
      context = canvas.getContext(names[i]);
    } catch (e) {}
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
  String vertexShaderSource = '''attribute vec3 aVertexPosition;
attribute vec4 aVertexColor;
varying vec4 vColor;
void main() {
  vColor = aVertexColor;
  gl_Position = vec4(aVertexPosition, 1.0);
}
''';
  String fragmentShaderSource = '''precision mediump float;
varying vec4 vColor;
void main() {
  gl_FragColor = vColor;
}
''';
  var vertexShader = loadShader(GL.VERTEX_SHADER, vertexShaderSource);
  var fragmentShader = loadShader(GL.FRAGMENT_SHADER, fragmentShaderSource);

  shaderProgram = gl.createProgram();
  gl.attachShader(shaderProgram, vertexShader);
  gl.attachShader(shaderProgram, fragmentShader);
  gl.linkProgram(shaderProgram);

  if (gl.getProgramParameter(shaderProgram, GL.LINK_STATUS)==null) {
    print('Failed to setup shaders');
  }

  gl.useProgram(shaderProgram);

  vertexPositionAttribute = gl.getAttribLocation(shaderProgram, "aVertexPosition");
  vertexColorAttribute = gl.getAttribLocation(shaderProgram, 'aVertexColor');
}

void setupBuffers() {
  hexagonVertexBuffer = gl.createBuffer();
  gl.bindBuffer(GL.ARRAY_BUFFER, hexagonVertexBuffer);
  var hexagonVertices = 
      [-0.3,0.6,0.0,
       -0.4,0.8,0.0,
       -0.6,0.8,0.0,
       -0.7,0.6,0.0,
       -0.6,0.4,0.0,
       -0.4,0.4,0.0,
       -0.3,0.6,0.0];
  gl.bufferData(GL.ARRAY_BUFFER, new Float32List.fromList(hexagonVertices), GL.STATIC_DRAW);
  
  triangleVertexBuffer = gl.createBuffer();
  gl.bindBuffer(GL.ARRAY_BUFFER, triangleVertexBuffer);
  var triangleVertices =
      [0.3,0.4,0.0,
       0.7,0.4,0.0,
       0.5,0.8,0.0];
  gl.bufferData(GL.ARRAY_BUFFER, new Float32List.fromList(triangleVertices), GL.STATIC_DRAW);
  
  triangleVertexColorBuffer = gl.createBuffer();
  gl.bindBuffer(GL.ARRAY_BUFFER, triangleVertexColorBuffer);
  var colors = 
      [1.0,0.0,0.0,1.0,
       0.0,1.0,0.0,1.0,
       0.0,0.0,1.0,1.0];
  gl.bufferData(GL.ARRAY_BUFFER, new Float32List.fromList(colors), GL.STATIC_DRAW);
  
  stripVertexBuffer = gl.createBuffer();
  gl.bindBuffer(GL.ARRAY_BUFFER, stripVertexBuffer);
  var stripVertices =
      [-0.5,0.2,0.0,
       -0.4,0.0,0.0,
       -0.3,0.2,0.0,
       -0.2,0.0,0.0,
       -0.1,0.2,0.0,
       0.0,0.0,0.0,
       0.1,0.2,0.0,
       0.2,0.0,0.0,
       0.3,0.2,0.0,
       0.4,0.0,0.0,
       0.5,0.2,0.0,
       // start of the second strip
       -0.5,-0.3,0.0,
       -0.4,-0.5,0.0,
       -0.3,-0.3,0.0,
       -0.2,-0.5,0.0,
       -0.1,-0.3,0.0,
        0.0,-0.5,0.0,
        0.1,-0.3,0.0,
        0.2,-0.5,0.0,
        0.3,-0.3,0.0,
        0.4,-0.5,0.0,
        0.5,-0.3,0.0];
  gl.bufferData(GL.ARRAY_BUFFER, new Float32List.fromList(stripVertices), GL.STATIC_DRAW);
  
  stripElementBuffer = gl.createBuffer();
  gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, stripElementBuffer);
  var indices =
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
       10, 10, 11, // extra indices for the degenerate triangles
       11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21];
  gl.bufferData(GL.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(indices), GL.STATIC_DRAW);
}

void draw() {
  gl.viewport(0, 0, viewportWidth, viewportHeight);
  gl.clear(GL.COLOR_BUFFER_BIT);
  
  // draw the hexagon
  gl.enableVertexAttribArray(vertexPositionAttribute);
  gl.disableVertexAttribArray(vertexColorAttribute);
  gl.vertexAttrib4f(vertexColorAttribute, 0.0, 0.0, 0.0, 1.0);
  gl.bindBuffer(GL.ARRAY_BUFFER, hexagonVertexBuffer);
  gl.vertexAttribPointer(vertexPositionAttribute, hexagonVertexBufferItemSize, GL.FLOAT, false, 0, 0);
  gl.drawArrays(GL.LINE_STRIP, 0, hexagonVertexBufferNumberOfItems);
  
  // draw the independent triangle
  gl.enableVertexAttribArray(vertexColorAttribute);
  gl.bindBuffer(GL.ARRAY_BUFFER, triangleVertexBuffer);
  gl.vertexAttribPointer(vertexPositionAttribute, triangleVertexBufferItemSize, GL.FLOAT, false, 0, 0);
  gl.bindBuffer(GL.ARRAY_BUFFER, triangleVertexColorBuffer);
  gl.vertexAttribPointer(vertexColorAttribute, triangleVertexColorBufferItemSize, GL.FLOAT, false, 0, 0);
  gl.drawArrays(GL.TRIANGLES, 0, triangleVertexBufferNumberOfItems);
  
  // draw the triangle strip
  gl.disableVertexAttribArray(vertexColorAttribute);
  gl.bindBuffer(GL.ARRAY_BUFFER, stripVertexBuffer);
  gl.vertexAttribPointer(vertexPositionAttribute, stripVertexBufferItemSize, GL.FLOAT, false, 0, 0);
  gl.vertexAttrib4f(vertexColorAttribute, 1.0, 1.0, 0.0, 1.0);
  gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, stripElementBuffer);
  gl.drawElements(GL.TRIANGLE_STRIP, stripElementBufferNumberOfItems, GL.UNSIGNED_SHORT, 0);
  
  // draw lines to make triangles visible
  gl.vertexAttrib4f(vertexColorAttribute, 0.0, 0.0, 0.0, 1.0);
  gl.drawArrays(GL.LINE_STRIP, 0, 11);
  gl.drawArrays(GL.LINE_STRIP, 11, 11);
}

void main() {
  canvas = html.querySelector('#screen');
  canvas.width = html.window.innerWidth;
  canvas.height = html.window.innerHeight;
  gl = createGLContext(canvas);
  setupShaders();
  setupBuffers();
  gl.clearColor(1.0,1.0,1.0,1.0);
  gl.frontFace(GL.CCW);
  gl.enable(GL.CULL_FACE);
  gl.cullFace(GL.BACK);
  draw();
}
