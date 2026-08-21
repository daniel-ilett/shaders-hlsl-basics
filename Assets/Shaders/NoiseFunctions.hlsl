inline float2 randomVector(float2 seed, float timeOffset = 0.0f)
{
    float a = sin(dot(seed, float2(12.9898, 78.233))) * 43758.5453 + timeOffset;
    return float2(sin(a), cos(a));
}

inline float perlinNoiseSingleOctave(float2 uv, float timeOffset = 0.0f)
{
    float2 i = floor(uv);
    float2 f = frac(uv);

    float2 c0 = i;
    float2 c1 = i + float2(1.0, 0.0);
    float2 c2 = i + float2(0.0, 1.0);
    float2 c3 = i + float2(1.0, 1.0);
    
    float r0 = dot(randomVector(c0, timeOffset), f);
    float r1 = dot(randomVector(c1, timeOffset), f - float2(1, 0));
    float r2 = dot(randomVector(c2, timeOffset), f - float2(0, 1));
    float r3 = dot(randomVector(c3, timeOffset), f - float2(1, 1));
    
    f = f * f * (3.0 - 2.0 * f);

    float bottomOfGrid = lerp(r0, r1, f.x);
    float topOfGrid = lerp(r2, r3, f.x);
    float t = lerp(bottomOfGrid, topOfGrid, f.y) * 0.5f + 0.5f;
    return t;
}

float perlinNoise(float2 uv, float scale, float timeOffset = 0.0f)
{
    float t = 0.0;
    float2 scaledUV = uv * scale;

    float freq = 4.0f;
    float amp = 0.5f;
    t += perlinNoiseSingleOctave(float2(scaledUV.x / freq, scaledUV.y / freq), timeOffset) * amp;

    freq = 2.0f;
    amp = 0.25f;
    t += perlinNoiseSingleOctave(float2(scaledUV.x / freq, scaledUV.y / freq), timeOffset) * amp;

    freq = 1.0f;
    amp = 0.125f;
    t += perlinNoiseSingleOctave(float2(scaledUV.x / freq, scaledUV.y / freq), timeOffset) * amp;

    return t;
}

// Based on code by Inigo Quilez: https://iquilezles.org/articles/voronoilines/
void voronoiNoise(float2 uv, float cellDensity, out float distFromCenter, out float distFromEdge, float timeOffset = 0.0f)
{
    // Cell position variables.
    int2 cell = floor(uv * cellDensity);
    float2 posInCell = frac(uv * cellDensity);

    // Initialize output values.
    distFromCenter = 8.0f;
    distFromEdge = 8.0f;
    
    // Stuff to remember between passes.
    float2 cellOffsets[3][3];
    float2 closestOffset;
    
    int x, y;
    
    // Precalculate random offsets pass.
    [unroll(9)]
    for(y = -1; y <= 1; ++y)
    for(x = -1; x <= 1; ++x)
    {
        float2 cellToCheck = float2(x, y);
        float2 rand = randomVector(cell + cellToCheck, timeOffset) * 0.5f + 0.5f;
        cellOffsets[x + 1][y + 1] = float2(cellToCheck) - posInCell + rand;
    }
      
    // Distance from closest cell center pass.
    [unroll(9)]
    for(y = -1; y <= 1; ++y)
    for(x = -1; x <= 1; ++x)
    {
        float2 cellOffset = cellOffsets[x + 1][y + 1];
        float distToPoint = dot(cellOffset, cellOffset);

        if(distToPoint < distFromCenter)
        {
            distFromCenter = distToPoint;
            closestOffset = cellOffset;
        }
    }
    
    // Distance from edge between two closest cell centers pass.
    [unroll(9)]
    for(y = -1; y <= 1; ++y)
    for(x = -1; x <= 1; ++x)
    {
        float2 cellOffset = cellOffsets[x + 1][y + 1];
        float distFromCurrentEdge = dot(0.5f * (cellOffset + closestOffset), normalize(cellOffset - closestOffset));

        distFromEdge = min(distFromEdge, distFromCurrentEdge);
    }
}
