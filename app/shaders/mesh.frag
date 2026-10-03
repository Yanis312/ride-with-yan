#version 460 core

#include <flutter/runtime_effect.glsl>

// Fond "shadergradient" : une surface ondulée (vagues sinusoïdales) éclairée
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

// Toucher : jusqu'à 4 ondes (x, y en pixels, âge en secondes, active 0/1),
// la lumière sous le doigt (x, y, intensité) et la couleur de la lumière.
uniform vec4 uR0;
uniform vec4 uR1;
uniform vec4 uR2;
uniform vec4 uR3;
uniform vec3 uFinger;
uniform vec3 uGlow;

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Anneau d'une onde : il s'élargit et s'éteint. [push] accumule la poussée
// vers l'extérieur qui déforme les vagues sous l'anneau.
float ripple(vec4 r, vec2 frag, inout vec2 push) {
  if (r.w < 0.5) return 0.0;
  vec2 d = frag - r.xy;
  float dist = length(d);
  float radius = r.z * 560.0;
  float width = 50.0 + r.z * 70.0;
  float ring = exp(-pow((dist - radius) / width, 2.0)) * exp(-r.z * 1.5);
  push += (d / max(dist, 1.0)) * ring;
  return ring;
}

// Hauteur de la surface : de longues vagues diagonales.
// Somme de sinus avec déformation : même rendu "étoffe satinée" que le
// bruit de Perlin, pour une fraction du coût (important sur iPhone).
float height(vec2 p, float t) {
  float a = sin(p.x * 0.9 + t * 0.9 + sin(p.y * 0.7 + t * 0.5) * 1.6);
  float b = sin(p.y * 1.5 - t * 0.7 + sin(p.x * 0.8 - t * 0.4) * 1.3);
  float c = sin((p.x + p.y) * 0.65 + t * 0.6);
  return a * 0.6 + b * 0.35 + c * 0.35;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  float aspect = uSize.x / uSize.y;
  vec2 p = vec2((uv.x - 0.5) * aspect, uv.y - 0.5) * 3.2;

  // Rotation pour des vagues en biais, comme une étoffe tendue.
  float a = -0.55;
  p = mat2(cos(a), sin(a), -sin(a), cos(a)) * p;

  vec2 frag = FlutterFragCoord().xy;
  vec2 push = vec2(0.0);
  float ring = ripple(uR0, frag, push) + ripple(uR1, frag, push) + ripple(uR2, frag, push) + ripple(uR3, frag, push);
  p += push * 0.22;

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

  // Lumière liquide : l'anneau des ondes et le halo sous le doigt.
  float fd = length(frag - uFinger.xy);
  float halo = uFinger.z * exp(-(fd * fd) / (150.0 * 150.0));
  col = mix(col, uGlow, clamp(ring * 0.7 + halo * 0.4, 0.0, 0.9));
  col += vec3(1.0, 0.95, 0.8) * (ring * 0.28 + halo * 0.12);

  col += (hash(FlutterFragCoord().xy + fract(uTime)) - 0.5) * uGrain;
  fragColor = vec4(col, 1.0);
}
