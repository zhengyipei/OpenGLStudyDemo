
attribute vec3 a_emissionPosition; //位置
attribute vec3 a_emissionVelocity; //速度
attribute vec3 a_emissionForce; //受力
attribute vec2 a_size;  //大小 和 Fade持续时间  size = GLKVector2Make(aSize, aDuration);
attribute vec2 a_emissionAndDeathTimes; //发射时间 和 消失时间

uniform highp mat4 u_mvpMatrix;
uniform sampler2D  u_samplers2D[1];
uniform highp vec3 u_gravity;
uniform highp float u_elapsedSeconds;//当前时间

varying lowp float v_particleOpacity;

void main()
{
    highp float elapsedTime = u_elapsedSeconds - a_emissionAndDeathTimes.x;//流失时间
    
    //v = v0 + at ; a = f/m 假设质量m为1
    highp vec3 velocity = a_emissionVelocity + ((a_emissionForce + u_gravity) * elapsedTime);
    //s = s0 + 0.5 * (v0+v) * t
    highp vec3 untransformedPosition = a_emissionPosition + 0.5 * (a_emissionVelocity + velocity) * elapsedTime;
    
    gl_Position = u_mvpMatrix * vec4(untransformedPosition,1.0);
    gl_PointSize = a_size.x / gl_Position.w;
    
    v_particleOpacity = max(0.0,min(1.0,(a_emissionAndDeathTimes.y - u_elapsedSeconds)/ max(a_size.y,0.00001)));
}
