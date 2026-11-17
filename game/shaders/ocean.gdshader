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

const int WAVE_COUNT = 5;

const SineWave[WAVE_COUNT] waves = SineWave[WAVE_COUNT](
	SineWave(vec2( 1.0,  0.0), 8.0, 0.5,  0.50),
	SineWave(vec2( 0.31, 0.95), 4.5, 0.3,  0.28),
	SineWave(vec2(-0.81, 0.59), 2.5, 5.6,  0.15),
	SineWave(vec2(-0.81,-0.59), 1.2, 1.2,  0.07),
	SineWave(vec2( 0.31,-0.95), 0.6, 2.4,  0.03)
);

float wave_get_coord(vec3 pos, vec2 dir) {
	return pos.x * dir.x + pos.z * dir.y;
}

vec2 wave_gradient(vec3 pos, float t) {
	// Base derivative is f(x)' = a * fi * cos(r * t + x * fi)
	// Partial derivative ??
	vec2 grad = vec2(0.0);
	for (int i = 0; i < WAVE_COUNT; i++) {
		float freq = 2.0f / waves[i].wavelength;
		float rho = waves[i].speed * freq;
		float phase = dot(pos.xz, waves[i].direction) * freq + t * rho;
		float d = waves[i].amplitude * freq * cos(phase);
		grad += d * waves[i].direction;
	}
	return grad;
}

void vertex() {
	// Called for every vertex the material is visible on.
	vec3 pos = VERTEX;
	float sum = 0.0f;
	for (int i = 0; i < WAVE_COUNT; i++) {
		float freq = 2.f / waves[i].wavelength;
		float rho = waves[i].speed * freq;
		float waveCoord = wave_get_coord(pos, waves[i].direction);
		float timeModulated = TIME * rho;
		sum += waves[i].amplitude * sin(waveCoord * freq + timeModulated);
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
