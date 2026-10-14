#!/usr/bin/env ruby
# frozen_string_literal: true

# Scaffolds a journal post (article or daily thought note) with the front matter
# the site's two-column post shell expects.
#
# Usage:
#   ruby create_journal_post.rb --slug why-we-build --date 2026-10-12 \
#     --title "中文标题" --title-en "English title" \
#     --summary-zh "摘要" --summary-en "Summary" \
#     --visual /assets/journal/2026-10-12-why-we-build/01-real-problem.png \
#     --visual-kind illustration \
#     [--visual-caption "中文图注"] [--visual-caption-en "English caption"] \
#     [--source-url https://.../cards/slug]

require "date"
require "fileutils"
require "optparse"
require "pathname"
require "rbconfig"

def yaml_string(value)
  value.to_s.dump
end

options = { repo: ENV["Z2Y_HOME_REPO"] || Dir.pwd, kind: "article", dry_run: false, force: false }

OptionParser.new do |parser|
  parser.banner = "Usage: create_journal_post.rb --slug SLUG --date YYYY-MM-DD --title TITLE [options]"
  parser.on("--repo PATH", "Zero2You website repository") { |v| options[:repo] = v }
  parser.on("--slug SLUG", "kebab-case slug") { |v| options[:slug] = v }
  parser.on("--date DATE", "YYYY-MM-DD") { |v| options[:date] = v }
  parser.on("--title TITLE", "Chinese title") { |v| options[:title] = v }
  parser.on("--title-en TITLE", "English title") { |v| options[:title_en] = v }
  parser.on("--summary-zh TEXT", "Chinese excerpt") { |v| options[:summary_zh] = v }
  parser.on("--summary-en TEXT", "English excerpt") { |v| options[:summary_en] = v }
  parser.on("--visual PATH", "Site-absolute visual path, e.g. /assets/journal/.../01.png") { |v| options[:visual] = v }
  parser.on("--visual-kind KIND", "illustration | product | note") { |v| options[:visual_kind] = v }
  parser.on("--visual-caption TEXT", "Chinese caption") { |v| options[:visual_caption] = v }
  parser.on("--visual-caption-en TEXT", "English caption") { |v| options[:visual_caption_en] = v }
  parser.on("--source-url URL", "Canonical source (for aphorism-notebook cards)") { |v| options[:source_url] = v }
  parser.on("--body-zh TEXT", "Chinese body") { |v| options[:body_zh] = v }
  parser.on("--body-en TEXT", "English body") { |v| options[:body_en] = v }
  parser.on("--force", "Overwrite an existing post") { options[:force] = true }
  parser.on("--dry-run", "Print without writing") { options[:dry_run] = true }
end.parse!

%w[slug date title title_en summary_zh summary_en visual].each do |key|
  abort "Missing --#{key.tr('_', '-')}" if options[key.to_sym].to_s.strip == ""
end

abort "Invalid slug: #{options[:slug]}" unless options[:slug].to_s.match?(/\A[a-z0-9][a-z0-9-]*\z/)

begin
  date = Date.strptime(options[:date], "%Y-%m-%d")
rescue ArgumentError
  abort "--date must use YYYY-MM-DD"
end

repo = Pathname.new(options[:repo]).expand_path
abort "Not a Zero2You site repo: #{repo}" unless repo.join("_data/apps.yml").file?

visual = options[:visual].to_s
abort "--visual must start with /" unless visual.start_with?("/")
abort "Visual not found: #{visual}" unless repo.join(visual.sub(%r{\A/}, "")).file?

post_path = repo.join("_posts/#{date.strftime('%Y-%m-%d')}-#{options[:slug]}.md")
if post_path.file? && !options[:force] && !options[:dry_run]
  abort "Post already exists: #{post_path} (use --force to overwrite)"
end

body_zh = options[:body_zh].to_s.strip
body_en = options[:body_en].to_s.strip
body_zh = options[:summary_zh].to_s if body_zh.empty?
body_en = options[:summary_en].to_s if body_en.empty?

front_matter = +"---\n"
front_matter << "layout: single\n"
front_matter << "title: #{yaml_string(options[:title])}\n"
front_matter << "title_en: #{yaml_string(options[:title_en])}\n"
front_matter << "date: #{date.strftime('%Y-%m-%d')} 18:00:00 +0800\n"
front_matter << "categories:\n  - article\n"
front_matter << "excerpt: #{yaml_string(options[:summary_zh])}\n"
front_matter << "excerpt_en: #{yaml_string(options[:summary_en])}\n"
front_matter << "visual: #{yaml_string(visual)}\n"
front_matter << "visual_kind: #{yaml_string(options[:visual_kind] || 'illustration')}\n"
front_matter << "visual_caption: #{yaml_string(options[:visual_caption])}\n" if options[:visual_caption]
front_matter << "visual_caption_en: #{yaml_string(options[:visual_caption_en])}\n" if options[:visual_caption_en]
front_matter << "source_url: #{yaml_string(options[:source_url])}\n" if options[:source_url]
front_matter << "author_profile: false\nshare: false\nrelated: false\n---\n"

content = front_matter + <<~BODY

  <div data-lang="zh" markdown="1">

  #{body_zh}

  </div>

  <div data-lang="en" markdown="1">

  #{body_en}

  </div>
BODY

if options[:dry_run]
  puts "POST_PATH=#{post_path}"
  puts content
  exit 0
end

FileUtils.mkdir_p(post_path.dirname)
post_path.write(content)
puts "Created #{post_path}"

validator = repo.join(".codex/skills/zero2you-site-manager/scripts/validate_site_content.rb")
abort "Journal post written, but validation failed" unless system(RbConfig.ruby, validator.to_s, repo.to_s)
