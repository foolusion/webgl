// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:web_gl' as GL;
import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

class ImageLoader {
  Map<String, html.ImageElement> images = {};
  Map<String, GL.Texture> textures = {};
  List<String> loading = [];
  int numLoaded = 0;

  downloadAll(Function callback) {
    if (loading.length == 0) {
      callback();
    }
    for (String src in loading) {
      loadImage(src, callback);
    }
  }

  addImage(String src) {
    loading.add(src);
  }

  loadImage(String src, Function callback) {
    html.ImageElement img = new html.ImageElement();
    img.onLoad.listen((html.Event e) {
      numLoaded++;
      createTextureFromImage(src);
      if (numLoaded == loading.length) {
        callback();
      }
    });
    img.src = src;
    images[src] = img;
    textures[src] = gl.createTexture();
  }

  createTextureFromImage(String src) {
    gl.bindTexture(GL.TEXTURE_2D, textures[src]);
    gl.pixelStorei(GL.UNPACK_FLIP_Y_WEBGL, GL.ONE);
    gl.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, GL.RGBA, GL.UNSIGNED_BYTE, images[src]);
    gl.bindTexture(GL.TEXTURE_2D, null);
  }
}

GL.RenderingContext gl;
int viewportWidth;
int viewportHeight;
html.CanvasElement canvas;
GL.Program shaderProgram;
int vertexPositionAttribute;
int textureCoordinateAttribute;
GL.UniformLocation matrixUniform;
GL.UniformLocation samplerUniform;

GL.Buffer floorVertexPositionBuffer;
GL.Buffer floorVertexIndexBuffer;
GL.Buffer floorTextureCoordinateBuffer;
GL.Buffer cubeVertexPositionBuffer;
GL.Buffer cubeVertexIndexBuffer;
GL.Buffer cubeTextureCoordinateBuffer;

Matrix4 modelViewMatrix;
Matrix4 projectionMatrix;
List<Matrix4> modelViewMatrixStack = [];

ImageLoader il = new ImageLoader();

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
attribute vec2 aTextureCoordinate;
uniform mat4 uMatrix;
varying vec2 vTextureCoordinates;
void main() {
  vTextureCoordinates = aTextureCoordinate;
  gl_Position = uMatrix * vec4(aVertexPosition, 1.0);
}
''';
  String fragmentShaderSource = '''precision mediump float;
