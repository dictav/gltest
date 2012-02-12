//
//  Shader.fsh
//  ES2
//
//  Created by Machine Admin on 10/03/19.
//  Copyright dictav 2010. All rights reserved.
//

precision mediump float;
varying vec2 texCoordVarying;
varying vec4 positionVarying;
uniform sampler2D texture;
const vec2 dxy = vec2(0.0021, 0.0016);
vec4 inverse(vec4 color);

// average mosaic
vec4 mosaic1(vec4 color)
{
    int nPixel = 10;
    float dx = float(nPixel)/480.0;
    float dy = float(nPixel)/480.0;
    int I = int(texCoordVarying.x / dx);
    int J = int(texCoordVarying.y / dy);
    vec2 texCoord = vec2(float(I) * dx, float(J)*dy);
    float x0 = texCoord.x;
    
    vec4 sum = vec4(0.0);
    int cnt = 0;
    for(int j = 0; j < nPixel; j++) {
        texCoord.y += dy;
        for (int i = 0; i < nPixel; i++) {
            texCoord.x += dx;
            sum += texture2D(texture, texCoord);
            cnt++;
        }
        texCoord.x = x0;
    }
    
    vec4 newColor;
    newColor.rgb = sum.rgb / float(cnt);
    return newColor;
}

// representation mosaic
vec4 mosaic2(vec4 color)
{
    int nPixel = 20;
    float dx = float(nPixel)/480.0;
    float dy = float(nPixel)/480.0;
    int I = int(texCoordVarying.x / dx);
    int J = int(texCoordVarying.y / dy);
    vec2 texCoord = vec2(float(I) * dx, float(J) * dy);
    vec4 newColor = texture2D(texture, texCoord);
    return newColor;
}

// point mosaic
vec4 mosaic3(vec4 color)
{
    float radius = 0.1;
    float width = 480.0;
    float height = 640.0;
    float aspect = width/height;
    vec2 point = vec2(0.2,0.3);
    vec2 texCoord = texCoordVarying;
    texCoord.y *= aspect;
    float dist = distance(point, texCoord);
    if (dist < radius) {
        return mosaic2(color);
    } else {
        return color;
    }
}

// 
vec4 poster(vec4 color)
{
    float nLevel = 4.0;
    vec3 k =  floor(color.rgb * (nLevel - 1.0) + vec3(0.5));
    vec4 newColor = color;
    newColor.rgb = k / (nLevel - 1.0);
    return newColor;
}

//average
vec4 smooth1(vec4 color)
{
    const int size = 5;
    int num = (size - 1)/2;
    const float weight = 1.0/float(size*size);
    const vec2 dxy = vec2(0.0021, 0.0016);
    vec3 col = color.rgb * weight;
    for (int j = -num; j <= num; j++) { 
    for (int i = -num; i <= num; i++) {
        if (i == 0 && j == 0) continue;
        col += texture2D(texture, texCoordVarying + dxy * vec2(float(i), float(j))).rgb * weight;
    }
    }
    return vec4(col,1.0);
}

//Gaussian
vec4 smooth2(vec4 color)
{
    const int size = 5;
    float sigma = 2.0;
    int num = (size - 1)/2;
    float weight = 1.0;
    vec3 col = color.rgb * weight;
    float sum = weight;
    for (int j = -num; j <= num; j++) {
        for (int i = -num; i <= num; i++) {
            if (i == 0 && j == 0) continue;
            vec2 point = dxy * vec2(float(i), float(j));
            weight = exp(-(point.x * point.x + point.y + point.y)/(2.0 * sigma * sigma));
            col += texture2D(texture, texCoordVarying + point).rgb * weight;
            sum += weight;
        }
    }
    
    return vec4(col/sum, 1.0);
}

void main()
{
    vec4 color = texture2D(texture, texCoordVarying);
	gl_FragColor = smooth1(color);
}
