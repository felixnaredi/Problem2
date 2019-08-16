//
//  Shaders.metal
//  Problem2
//
//  Created by Felix Naredi on 2019-08-15.
//  Copyright © 2019 Felix Naredi. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct RasterizerData {
  float4 position [[position]];
  float2 textureCoord;
};

constant float4 rectVertices[] = {
  {-1, -1, 0, 1},
  { 1, -1, 0, 1},
  {-1,  1, 0, 1},
  
  {-1,  1, 0, 1},
  { 1, -1, 0, 1},
  { 1,  1, 0, 1},
};

constant float2 rectTextCoords[] = {
  {0, 0},
  {1, 0},
  {0, 1},
  
  {0, 1},
  {1, 0},
  {1, 1},
};

vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]])
{
  return RasterizerData({
    .position = rectVertices[vertexID],
    .textureCoord = rectTextCoords[vertexID]
  });
}

fragment float4
samplingShader(RasterizerData in [[stage_in]],
               texture2d<float> colorTexture [[texture(0)]])
{
  constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
  return colorTexture.sample(textureSampler, in.textureCoord);
}
