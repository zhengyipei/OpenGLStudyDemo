
attribute vec4 position;
attribute vec2 inputTextureCoordinate;
varying lowp vec2 textureCoordinate;

void main(){
    
    textureCoordinate = inputTextureCoordinate;
    
    gl_Position = position;
}
