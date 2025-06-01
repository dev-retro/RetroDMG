struct VertexIn {
    float3 position;
    float4 color;
};

struct VertexOut {
    float4 position : SV_POSITION;
    float4 color   : COLOR0;
};

[shader("vertex")]
VertexOut basic_vertex_function(
    VertexIn vertices[1],
    uint vertexID : SV_VertexID)
{
    VertexOut vOut;
    vOut.position = float4(vertices[vertexID].position, 1.0);
    vOut.color = vertices[vertexID].color;
    vOut.position.y = -vOut.position.y;
    return vOut;
}

[shader("fragment")]
float4 basic_fragment_function(VertexOut vIn) : SV_Target
{
    return vIn.color;
}
