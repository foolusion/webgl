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
GL.Buffer vertexBuffer;

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
  vertexBuffer = gl.createBuffer();
  gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
  var triangleVertices = [0.0, 0.5, 0.0, 255, 0, 0, 255, -0.5, -0.5, 0.0, 0, 255, 0, 255, 0.5, -0.5, 0.0, 0, 0, 255, 255];

  var nbrOfVertices = 3;

  var vertexSizeInBytes = 3 * Float32List.BYTES_PER_ELEMENT + 4 * Uint8List.BYTES_PER_ELEMENT;

  var buffer = new Uint8List(nbrOfVertices * vertexSizeInBytes).buffer;
  var positionView = new Float32List.view(buffer);
  var colorView = new Uint8List.view(buffer);
  
  var positionOffset = 0;
  var colorOffset = 12;
  var k = 0;
  for (var i = 0; i < nbrOfVertices; i++) {
    positionView[positionOffset] = triangleVertices[k];
    positionView[1+positionOffset] = triangleVertices[1+k];
    positionView[2+positionOffset] = triangleVertices[2+k];
    colorView[colorOffset] = triangleVertices[3+k];
    colorView[1+colorOffset] = triangleVertices[4+k];
    colorView[2+colorOffset] = triangleVertices[5+k];
    colorView[3+colorOffset] = triangleVertices[6+k];
    
    positionOffset += 4;
    colorOffset += vertexSizeInBytes;
    k += 7;
  }
  gl.bufferData(GL.ARRAY_BUFFER, buffer, GL.STATIC_DRAW);
}

void draw() {
  gl.viewport(0, 0, viewportWidth, viewportHeight);
  gl.clear(GL.COLOR_BUFFER_BIT);
  gl.vertexAttribPointer(vertexPositionAttribute, 3, GL.FLOAT, false, 16, 0);
  gl.vertexAttribPointer(vertexColorAttribute, 4, GL.UNSIGNED_BYTE, true, 16, 12);
  gl.enableVertexAttribArray(vertexPositionAttribute);
  gl.enableVertexAttribArray(vertexColorAttribute);
  gl.drawArrays(GL.TRIANGLES, 0, 3);
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
