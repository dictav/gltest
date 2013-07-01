//
//  Shader.vsh
//  ES2
//
//  Created by Machine Admin on 10/03/19.
//  Copyright dictav 2010. All rights reserved.
//

attribute vec4 position;
attribute vec2 texCoord;
varying vec2 texCoordVarying;

void main()
{
	gl_Position =  position;
	texCoordVarying = texCoord;
}
