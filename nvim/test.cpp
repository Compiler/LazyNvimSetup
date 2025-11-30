#include <vk_engine.h>
#include <immintrin.h>
#include <fmt/core.h>

void avx2_add_i64(const int64_t* a, const int64_t* b, int64_t* out, size_t n) {
    const size_t step = 4; 
    size_t i = 0;

    for (; i + step <= n; i += step) {
        __m256i va = _mm256_loadu_si256(reinterpret_cast<const __m256i*>(a + i));
        __m256i vb = _mm256_loadu_si256(reinterpret_cast<const __m256i*>(b + i));
        __m256i vc = _mm256_add_epi64(va, vb);
        _mm256_storeu_si256(reinterpret_cast<__m256i*>(out + i), vc);
    }

    for (; i < n; ++i) out[i] = a[i] + b[i];
}

int main(int argc, char* argv[]) {

    VulkanEngine engine;

    fmt::print("Root dir: {}\n", PROJ_ROOT);
    engine.init();	

    engine.run();	

    engine.cleanup();	

    return 0;
}
