#version 460 core

#include <flutter/runtime_effect.glsl>

// Fond "lampe à lave" : quatre halos colorés qui dérivent sur une base,
// avec une légère déformation du domaine et un grain fin.

uniform vec2 uSize;
uniform float uTime;
uniform vec3 uBase;
uniform vec3 uC1;
uniform vec3 uC2;
uniform vec3 uC3;
uniform vec3 uC4;
uniform float uIntensity;
uniform float uGrain;

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float blob(vec2 p, vec2 center, float radius) {
  vec2 d = p - center;
  return exp(-dot(d, d) / (radius * radius));
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  float aspect = uSize.x / uSize.y;
  vec2 p = vec2(uv.x * aspect, uv.y);
  float t = uTime;

  // Déformation douce pour des contours organiques.
  p += 0.06 * vec2(sin(p.y * 3.1 + t * 0.7), cos(p.x * 2.7 - t * 0.6));

  vec2 c1 = vec2(aspect * (0.22 + 0.14 * sin(t * 0.31)), 0.28 + 0.16 * cos(t * 0.27));
  vec2 c2 = vec2(aspect * (0.80 + 0.12 * cos(t * 0.23)), 0.22 + 0.14 * sin(t * 0.35));
  vec2 c3 = vec2(aspect * (0.68 + 0.16 * sin(t * 0.19 + 1.7)), 0.82 + 0.10 * cos(t * 0.29));
  vec2 c4 = vec2(aspect * (0.18 + 0.12 * cos(t * 0.25 + 0.9)), 0.84 + 0.12 * sin(t * 0.21));

  float r = 0.42 * max(aspect, 1.0);
  float w1 = blob(p, c1, r);
  float w2 = blob(p, c2, r * 0.9);
  float w3 = blob(p, c3, r * 1.05);
  float w4 = blob(p, c4, r * 0.85);

  vec3 col = uBase;
  col = mix(col, uC1, w1 * uIntensity);
  col = mix(col, uC2, w2 * uIntensity);
  col = mix(col, uC3, w3 * uIntensity);
  col = mix(col, uC4, w4 * uIntensity);

  col += (hash(FlutterFragCoord().xy + fract(t)) - 0.5) * uGrain;

  fragColor = vec4(col, 1.0);
}
