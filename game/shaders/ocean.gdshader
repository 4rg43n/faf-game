shader_type spatial;

// Sum of sines is
// Sum(a * sin(x * fi + t * r))

// Define all our values indexed by our arrays
struct SineWave {
	vec2  direction;
	float wavelength;
	float speed;
	float amplitude;
};

const int WAVE_COUNT = 32;
const float WARP_STRENGTH = 0.5;



const SineWave[WAVE_COUNT] waves = SineWave[WAVE_COUNT](
	SineWave(vec2( 1.00, 0.00), 8.000, 1.41, 0.2500),
	SineWave(vec2(-0.74, 0.68), 7.040, 1.72, 0.2050),
	SineWave(vec2( 0.09,-1.00), 6.195, 1.15, 0.1681),
	SineWave(vec2( 0.61, 0.79), 5.452, 0.84, 0.1378),
	SineWave(vec2(-0.98,-0.17), 4.798, 1.26, 0.1130),
	SineWave(vec2( 0.84,-0.54), 4.222, 1.27, 0.0927),
	SineWave(vec2(-0.26, 0.97), 3.715, 0.76, 0.0760),
	SineWave(vec2(-0.46,-0.89), 3.269, 0.74, 0.0623),
	SineWave(vec2( 0.94, 0.34), 2.877, 1.07, 0.0511),
	SineWave(vec2(-0.92, 0.38), 2.532, 0.89, 0.0419),
	SineWave(vec2( 0.42,-0.91), 2.228, 0.53, 0.0344),
	SineWave(vec2( 0.30, 0.95), 1.961, 0.67, 0.0282),
	SineWave(vec2(-0.87,-0.50), 1.725, 0.85, 0.0231),
	SineWave(vec2( 0.98,-0.22), 1.518, 0.60, 0.0189),
	SineWave(vec2(-0.57, 0.82), 1.336, 0.41, 0.0155),
	SineWave(vec2(-0.13,-0.99), 1.176, 0.60, 0.0127),
	SineWave(vec2( 0.77, 0.64), 1.035, 0.64, 0.0104),
	SineWave(vec2(-1.00, 0.04), 0.911, 0.39, 0.0086),
	SineWave(vec2( 0.71,-0.71), 0.801, 0.35, 0.0070),
	SineWave(vec2(-0.04, 1.00), 0.705, 0.52, 0.0058),
	SineWave(vec2(-0.64,-0.77), 0.621, 0.46, 0.0047),
	SineWave(vec2( 0.99, 0.13), 0.546, 0.27, 0.0039),
	SineWave(vec2(-0.82, 0.57), 0.481, 0.32, 0.0032),
	SineWave(vec2( 0.22,-0.98), 0.423, 0.42, 0.0026),
	SineWave(vec2( 0.50, 0.87), 0.372, 0.31, 0.0021),
	SineWave(vec2(-0.95,-0.30), 0.327, 0.20, 0.0018),
	SineWave(vec2( 0.91,-0.42), 0.288, 0.29, 0.0014),
	SineWave(vec2(-0.38, 0.92), 0.254, 0.32, 0.0012),
	SineWave(vec2(-0.34,-0.94), 0.223, 0.20, 0.0010),
	SineWave(vec2( 0.89, 0.46), 0.196, 0.17, 0.0008),
	SineWave(vec2(-0.97, 0.26), 0.173, 0.25, 0.0006),
	SineWave(vec2( 0.54,-0.84), 0.152, 0.23, 0.0005)
);

float wave_get_coord(vec3 pos, vec2 dir) {
	return pos.x * dir.x + pos.z * dir.y;
}

vec2 wave_gradient(vec3 pos, float t) {
	// Base derivative is f(x)' = a * fi * cos(r * t + x * fi)
	// Partial derivative ??
	vec2 grad = vec2(0.0);
	vec2 p = pos.xz;
	for (int i = 0; i < WAVE_COUNT; i++) {
		float freq = 2.0f / waves[i].wavelength;
		float rho = waves[i].speed * freq;
		float phase = dot(p, waves[i].direction) * freq + t * rho;
		float d = waves[i].amplitude * freq * cos(phase);
		grad += d * waves[i].direction;
		p -= d * waves[i].direction * WARP_STRENGTH;
	}
	return grad;
}

void vertex() {
	// Called for every vertex the material is visible on.
	vec3 pos = VERTEX;
	vec3 warped = pos;
	float sum = 0.0f;
	for (int i = 0; i < WAVE_COUNT; i++) {
		float freq = 2.f / waves[i].wavelength;
		float rho = waves[i].speed * freq;
		float waveCoord = wave_get_coord(warped, waves[i].direction);
		float timeModulated = TIME * rho;
		sum += waves[i].amplitude * sin(waveCoord * freq + timeModulated);
		float d = waves[i].amplitude * freq * cos(waveCoord * freq + timeModulated);
		warped.xz -= d * waves[i].direction * WARP_STRENGTH;
	}
	pos.y += sum;
	VERTEX = pos;
	vec2 g = wave_gradient(pos, TIME);
	NORMAL = normalize(vec3(-g.x, 1.0, -g.y));
}

void fragment() {
	ALBEDO    = vec3(66.f / 255.f, 154.f / 255.f, 255.f / 255.f);
	ROUGHNESS = 0.05;
	METALLIC  = 0.0;
	SPECULAR  = 0.6;
}
