#!/usr/bin/env ruby
# frozen_string_literal: true

# Attaches (or repoints) a post's left-panel visual and verifies the asset exists.
#
# Usage:
#   ruby attach_visual.rb --post _posts/2026-10-12-why-we-build.md \
#     --visual /assets/journal/2026-10-12-why-we-build/01-real-problem.png \
#     --kind illustration \
#     [--caption "中文图注"] [--caption-en "English caption"] \
#     [--source-url https://.../cards/<slug>]

require "fileutils"
require "optparse"
require "pathname"
require "rbconfig"

FRONT_KEYS = %w[visual visual_kind visual_caption visual_caption_en source_url].freeze

def yaml_string(value)
  value.to_s.dump
end

options = { repo: ENV["Z2Y_HOME_REPO"] || Dir.pwd, dry_run: false }
OptionParser.new do |parser|
  parser.banner = "Usage: attach_visual.rb --post PATH --visual PATH [options]"
  parser.on("--repo PATH", "Zero2You website repository") { |v| options[:repo] = v }
  parser.on("--post PATH", "Post path, relative to the repo") { |v| options[:post] = v }
  parser.on("--visual PATH", "Site-absolute visual path") { |v| options[:visual] = v }
  parser.on("--kind KIND", "illustration | product | note") { |v| options[:kind] = v }
  parser.on("--caption TEXT", "Chinese caption") { |v| options[:caption] = v }
  parser.on("--caption-en TEXT", "English caption") { |v| options[:caption_en] = v }
  parser.on("--source-url URL", "Canonical source URL") { |v| options[:source_url] = v }
  parser.on("--dry-run", "Print the result without writing") { options[:dry_run] = true }
end.parse!

abort "Missing --post" unless options[:post]
abort "Missing --visual" unless options[:visual]

repo = Pathname.new(options[:repo]).expand_path
post_path = repo.join(options[:post].to_s)
abort "Post not found: #{post_path}" unless post_path.file?

visual = options[:visual].to_s
abort "--visual must start with /" unless visual.start_with?("/")
asset = repo.join(visual.sub(%r{\A/}, ""))
abort "Visual asset not found: #{asset}" unless asset.file?

content = post_path.read
parts = content.split(/^---\s*$/, 3)
abort "#{post_path} has no front matter" unless parts.length == 3

front_lines = parts[1].lines.map(&:chomp)
front_lines.reject! { |line| FRONT_KEYS.any? { |key| line.match?(/\A#{key}:/) } }

front_lines << "visual: #{yaml_string(visual)}"
front_lines << "visual_kind: #{yaml_string(options[:kind] || 'illustration')}"
front_lines << "visual_caption: #{yaml_string(options[:caption])}" if options[:caption]
front_lines << "visual_caption_en: #{yaml_string(options[:caption_en])}" if options[:caption_en]
front_lines << "source_url: #{yaml_string(options[:source_url])}" if options[:source_url]

updated = "---\n#{front_lines.join("\n")}\n---#{parts[2]}"

if options[:dry_run]
  puts updated
  exit 0
end

post_path.write(updated)
puts "Updated #{post_path}"
puts "Visual: #{visual}"

validator = repo.join(".codex/skills/zero2you-site-manager/scripts/validate_site_content.rb")
abort "Visual attached, but validation failed" unless system(RbConfig.ruby, validator.to_s, repo.to_s)
