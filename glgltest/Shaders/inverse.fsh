precision mediump float;
vec4 inverse(vec4 color)
{
    vec4 newColor;
    newColor.rgb = vec3(1.0) - color.rgb;
    newColor.a = color.a;
    return newColor;
}
