//
//  Shaders.metal
//  Problem2
//
//  Created by Felix Naredi on 2019-08-15.
//  Copyright © 2019 Felix Naredi. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#define PUBLIC_SHADER(module, label) module ## __ ## label


// -------------------------------------------------------------------------------------------------
// MODULE: TextureRenderer
//

#define MODULE TextureRenderer

namespace MODULE {
  constant float4 rect_vertices[] = {
    {-1, -1, 0, 1},
    { 1, -1, 0, 1},
    {-1,  1, 0, 1},
    
    {-1,  1, 0, 1},
    { 1, -1, 0, 1},
    { 1,  1, 0, 1},
  };
  
  constant float2 rect_text_coords[] = {
    {0, 1},
    {1, 1},
    {0, 0},
    
    {0, 0},
    {1, 1},
    {1, 0},
  };
  
  struct rasterizer_t {
    float4 position [[position]];
    float2 text_coord;
    
    constexpr rasterizer_t(uint n)
      : position(rect_vertices[n])
      , text_coord(rect_text_coords[n])
    {}
  };
}

// Export global types from module namespace.
#define rasterizer_t MODULE::rasterizer_t

// Make public shader function labels.
#define vertex_shader PUBLIC_SHADER(TextureRenderer, vertex_shader)
#define fragment_shader PUBLIC_SHADER(TextureRenderer, fragment_shader)

vertex rasterizer_t vertex_shader(uint vid [[vertex_id]])
{ return vid; }

fragment float4
fragment_shader(rasterizer_t in [[stage_in]],
               texture2d<float> color_texture [[texture(0)]])
{
  constexpr sampler texture_sampler(mag_filter::linear, min_filter::linear);
  return color_texture.sample(texture_sampler, in.text_coord);
}

#undef fragment_shader
#undef vertex_shader
#undef rasterizer_t
#undef MODULE // TextureRenderer


// -------------------------------------------------------------------------------------------------
// MODULE: PolygonTexturePipeline
//

#define MODULE PolygonTexturePipeline

namespace MODULE {
  
  struct vertex_t
  {
    float2 position;
    float3 color;
  };
  
  struct rasterizer_t
  {
    float4 position [[position]];
    float4 color;
    
    constexpr rasterizer_t(vertex_t v)
      : position(float4(v.position, 0, 1))
      , color(float4(v.color, 1))
    {}
  };
}

// Export global types from module namespace.
#define vertex_t MODULE::vertex_t
#define rasterizer_t MODULE::rasterizer_t

// Make public shader function labels.
#define vertex_shader PUBLIC_SHADER(PolygonTexturePipeline, vertex_shader)
#define fragment_shader PUBLIC_SHADER(PolygonTexturePipeline, fragment_shader)

vertex
rasterizer_t vertex_shader(uint vid [[vertex_id]], constant vertex_t* vs [[buffer(0)]])
{ return vs[vid]; }

fragment
float4 fragment_shader(rasterizer_t v [[stage_in]])
{ return v.color; }

#undef vertex_shader
#undef fragment_shader
#undef rasterizer_t
#undef vertex_t
#undef MODULE // PolygonTexturePipeline
