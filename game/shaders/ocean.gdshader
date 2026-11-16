shader_type spatial;

// Sum of sines is
// Sum(a * sin(x * fi + t * r))

// Define all our values indexed by our arrays
struct SineWave {
	float wavelength;
	float speed;
	float amplitude;
};

const SineWave[5] waves = SineWave[5](SineWave(8.0f, 0.15f, 0.50f), SineWave(4.5f, 0.30f, 0.28f), SineWave(2.5f, 0.60f, 0.15f), SineWave(1.2f, 1.20f, 0.07f), SineWave(0.6f, 2.40f, 0.03f));

void vertex() {
	// Called for every vertex the material is visible on.
	vec3 pos = VERTEX;
	float sum = 0.0f;
	for (int i = 0; i < 5; i++) {
		float freq = 2.f / waves[i].wavelength;
		float rho = waves[i].speed * freq;
		sum += waves[i].amplitude * sin((pos.x + pos.z) * freq + TIME * rho);
	}
	pos.y += sum;
	VERTEX = pos;
	
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = vec3(0.1f, 0.2f, 1);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
