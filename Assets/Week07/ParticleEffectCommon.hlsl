#ifndef PARTICLE_EFFECT_COMMON_INCLUDED
#define PARTICLE_EFFECT_COMMON_INCLUDED

struct VertexInputs {
    float3 positionOS;
    float3 normalOS;
    float2 uv;
};

#define STRUCTURED_IDX_BUFFER(RW, NAME) \
RW##StructuredBuffer<uint> NAME ##_IdxBuffer

#define STRUCTURED_ATT_BUFFER(RW, NAME) \
RW##StructuredBuffer<VertexInputs> NAME ##_AttBuffer


#ifdef PARTICLE_EFFECT_COMPUTE
  
    ParticleParams ParticleEffect_Params;

    STRUCTURED_ATT_BUFFER(RW, ParticleSample);
    STRUCTURED_IDX_BUFFER(RW, ParticleSample);

    STRUCTURED_ATT_BUFFER(RW, ParticleWhole);
    STRUCTURED_IDX_BUFFER(RW, ParticleWhole);
#else

    STRUCTURED_ATT_BUFFER(, ParticleWhole);
    STRUCTURED_IDX_BUFFER(, ParticleWhole);

    VertexInputs GetVertexInputs(uint vid) {
        uint idx = ParticleWhole_IdxBuffer[vid];
        VertexInput i = ParticleWhole_AttBuffer[idx];
        return i;
    }

#endif //PARTICLE_EFFECT_COMPUTE
#endif //PARTICLE_EFFECT_COMMON_INCLUDED