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
    { 1,  1, 0, 1},
  };
  
  constant float2 rect_text_coords[] = {
    {0, 1},
    {1, 1},
    {0, 0},
    {1, 0}
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


// -------------------------------------------------------------------------------------------------
// MODULE: LinearGradientTexture
//

#define MODULE LinearGradientTexture

namespace MODULE {
  
  constant float4 vertices[] = {
    { 32,  0,  0.5, 1},
    { 0,  32,  1.0, 1},
    { 0, -32,  0.0, 1},
    {-32,  0,  0.5, 1}
  };
  
  struct rasterizer_t
  {
    const float4 position [[position]];
    
    rasterizer_t(uint n, constant float4x4& transform)
      : position(vertices[n] * transform)
    {}
    
    float delta() const { return (position.z - 0.5) * 64; }
  };
  
  constexpr float min(float a, float b) { return a < b ? a : b; }
  constexpr float sgn(float a) { return a < 0 ? -1 : 1; }
  
  constexpr float4 binary_blue_brown_graph(float d)
  {
    if (d < 0) { return {0.8, 0.4, 0.2, 1.0}; }
    return {0.1, 0.2, 0.8, 1.0};
  }
  
  /// Returns a color based on the scalar `t` (ex. distance from a line). The derivative of the
  /// function in regards to `t` is smooth. It has the following limits:
  ///
  ///   lim(t -> inf+.) f(t) = poscolor
  ///   lim(t -> 0)     f(t) = {1, 1, 1, 1}
  ///   lim(t -> inf-.) f(t) = negcolor
  ///
  /// The colors to not blend as `t` approaches zero. Instead the graf gets closer to white. The
  /// white area are the signature "peek" if the function.
  ///
  /// - Parameter negcolor: The color the graph approximates as `t` goes towards negative infinity.
  /// - Parameter poscolor: The color the graph approximates as `t` goes towards positive infinity.
  /// - Parameter peek_slope: The steeper the slope the thinner the peek.
  /// - Parameter t: Scalar value.
  /// - Returns: A color on the graf.
  float4 smooth_peek_graph(float4 negcolor, float4 poscolor, float peek_slope, float t)
  {
    const float y(min(64, 1 / (peek_slope * (t * t))));
    const auto u = (negcolor + poscolor) / 2;
    const auto k = u - negcolor;
    return (y + u + sgn(t) * k) / (y + 1);
  }
}

// Export global types from module namespace.
#define rasterizer_t MODULE::rasterizer_t

// Make public shader function labels.
#define vertex_shader PUBLIC_SHADER(LinearGradientTexture, vertex_shader)
#define fragment_shader PUBLIC_SHADER(LinearGradientTexture, fragment_shader)

vertex
rasterizer_t vertex_shader(uint vid [[vertex_id]], constant float4x4& transform [[buffer(0)]])
{ return {vid, transform}; }

fragment
float4 fragment_shader(rasterizer_t in [[stage_in]])
{ return MODULE::smooth_peek_graph({0.2, 0.3, 0.8, 1}, {0.8, 0.4, 0.1, 1}, 128, in.delta()); }


#undef vertex_shader
#undef fragment_shader
#undef rasterizer_t
#undef MODULE // LinearGradientTexture
