
uniform highp mat4 u_mvpMatrix;

uniform samplerCube u_unitCube[1];

varying lowp vec3 v_texCoord[1];

void main()
{
    gl_FragColor = textureCube(u_unitCube[0],v_texCoord[0]);
}
