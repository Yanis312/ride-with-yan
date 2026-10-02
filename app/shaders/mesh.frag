#version 460 core

#include <flutter/runtime_effect.glsl>

// Fond "shadergradient" : une surface ondulée (bruit de Perlin 3D) éclairée
// comme un tissu satiné, colorée par la palette de la scène.

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

// Classic Perlin noise 3D, Stefan Gustavson (glsl-noise, MIT).
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 mod289(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 permute(vec4 x) { return mod289(((x * 34.0) + 1.0) * x); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }
vec3 fade(vec3 t) { return t * t * t * (t * (t * 6.0 - 15.0) + 10.0); }

float cnoise(vec3 P) {
  vec3 Pi0 = floor(P);
  vec3 Pi1 = Pi0 + vec3(1.0);
  Pi0 = mod289(Pi0);
  Pi1 = mod289(Pi1);
  vec3 Pf0 = fract(P);
  vec3 Pf1 = Pf0 - vec3(1.0);
  vec4 ix = vec4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
  vec4 iy = vec4(Pi0.yy, Pi1.yy);
  vec4 iz0 = Pi0.zzzz;
  vec4 iz1 = Pi1.zzzz;
  vec4 ixy = permute(permute(ix) + iy);
  vec4 ixy0 = permute(ixy + iz0);
  vec4 ixy1 = permute(ixy + iz1);
  vec4 gx0 = ixy0 * (1.0 / 7.0);
  vec4 gy0 = fract(floor(gx0) * (1.0 / 7.0)) - 0.5;
  gx0 = fract(gx0);
  vec4 gz0 = vec4(0.5) - abs(gx0) - abs(gy0);
  vec4 sz0 = step(gz0, vec4(0.0));
  gx0 -= sz0 * (step(0.0, gx0) - 0.5);
  gy0 -= sz0 * (step(0.0, gy0) - 0.5);
  vec4 gx1 = ixy1 * (1.0 / 7.0);
  vec4 gy1 = fract(floor(gx1) * (1.0 / 7.0)) - 0.5;
  gx1 = fract(gx1);
  vec4 gz1 = vec4(0.5) - abs(gx1) - abs(gy1);
  vec4 sz1 = step(gz1, vec4(0.0));
  gx1 -= sz1 * (step(0.0, gx1) - 0.5);
  gy1 -= sz1 * (step(0.0, gy1) - 0.5);
  vec3 g000 = vec3(gx0.x, gy0.x, gz0.x);
  vec3 g100 = vec3(gx0.y, gy0.y, gz0.y);
  vec3 g010 = vec3(gx0.z, gy0.z, gz0.z);
  vec3 g110 = vec3(gx0.w, gy0.w, gz0.w);
  vec3 g001 = vec3(gx1.x, gy1.x, gz1.x);
  vec3 g101 = vec3(gx1.y, gy1.y, gz1.y);
  vec3 g011 = vec3(gx1.z, gy1.z, gz1.z);
  vec3 g111 = vec3(gx1.w, gy1.w, gz1.w);
  vec4 norm0 = taylorInvSqrt(vec4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
  g000 *= norm0.x;
  g010 *= norm0.y;
  g100 *= norm0.z;
  g110 *= norm0.w;
  vec4 norm1 = taylorInvSqrt(vec4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
  g001 *= norm1.x;
  g011 *= norm1.y;
  g101 *= norm1.z;
  g111 *= norm1.w;
  float n000 = dot(g000, Pf0);
  float n100 = dot(g100, vec3(Pf1.x, Pf0.yz));
  float n010 = dot(g010, vec3(Pf0.x, Pf1.y, Pf0.z));
  float n110 = dot(g110, vec3(Pf1.xy, Pf0.z));
  float n001 = dot(g001, vec3(Pf0.xy, Pf1.z));
  float n101 = dot(g101, vec3(Pf1.x, Pf0.y, Pf1.z));
  float n011 = dot(g011, vec3(Pf0.x, Pf1.yz));
  float n111 = dot(g111, Pf1);
  vec3 fade_xyz = fade(Pf0);
  vec4 n_z = mix(vec4(n000, n100, n010, n110), vec4(n001, n101, n011, n111), fade_xyz.z);
  vec2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
  return 2.2 * mix(n_yz.x, n_yz.y, fade_xyz.x);
}

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Hauteur de la surface : de longues vagues diagonales.
float height(vec2 p, float t) {
  return cnoise(vec3(p.x * 0.55, p.y * 1.1, t));
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  float aspect = uSize.x / uSize.y;
  vec2 p = vec2((uv.x - 0.5) * aspect, uv.y - 0.5) * 3.2;

  // Rotation pour des vagues en biais, comme une étoffe tendue.
  float a = -0.55;
  p = mat2(cos(a), sin(a), -sin(a), cos(a)) * p;

  float t = uTime * 0.18;
  float h = height(p, t);

  // Normale par différences finies : donne le relief et les reflets.
  float e = 0.03;
  float hx = height(p + vec2(e, 0.0), t) - h;
  float hy = height(p + vec2(0.0, e), t) - h;
  vec3 n = normalize(vec3(-hx / e * 0.32, -hy / e * 0.32, 1.0));

  // Couleur : dégradé horizontal c1 -> c2, crêtes vers c3, haut de l'écran vers c4.
  vec3 col = mix(uC1, uC2, smoothstep(-2.4, 2.4, p.x + 0.8 * h));
  col = mix(col, uC3, smoothstep(0.1, 1.3, h) * 0.85);
  col = mix(col, uC4, smoothstep(0.3, 1.8, -p.y + 0.4 * h) * 0.55);

  // Éclairage satiné : diffus doux + reflet spéculaire.
  vec3 light = normalize(vec3(-0.45, 0.55, 0.7));
  float diffuse = 0.62 + 0.38 * max(dot(n, light), 0.0);
  vec3 halfway = normalize(light + vec3(0.0, 0.0, 1.0));
  float spec = pow(max(dot(n, halfway), 0.0), 48.0) * 0.32;
  col = col * diffuse + vec3(spec);

  // Mélange avec la base de la scène et vignette douce.
  col = mix(uBase, col, uIntensity);
  float v = smoothstep(0.45, 1.25, length((uv - 0.5) * vec2(1.0, 1.15)) * 1.35);
  col = mix(col, uBase, v * 0.55);

  col += (hash(FlutterFragCoord().xy + fract(uTime)) - 0.5) * uGrain;
  fragColor = vec4(col, 1.0);
}
