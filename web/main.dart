// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:web_gl' as GL;
import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

GL.RenderingContext gl;
int viewportWidth;
int viewportHeight;
html.CanvasElement canvas;
GL.Program shaderProgram;
int vertexPositionAttribute;
int vertexColorAttribute;
GL.UniformLocation matrixUniform;

GL.Buffer floorVertexPositionBuffer;
GL.Buffer floorVertexIndexBuffer;
GL.Buffer cubeVertexPositionBuffer;
GL.Buffer cubeVertexIndexBuffer;

Matrix4 modelViewMatrix;
Matrix4 projectionMatrix;
List<Matrix4> modelViewMatrixStack = [];

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
uniform mat4 uMatrix;
varying vec4 vColor;
void main() {
  vColor = aVertexColor;
  gl_Position = uMatrix * vec4(aVertexPosition, 1.0);
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
  matrixUniform = gl.getUniformLocation(shaderProgram, "uMatrix");
}

void setupFloorBuffers() {
  floorVertexPositionBuffer = gl.createBuffer();
  gl.bindBuffer(GL.ARRAY_BUFFER, floorVertexPositionBuffer);
  var floorVertexPosition =
      [5.0,0.0,5.0,
       5.0,0.0,-5.0,
       -5.0,0.0,-5.0,
       -5.0,0.0,5.0];
  gl.bufferData(GL.ARRAY_BUFFER, new Float32List.fromList(floorVertexPosition), GL.STATIC_DRAW);
  
  floorVertexIndexBuffer = gl.createBuffer();
  gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, floorVertexIndexBuffer);
  var floorVertexIndices = [0,1,2,3];
  gl.bufferData(GL.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(floorVertexIndices), GL.STATIC_DRAW);
}

void setupCubeBuffers() {
  cubeVertexPositionBuffer = gl.createBuffer();
  gl.bindBuffer(GL.ARRAY_BUFFER, cubeVertexPositionBuffer);
  var cubeVertexPosition =
      [-1.0,1.0,-1.0,
       -1.0,-1.0,-1.0,
       1.0,1.0,-1.0,
       1.0,-1.0,-1.0,
       
       -1.0,1.0,1.0,
       -1.0,-1.0,1.0,
       1.0,1.0,1.0,
       1.0,-1.0,1.0];
  gl.bufferData(GL.ARRAY_BUFFER, new Float32List.fromList(cubeVertexPosition), GL.STATIC_DRAW);
  
  cubeVertexIndexBuffer = gl.createBuffer();
  gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, cubeVertexIndexBuffer);
  var cubeVertexIndices = 
      [
       0,1,2, 2,1,3,
       2,3,6, 6,3,7,
       4,5,0, 0,5,1,
       6,7,4, 4,7,5,
       4,0,6, 6,0,2,
       1,5,3, 3,5,7];
  gl.bufferData(GL.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(cubeVertexIndices), GL.STATIC_DRAW);
}

void setupBuffers() {
  setupFloorBuffers();
  setupCubeBuffers();
}

void drawFloor(double r, double g,double b, double a) {
  Matrix4 m = projectionMatrix*modelViewMatrix;
  gl.uniformMatrix4fv(matrixUniform, false, m.storage);
  gl.vertexAttrib4f(vertexColorAttribute, r, g, b, a);
  gl.enableVertexAttribArray(vertexPositionAttribute);
  gl.bindBuffer(GL.ARRAY_BUFFER, floorVertexPositionBuffer);
  gl.vertexAttribPointer(vertexPositionAttribute, 3, GL.FLOAT, false, 0, 0);
  gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, floorVertexIndexBuffer);
  gl.drawElements(GL.TRIANGLE_FAN, 4, GL.UNSIGNED_SHORT, 0);
}

void drawCube(double r, double g, double b, double a) {
  Matrix4 m = projectionMatrix*modelViewMatrix;
  gl.uniformMatrix4fv(matrixUniform, false, m.storage);
  
  gl.enableVertexAttribArray(vertexPositionAttribute);
  gl.disableVertexAttribArray(vertexColorAttribute);
  gl.vertexAttrib4f(vertexColorAttribute, r, g, b, a);
  gl.bindBuffer(GL.ARRAY_BUFFER, cubeVertexPositionBuffer);
  gl.vertexAttribPointer(vertexPositionAttribute, 3, GL.FLOAT, false, 0, 0);
  gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, cubeVertexIndexBuffer);
  gl.drawElements(GL.TRIANGLES, 36, GL.UNSIGNED_SHORT, 0);
}

void drawTable(double r, double g, double b, double a) {
  modelViewMatrixStack.add(new Matrix4.copy(modelViewMatrix));
  modelViewMatrix.translate(0.0,1.0,0.0);
  modelViewMatrix.scale(2.0,0.1,2.0);
  drawCube(0.72, 0.53, 0.04, 1.0);
  modelViewMatrix = modelViewMatrixStack.removeLast();
  
  for (var i =-1; i <= 1; i += 2) {
    for (var j = -1; j <= 1; j += 2) {
      modelViewMatrixStack.add(new Matrix4.copy(modelViewMatrix));
      modelViewMatrix.translate(i*1.9, -0.1, j*1.9);
      modelViewMatrix.scale(0.1, 1.0, 0.1);
      drawCube(0.72,0.53,0.04,1.0);
      modelViewMatrix = modelViewMatrixStack.removeLast();
    }
  }
}

void draw() {
  gl.viewport(0, 0, viewportWidth, viewportHeight);
  gl.clear(GL.COLOR_BUFFER_BIT);
  
  var top = .1 * math.tan(math.PI/8);
  var bottom = -top;
  var left = bottom*4/3;
  var right = top*4/3;
  
  projectionMatrix = makeFrustumMatrix(left, right, bottom, top, 0.1, 100);
  modelViewMatrix = makeViewMatrix(new Vector3(8.0,5.0,-10.0), new Vector3.zero(), new Vector3(0.0,1.0,0.0));
  
  modelViewMatrixStack.add(new Matrix4.copy(modelViewMatrix));
  drawFloor(1.0, 0.0, 0.0, 1.0);
  modelViewMatrix = modelViewMatrixStack.removeLast();
  
  modelViewMatrixStack.add(new Matrix4.copy(modelViewMatrix));
  modelViewMatrix.translate(0.0, 1.1, 0.0);
  drawTable(1.0, 0.0, 0.0, 1.0);
  modelViewMatrix = modelViewMatrixStack.removeLast();
  
  // draw cube
  modelViewMatrixStack.add(new Matrix4.copy(modelViewMatrix));
  modelViewMatrix.translate(0.0, 2.7, 0.0);
  modelViewMatrix.scale(.5);
  drawCube(0.0, 0.0, 1.0, 1.0);
  modelViewMatrix = modelViewMatrixStack.removeLast();
}

void main() {
  canvas = html.querySelector('#screen');
  canvas.width = 640;
  canvas.height = 480;
  gl = createGLContext(canvas);
  setupShaders();
  setupBuffers();
  gl.clearColor(1.0,1.0,1.0,1.0);
  gl.frontFace(GL.CCW);
  gl.enable(GL.CULL_FACE);
  gl.cullFace(GL.BACK);
  draw();
}
