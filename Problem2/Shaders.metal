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
  
  constant float4 vertices[] = {
    {-1, -1, 0, 1},
    { 1, -1, 0, 1},
    {-1,  1, 0, 1},
    { 1,  1, 0, 1},
  };
  
  constant float2 text_coords[] = {
    {0, 1},
    {1, 1},
    {0, 0},
    {1, 0}
  };

  struct rasterizer_t {
    
    const float4 position [[position]];
    const float2 text_coord;
    
    constexpr rasterizer_t(uint n)
      : position(vertices[n])
      , text_coord(text_coords[n])
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

#undef fragment_shader
#undef vertex_shader
#undef rasterizer_t
#undef vertex_t
#undef MODULE // PolygonTexturePipeline


// -------------------------------------------------------------------------------------------------
// MODULE: LinearGradientTexture
//

#define MODULE LinearGradientTexture

namespace MODULE {
  
#define S 64
  
  constant float4 vertices[] = {
    { S,  0, 0.5, 1},
    { 0,  S, 1.0, 1},
    { 0, -S, 0.0, 1},
    {-S,  0, 0.5, 1}
  };
  
  struct rasterizer_t
  {
    const float4 position [[position]];
    
    rasterizer_t(uint n, constant float4x4& transform)
      : position(vertices[n] * transform)
    {}
    
    float delta() const { return (position.z - 0.5) * (2 * S); }
  };
  
#undef S
  
  constexpr float min(float a, float b) { return a < b ? a : b; }
  
  float4 min(float4 a, float4 b)
  { return {min(a.x, b.x), min(a.y, b.y), min(a.z, b.z), min(a.w, b.w)}; }
  
  constexpr float sgn(float a) { return a < 0 ? -1 : 1; }
  
  constexpr float4 binary_blue_brown_graph(float d)
  {
    if (d < 0) { return {0.8, 0.4, 0.2, 1.0}; }
    return {0.1, 0.2, 0.8, 1.0};
  }
  
  /// Returns a color based on the scalar `t` (ex. distance from a line). The derivative of the
  /// function in regards to `t` is smooth. It has the following limits:
  ///
  ///   lim(t -> inf+.) f(t) = pos_color
  ///   lim(t -> 0)     f(t) = peek_color
  ///   lim(t -> inf-.) f(t) = neg_color
  ///
  /// The colors for positive and negative values of `t` to not blend as `t` approaches zero.
  /// Instead the graf gets closer to the peek color.
  ///
  /// - Parameter neg_color: The color the graph approximates as `t` goes towards negative infinity.
  /// - Parameter pos_color: The color the graph approximates as `t` goes towards positive infinity.
  /// - Parameter peek_color: The color the grapch approximates as `t` goes towards zero.
  /// - Parameter slope: The steeper the slope the thinner the peek.
  /// - Parameter t: The depending variable.
  /// - Returns: A color on the graf.
  float4 smooth_peek_graph(float4 neg_color,
                           float4 pos_color,
                           float4 peek_color,
                           float4 slope,
                           float t)
  {
    // Cropping the maximum value of z since if no upper bound is used the texture starts to
    // flicker close to t = 0 because of Nan. values.
    const auto z(min(float4(1024, 1024, 1024, 1), 1 / (slope * t * t)));
    const auto h(t < 0 ? neg_color : pos_color);
    return (peek_color * z + h) / (z + 1);
    
    /// The math:
    ///
    /// The general shape of the graph can be visualized by plotting the curve of w where:
    ///
    ///   z = 1 / x^(2n)              n is a positive integer.
    ///   w = z / (z + 1)
    ///
    /// Let A be the value the graph should approach as x goes towards infinity and B the value it
    /// should approach as x goes towards negative infinity.
    ///
    /// Then using a function h(x) that are equal to A when x >= 0 and B when x < 0 its possible
    /// to fullfill the invariant above by simply adding w and h together.
    ///
    ///    lim (x -> inf.) (w + h(x)) =
    ///      0 + lim (x -> inf.) h(x) = A
    ///
    ///   lim (x -> inf-.) (w + h(x)) =
    ///     0 + lim (x -> inf-.) h(x) = B
    ///
    ///   Note: lim (x -> inf.) z = lim (x -> inf.) (1 / x^(2n)) = 0
    ///         lim (x -> inf.) w = lim (x -> inf.) (z / (z + 1)) = 0 / 1 = 0
    ///
    /// The problem by doing that is that there will be points close to x = 0 where the graph
    /// is greater than 1 (trying to stay in the bound [0, 1] as much as possible). However, since
    /// z is approaching infinity as x gets closer to 0 its possible to neglect the effect of the
    /// addition from h close to zero by rearanging the graph to:
    ///
    ///   y = (z + h(x)) / (z + 1)
    ///
    /// Lets see what happens in y when x approaches 0:
    ///
    ///                         lim (x -> 0) y =
    ///   lim (x -> 0) ((z + h(x)) / (z + 1))) =
    ///                   lim (x -> 0) (z / z) = 1
    ///
    /// Pretty solid!
  }
}

// Export global types from module namespace.
#define rasterizer_t MODULE::rasterizer_t

// Make public shader function labels.
#define vertex_shader PUBLIC_SHADER(LinearGradientTexture, vertex_shader)
#define fragment_shader PUBLIC_SHADER(LinearGradientTexture, fragment_shader)
#define smooth_peek_fragment_shader PUBLIC_SHADER(LinearGradientTexture, smooth_peek_fragment_shader)

vertex
rasterizer_t vertex_shader(uint vid [[vertex_id]], constant float4x4& transform [[buffer(0)]])
{ return {vid, transform}; }

fragment
float4 fragment_shader(rasterizer_t in [[stage_in]])
// { return MODULE::smooth_peek_graph({0.2, 0.3, 0.8, 1}, {0.8, 0.4, 0.1, 1}, 128, in.delta()); }
{
  return MODULE::smooth_peek_graph({0.8, 0.4, 0.2, 1},
                                   {0.1, 0.8, 0.5, 1},
                                   {0.5, 0.1, 0.8, 1},
                                   {0.8, 0.1, 0.8, 1},
                                   in.delta());
}

fragment
float4 smooth_peek_fragment_shader(rasterizer_t in [[stage_in]],
                                   constant float4* args [[buffer(0)]])
{ return MODULE::smooth_peek_graph(args[0], args[1], args[2], args[3], in.delta()); }


#undef fragment_shader
#undef vertex_shader
#undef rasterizer_t
#undef MODULE // LinearGradientTexture
