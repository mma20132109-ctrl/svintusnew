#version 330

layout(std140) uniform DynamicTransforms {
    mat4 ModelViewMat;
    vec4 ColorModulator;
    vec3 ModelOffset;
    mat4 TextureMat;
};

uniform sampler2D Sampler0;

in vec4 vertexColor;
in vec2 localPos;
flat in vec2 rectSize;
flat in vec2 params;

out vec4 fragColor;

float sdRoundBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

float hash(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 halfSize = rectSize * 0.5;
    float radius = min(params.x, min(halfSize.x, halfSize.y));
    float d = sdRoundBox(localPos - halfSize, halfSize, radius);
    float aa = max(fwidth(d), 1e-4);
    float alpha = clamp(0.5 - d / aa, 0.0, 1.0) * clamp(params.y, 0.0, 1.0);
    if (alpha <= 0.002) {
        discard;
    }

    vec2 uv = gl_FragCoord.xy / (vec2(textureSize(Sampler0, 0)) * 2.0);
    vec3 color = texture(Sampler0, uv).rgb;
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(luma), color, 1.25);
    color = mix(color, vertexColor.rgb, vertexColor.a);
    color += (hash(gl_FragCoord.xy) - 0.5) * 0.02;

    fragColor = vec4(color, alpha) * ColorModulator;
}