varying vec2 vTextureCoordinates;
uniform sampler2D uSampler;
void main() {
  gl_FragColor = texture2D(uSampler, vTextureCoordinates);
}
''';
  var vertexShader = loadShader(GL.VERTEX_SHADER, vertexShaderSource);
  var fragmentShader = loadShader(GL.FRAGMENT_SHADER, fragmentShaderSource);

  shaderProgram = gl.createProgram();
  gl.attachShader(shaderProgram, vertexShader);
  gl.attachShader(shaderProgram, fragmentShader);
  gl.linkProgram(shaderProgram);

  if (gl.getProgramParameter(shaderProgram, GL.LINK_STATUS) == null) {
    print('Failed to setup shaders');
  }

  gl.useProgram(shaderProgram);

  vertexPositionAttribute = gl.getAttribLocation(shaderProgram, "aVertexPosition");
  textureCoordinateAttribute = gl.getAttribLocation(shaderProgram, 'aTextureCoordinate');
  matrixUniform = gl.getUniformLocation(shaderProgram, "uMatrix");
  samplerUniform = gl.getUniformLocation(shaderProgram, 'uSampler');
}

void setupFloorBuffers() {
  floorVertexPositionBuffer = gl.createBuffer();
  gl.bindBuffer(GL.ARRAY_BUFFER, floorVertexPositionBuffer);
  var floorVertexPosition = [5.0, 0.0, 5.0, 5.0, 0.0, -5.0, -5.0, 0.0, -5.0, -5.0, 0.0, 5.0];
  gl.bufferData(GL.ARRAY_BUFFER, new Float32List.fromList(floorVertexPosition), GL.STATIC_DRAW);

  floorVertexIndexBuffer = gl.createBuffer();
  gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, floorVertexIndexBuffer);
  var floorVertexIndices = [0, 1, 2, 3];
  gl.bufferData(GL.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(floorVertexIndices), GL.STATIC_DRAW);

  floorTextureCoordinateBuffer = gl.createBuffer();
  gl.bindBuffer(GL.ARRAY_BUFFER, floorTextureCoordinateBuffer);
  var floorTextureCoordinates = [1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 0.0, 0.0];
  gl.bufferData(GL.ARRAY_BUFFER, new Float32List.fromList(floorTextureCoordinates), GL.STATIC_DRAW);
}

void setupCubeBuffers() {
  cubeVertexPositionBuffer = gl.createBuffer();
  gl.bindBuffer(GL.ARRAY_BUFFER, cubeVertexPositionBuffer);
  var cubeVertexPosition = [-1.0, 1.0, 1.0, 1.0, 1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0, 1.0, 1.0, -1.0, -1.0, 1.0, -1.0, -1.0, -1.0, 1.0, -1.0, -1.0, 1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, -1.0, 1.0, -1.0, 1.0, 1.0, 1.0, 1.0, 1.0,];
  gl.bufferData(GL.ARRAY_BUFFER, new Float32List.fromList(cubeVertexPosition), GL.STATIC_DRAW);

  cubeVertexIndexBuffer = gl.createBuffer();
  gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, cubeVertexIndexBuffer);
  var cubeVertexIndices = [0, 1, 3, 3, 1, 4, 2, 3, 6, 6, 3, 7, 3, 4, 7, 7, 4, 8, 4, 5, 8, 8, 5, 9, 7, 8, 10, 10, 8, 11, 10, 11, 12, 12, 11, 13];
  gl.bufferData(GL.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(cubeVertexIndices), GL.STATIC_DRAW);
  cubeTextureCoordinateBuffer = gl.createBuffer();
  gl.bindBuffer(GL.ARRAY_BUFFER, cubeTextureCoordinateBuffer);
  var cubeTextureCoordinates = [0.25, 1.0, 0.5, 1.0, 0.0, 0.75, 0.25, 0.75, 0.5, 0.75, 0.75, 0.75, 0.0, 0.5, 0.25, 0.5, 0.5, 0.5, 0.75, 0.5, 0.25, 0.25, 0.5, 0.25, 0.25, 0.0, 0.5, 0.0];
  gl.bufferData(GL.ARRAY_BUFFER, new Float32List.fromList(cubeTextureCoordinates), GL.STATIC_DRAW);
}

void setupBuffers() {
  setupFloorBuffers();
  setupCubeBuffers();
}

void drawFloor(String src) {
  Matrix4 m = projectionMatrix * modelViewMatrix;
  gl.uniformMatrix4fv(matrixUniform, false, m.storage);
  gl.enableVertexAttribArray(vertexPositionAttribute);
  gl.bindBuffer(GL.ARRAY_BUFFER, floorVertexPositionBuffer);
  gl.vertexAttribPointer(vertexPositionAttribute, 3, GL.FLOAT, false, 0, 0);

  gl.enableVertexAttribArray(textureCoordinateAttribute);
  gl.bindBuffer(GL.ARRAY_BUFFER, floorTextureCoordinateBuffer);
  gl.vertexAttribPointer(textureCoordinateAttribute, 2, GL.FLOAT, false, 0, 0);
  gl.activeTexture(GL.TEXTURE0);
  gl.bindTexture(GL.TEXTURE_2D, il.textures[src]);
  gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
  gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
  gl.uniform1i(samplerUniform, 0);

  gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, floorVertexIndexBuffer);
  gl.drawElements(GL.TRIANGLE_FAN, 4, GL.UNSIGNED_SHORT, 0);
}

void drawCube(String src) {
  Matrix4 m = projectionMatrix * modelViewMatrix;
  gl.uniformMatrix4fv(matrixUniform, false, m.storage);

  gl.enableVertexAttribArray(vertexPositionAttribute);
  gl.bindBuffer(GL.ARRAY_BUFFER, cubeVertexPositionBuffer);
  gl.vertexAttribPointer(vertexPositionAttribute, 3, GL.FLOAT, false, 0, 0);

  gl.enableVertexAttribArray(textureCoordinateAttribute);
  gl.bindBuffer(GL.ARRAY_BUFFER, cubeTextureCoordinateBuffer);
  gl.vertexAttribPointer(textureCoordinateAttribute, 2, GL.FLOAT, false, 0, 0);
  gl.activeTexture(GL.TEXTURE0);
  gl.bindTexture(GL.TEXTURE_2D, il.textures[src]);
  gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
  gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
  gl.uniform1i(samplerUniform, 0);

  gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, cubeVertexIndexBuffer);
  gl.drawElements(GL.TRIANGLES, 36, GL.UNSIGNED_SHORT, 0);
}

void drawTable(String src) {
  modelViewMatrixStack.add(new Matrix4.copy(modelViewMatrix));
  modelViewMatrix.translate(0.0, 1.0, 0.0);
  modelViewMatrix.scale(2.0, 0.1, 2.0);
  drawCube(src);
  modelViewMatrix = modelViewMatrixStack.removeLast();

  for (var i = -1; i <= 1; i += 2) {
    for (var j = -1; j <= 1; j += 2) {
      modelViewMatrixStack.add(new Matrix4.copy(modelViewMatrix));
      modelViewMatrix.translate(i * 1.9, -0.1, j * 1.9);
      modelViewMatrix.scale(0.1, 1.0, 0.1);
      drawCube(src);
      modelViewMatrix = modelViewMatrixStack.removeLast();
    }
  }
}

void draw() {
  gl.viewport(0, 0, viewportWidth, viewportHeight);
  gl.clear(GL.COLOR_BUFFER_BIT);

  var top = .1 * math.tan(math.PI / 8);
  var bottom = -top;
  var aspect = canvas.width / canvas.height;
  var left = bottom * aspect;
  var right = top * aspect;

  projectionMatrix = makeFrustumMatrix(left, right, bottom, top, 0.1, 100);
  modelViewMatrix = makeViewMatrix(new Vector3(-5.0, 5.0, 20.0), new Vector3(5.0, 0.0, -20.0), new Vector3(0.0, 1.0, 0.0));

  modelViewMatrixStack.add(new Matrix4.copy(modelViewMatrix));
  drawFloor("res/texture.png");
  modelViewMatrix = modelViewMatrixStack.removeLast();

  modelViewMatrixStack.add(new Matrix4.copy(modelViewMatrix));
  modelViewMatrix.translate(0.0, 1.1, 0.0);
  drawTable("res/texture.png");
  modelViewMatrix = modelViewMatrixStack.removeLast();

  // draw cube
  modelViewMatrixStack.add(new Matrix4.copy(modelViewMatrix));
  modelViewMatrix.translate(0.0, 2.7, 0.0);
  modelViewMatrix.scale(.5);
  drawCube("res/texture.png");
  modelViewMatrix = modelViewMatrixStack.removeLast();
}

void main() {
  canvas = html.querySelector('#screen');
  canvas.width = html.window.innerWidth;
  canvas.height = html.window.innerHeight;
  gl = createGLContext(canvas);
  setupShaders();
  setupBuffers();
  gl.clearColor(1.0, 1.0, 1.0, 1.0);
  gl.frontFace(GL.CCW);
  gl.enable(GL.CULL_FACE);
  gl.cullFace(GL.BACK);
  gl.enable(GL.DEPTH_TEST);
  il.addImage("res/texture.png");
  il.downloadAll(draw);
}
