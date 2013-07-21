const float energy = 0.75;
const float attraction = 0.05;
const float flowPower = 0.002;
const float spinPower = 0.001;

float hash( float n ) { return fract(sin(n)*43758.5453123); }
float fnoise( in vec3 x ) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*157.0 + 113.0*p.z;
    return mix(mix(mix(hash(n+  0.0), hash(n+  1.0),f.x),
                   mix(hash(n+157.0), hash(n+158.0),f.x),f.y),
               mix(mix(hash(n+113.0), hash(n+114.0),f.x),
                   mix(hash(n+270.0), hash(n+271.0),f.x),f.y),f.z);
}

void rX(inout vec3 p, float t) {
  float c = cos(t), s = sin(t); vec3 q = p;
  p.y = c * q.y - s * q.z;
  p.z = s * q.y + c * q.z;
}
void rY(inout vec3 p, float t) {
  float c = cos(t), s = sin(t); vec3 q = p;
  p.x = c * q.x + s * q.z;
  p.z = -s * q.x + c * q.z;
}
void rZ(inout vec3 p, float t) {
  float c = cos(t), s = sin(t); vec3 q = p;
  p.x = c * q.x - s * q.y;
  p.y = s * q.x + c * q.y;
}

float sdBox(vec3 p, vec3 b) {
  vec3 d = abs(p) - b;
  return min(max(d.x, max(d.y, d.z)), 0.) + length(max(d, 0.));
}
float sdSphere(vec3 p, float s) {
  return length(p) - s;
}
float opU(float d1, float d2) { return min(d1,d2); }
float opS(float d1, float d2) { return max(-d1, d2); }
float opI(float d1, float d2) { return max(d1,d2); }

// Change this.
float dist(vec3 p) {
  rX(p, time * .025);
  vec3 ip = floor(p);
  vec3 fp = fract(p) - .5;
  float tm = time * .2;
  float tp = PI * 2.;
  float seed = ip.x + ip.y + ip.z;
  fp += rand3(seed) * 0.15;
  rX(fp, rand(ip.x) * tp + tm * (rand(ip.x) - .5));
  rY(fp, rand(ip.y) * tp + tm * (rand(ip.y) - .5));
  rZ(fp, rand(ip.z) * tp + tm * (rand(ip.z) - .5));
  float sc = .2;
  if (rand(seed) > .25)
    return sdBox(fp, vec3(sc));
  return sdSphere(fp, sc);
}

vec3 grad(vec3 p, float d) {
  vec3 x = vec3(d, 0., 0.), y = vec3(0., d, 0.), z = vec3(0., 0., d);
  return vec3(
    dist(p + x) - dist(p - x),
    dist(p + y) - dist(p - y),
    dist(p + z) - dist(p - z)
  ) / (2. * d);
}

vec3 flow(vec3 p, float d) {
  vec3 x = vec3(d, 0., 0.), y = vec3(0., d, 0.), z = vec3(0., 0., d);
  return vec3(
    fnoise(p + x) - fnoise(p - x),
    fnoise(p + y) - fnoise(p - y),
    fnoise(p + z) - fnoise(p - z)
  ) / (2. * d);
}

void stepPos(in float i, in vec4 prevPos, in vec4 pos, out vec4 nextPos) {
  float seed = i * 0.01;

  float t = i / count;
  vec3 p = pos.xyz;
  vec3 vel = (p - prevPos.xyz) * energy;

  vec3 g = grad(p, 0.01);
  float phi = dist(p);
  if (phi > 0.) {
    float lg = length(g);
    vel -= attraction * phi * g / (lg * lg);
  }

  vel += flowPower * flow(p - time * .1 + t * 100., .01) * .2;
  vel += flowPower * flow(p *.1 + time * .25, .01) * .2;
  vel += rand3(seed + time) * 0.0005;

  vec3 lp = vec3(cos(time * .267), sin(time * 0.157), cos(time * .345)) * 2.;

  nextPos.xyz = p + vel;
  nextPos.w = max(0., -dot(g, normalize(p - lp))) + min(0., phi) * 10.;
}