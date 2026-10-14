#!/usr/bin/env ruby
# frozen_string_literal: true

# Renders a hand-drawn "小黑" style article illustration from a JSON spec.
#
# This is the deterministic fallback for the ian-xiaohei-illustrations workflow:
# use it when an image-generation tool is unavailable, or when an illustration
# must be reproducible and editable from source control.
#
# Usage:
#   ruby xiaohei_sketch.rb --spec spec.json --out illustration.svg [--png illustration.png] [--width 1600]

require "json"
require "optparse"
require "fileutils"
require "shellwords"
require "tmpdir"

class Wobble
  def initialize(seed)
    @state = (seed.to_i % 2_147_483_647)
    @state = 20_261_012 if @state <= 0
  end

  def next_float
    @state = (@state * 48_271) % 2_147_483_647
    (@state.to_f / 2_147_483_647) * 2.0 - 1.0
  end

  def jitter(amount)
    next_float * amount
  end
end

module Sketch
  COLORS = {
    "black" => "#111111",
    "red" => "#d2452f",
    "orange" => "#e07a1f",
    "blue" => "#2f6fb0",
    "gray" => "#8a8a8a"
  }.freeze

  FONT_STACK = "'Songti SC', 'Hiragino Sans GB', 'Kai', 'STKaiti', serif"

  module_function

  def color_for(value)
    COLORS[value.to_s] || value.to_s
  end

  def round(value)
    format("%.1f", value.to_f)
  end

  # Hand-drawn straight-ish line between two points.
  def line_path(rng, from, to, wobble)
    x1, y1 = from
    x2, y2 = to
    dx = x2 - x1
    dy = y2 - y1
    length = Math.sqrt((dx * dx) + (dy * dy))
    segments = [[(length / 90.0).round, 2].max, 9].min
    points = []
    (0..segments).each do |index|
      t = index.to_f / segments
      base_x = x1 + (dx * t)
      base_y = y1 + (dy * t)
      edge = (index.zero? || index == segments) ? 0.25 : 1.0
      points << [base_x + rng.jitter(wobble) * edge, base_y + rng.jitter(wobble) * edge]
    end
    smooth_path(points)
  end

  def smooth_path(points)
    return "" if points.empty?

    d = +"M #{round(points[0][0])} #{round(points[0][1])}"
    (1...points.length).each do |index|
      prev = points[index - 1]
      cur = points[index]
      cx = (prev[0] + cur[0]) / 2.0
      cy = (prev[1] + cur[1]) / 2.0
      d << " Q #{round(prev[0])} #{round(prev[1])} #{round(cx)} #{round(cy)}"
    end
    last = points[-1]
    d << " L #{round(last[0])} #{round(last[1])}"
    d
  end

  def rough_rect(rng, x, y, width, height, wobble)
    points = []
    steps = 7
    # top
    (0..steps).each { |i| t = i.to_f / steps; points << [x + (width * t), y + rng.jitter(wobble)] }
    # right
    (1..steps).each { |i| t = i.to_f / steps; points << [x + width + rng.jitter(wobble), y + (height * t)] }
    # bottom
    (1..steps).each { |i| t = i.to_f / steps; points << [x + width - (width * t), y + height + rng.jitter(wobble)] }
    # left
    (1...steps).each { |i| t = i.to_f / steps; points << [x + rng.jitter(wobble), y + height - (height * t)] }
    points << points[0]
    smooth_path(points)
  end

  def rough_circle(rng, cx, cy, radius, wobble, steps = 26)
    points = (0...steps).map do |index|
      angle = (index.to_f / steps) * Math::PI * 2
      r = radius + rng.jitter(wobble)
      [cx + (Math.cos(angle) * r), cy + (Math.sin(angle) * r)]
    end
    points << points[0]
    smooth_path(points)
  end

  # A tangled knot: several overlapping rough loops, used for "real problem" style metaphors.
  def scribble(rng, cx, cy, radius, loops, wobble)
    paths = []
    loops.times do |loop_index|
      points = []
      steps = 40
      phase = loop_index * 1.7
      (0..steps).each do |index|
        t = index.to_f / steps
        angle = (t * Math::PI * 2 * (1.6 + (loop_index * 0.22))) + phase
        r = radius * (0.42 + (0.5 * Math.sin((t * Math::PI * 2 * (loop_index + 1.5)) + phase).abs)) + rng.jitter(wobble)
        points << [cx + (Math.cos(angle) * r), cy + (Math.sin(angle) * r)]
      end
      paths << smooth_path(points)
    end
    paths
  end

  def arrow_head(rng, from, to, size, color)
    x1, y1 = from
    x2, y2 = to
    angle = Math.atan2(y2 - y1, x2 - x1)
    left = [x2 - (Math.cos(angle - 0.5) * size), y2 - (Math.sin(angle - 0.5) * size)]
    right = [x2 - (Math.cos(angle + 0.5) * size), y2 - (Math.sin(angle + 0.5) * size)]
    line_path(rng, [x2, y2], left, 1.0).then { |a| [a, line_path(rng, [x2, y2], right, 1.0)] }
                .then { |a, b| "<path d=\"#{a}\" fill=\"none\" stroke=\"#{color_for(color)}\" stroke-width=\"3\" stroke-linecap=\"round\"/>"
                               "<path d=\"#{b}\" fill=\"none\" stroke=\"#{color_for(color)}\" stroke-width=\"3\" stroke-linecap=\"round\"/>" }
  end

  def render_element(rng, element, svg)
    type = element["type"].to_s
    color = color_for(element["color"] || "black")
    width = element["width"] || 3
    wobble = (element["wobble"] || 2.4).to_f

    case type
    when "line"
      svg << %(<path d="#{line_path(rng, element["from"], element["to"], wobble)}" fill="none" stroke="#{color}" stroke-width="#{width}" stroke-linecap="round"/>)
    when "rect"
      x, y = element["at"]
      svg << %(<path d="#{rough_rect(rng, x, y, element["w"], element["h"], wobble)}" fill="#{element["fill"] || "none"}" stroke="#{color}" stroke-width="#{width}" stroke-linecap="round"/>)
    when "circle"
      cx, cy = element["at"]
      svg << %(<path d="#{rough_circle(rng, cx, cy, element["r"], wobble)}" fill="#{element["fill"] || "none"}" stroke="#{color}" stroke-width="#{width}" stroke-linecap="round"/>)
    when "blob"
      cx, cy = element["at"]
      rx = element["rx"]
      ry = element["ry"]
      points = []
      steps = 30
      (0...steps).each do |index|
        angle = (index.to_f / steps) * Math::PI * 2
        points << [cx + (Math.cos(angle) * rx) + rng.jitter(wobble * 1.4), cy + (Math.sin(angle) * ry) + rng.jitter(wobble * 1.2)]
      end
      points << points[0]
      svg << %(<path d="#{smooth_path(points)}" fill="#{element["fill"] || "#111111"}" stroke="#{color}" stroke-width="#{width}"/>)
    when "scribble"
      cx, cy = element["at"]
      scribble(rng, cx, cy, element["r"], element["loops"] || 3, wobble).each do |path|
        svg << %(<path d="#{path}" fill="none" stroke="#{color}" stroke-width="#{width}" stroke-linecap="round" opacity="#{element["opacity"] || 1}"/>)
      end
    when "arrow"
      svg << %(<path d="#{line_path(rng, element["from"], element["to"], wobble * 0.7)}" fill="none" stroke="#{color}" stroke-width="#{width}" stroke-linecap="round"/>)
      svg << arrow_head(rng, element["from"], element["to"], element["head"] || 16, color)
    when "arrowhead"
      svg << arrow_head(rng, element["from"], element["to"], element["head"] || 16, color)
    when "polyline"
      svg << %(<path d="#{smooth_path(element["points"])}" fill="#{element["fill"] || "none"}" stroke="#{color}" stroke-width="#{width}" stroke-linecap="round" stroke-linejoin="round"/>)
    when "label"
      x, y = element["at"]
      font_size = element["size"] || 26
      rotate = element["rotate"] || rng.jitter(3.5).round(1)
      anchor = element["anchor"] || "start"
      weight = element["weight"] || 500
      lines = element["text"].to_s.split("\n")
      svg << %(<g transform="rotate(#{rotate} #{x} #{y})">)
      lines.each_with_index do |line, index|
        svg << %(<text x="#{x}" y="#{y + (index * font_size * 1.35)}" fill="#{color}" font-family="#{FONT_STACK}" font-size="#{font_size}" font-weight="#{weight}" text-anchor="#{anchor}">#{escape(line)}</text>)
      end
      svg << "</g>"
      if element["underline"]
        svg << %(<path d="#{line_path(rng, [x, y + 9], [x + element["underline"], y + 9], 1.6)}" fill="none" stroke="#{color}" stroke-width="2.4" stroke-linecap="round" opacity="0.75"/>)
      end
    when "dot"
      x, y = element["at"]
      r = element["r"] || 6
      svg << %(<circle cx="#{x}" cy="#{y}" r="#{r}" fill="#{color}"/>)
    else
      raise ArgumentError, "unknown element type: #{type}"
    end
  end

  def escape(text)
    text.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
  end

  def build(spec)
    width = (spec["size"] || [1600, 900])[0].to_i
    height = (spec["size"] || [1600, 900])[1].to_i
    rng = Wobble.new(spec["seed"] || 20_261_012)
    svg = +%(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{width} #{height}" width="#{width}" height="#{height}">)
    svg << %(<rect width="#{width}" height="#{height}" fill="#ffffff"/>)
    Array(spec["elements"]).each { |element| render_element(rng, element, svg) }
    svg << "</svg>"
    svg
  end
end

options = { width: nil, png: nil }
spec_path = nil
out_path = nil

OptionParser.new do |parser|
  parser.banner = "Usage: xiaohei_sketch.rb --spec spec.json --out illustration.svg [--png illustration.png]"
  parser.on("--spec PATH", "JSON sketch spec") { |value| spec_path = value }
  parser.on("--out PATH", "Output SVG path") { |value| out_path = value }
  parser.on("--png PATH", "Also rasterize to PNG with headless Chrome") { |value| options[:png] = value }
  parser.on("--width PX", "Raster width in pixels") { |value| options[:width] = value.to_i }
end.parse!

abort "Missing --spec" unless spec_path
abort "Missing --out" unless out_path
abort "Spec not found: #{spec_path}" unless File.file?(spec_path)

spec = JSON.parse(File.read(spec_path))
svg = Sketch.build(spec)
FileUtils.mkdir_p(File.dirname(File.expand_path(out_path)))
File.write(out_path, svg)
puts "SVG: #{out_path}"

if options[:png]
  chrome = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
  ].find { |path| File.executable?(path) }
  abort "No Chromium-based browser found for --png rasterization" unless chrome

  width = options[:width].to_i
  width = (spec["size"] || [1600, 900])[0].to_i if width <= 0
  scale = width.to_f / (spec["size"] || [1600, 900])[0].to_i
  height = ((spec["size"] || [1600, 900])[1].to_i * scale).round
  png_path = File.expand_path(options[:png])
  FileUtils.mkdir_p(File.dirname(png_path))
  command = [
    chrome, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--no-first-run",
    "--force-device-scale-factor=1",
    "--user-data-dir=#{File.join(Dir.tmpdir, "z2y-sketch-chrome")}",
    "--window-size=#{width},#{height}",
    "--screenshot=#{png_path}",
    "file://#{File.expand_path(out_path)}"
  ]
  system(*command, out: File::NULL, err: File::NULL)
  abort "Rasterization failed" unless File.file?(png_path) && File.size(png_path).positive?
  puts "PNG: #{png_path}"
end
