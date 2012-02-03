//
//  Shader.fsh
//  ES2
//
//  Created by Machine Admin on 10/03/19.
//  Copyright dictav 2010. All rights reserved.
//

precision mediump float;
varying vec2 texCoordVarying;
uniform sampler2D texture;
void main()
{
	gl_FragColor = vec4(1.0) - texture2D(texture, texCoordVarying);
//	gl_FragColor = texture2D(texture, texCoordVarying);
}
