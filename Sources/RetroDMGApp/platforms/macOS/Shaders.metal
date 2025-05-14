//
//  Shaders.metal
//  Retro
//
//  Created by Glenn Hevey on 7/1/2024.
//

 #include <metal_stdlib>
 using namespace metal;
 struct VertexIn {
     float3 position;
     float4 color;
 };

 struct VertexOut {
     float4 position [[ position ]];
     float4 color;
 };

 vertex VertexOut basic_vertex_function(const device VertexIn *vertices [[ buffer(0) ]],
                                            uint vertexID [[ vertex_id  ]]) {
     VertexOut vOut;
     vOut.position = float4(vertices[vertexID].position,1);
     vOut.color = vertices[vertexID].color;
     vOut.position.y = -vOut.position.y;
     return vOut;
 }

 fragment float4 basic_fragment_function(VertexOut vIn [[ stage_in ]]) {
     return vIn.color;
 }
