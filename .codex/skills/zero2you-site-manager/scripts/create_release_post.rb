#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "date"
require "fileutils"
require "optparse"
require "pathname"
require "rbconfig"

def load_yaml(raw)
  YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(raw) : YAML.load(raw)
end

def yaml_string(value)
  value.to_s.dump
end

def compact_body(value)
  value.to_s.strip.gsub(/\n{3,}/, "\n\n")
end

options = {
  repo: ENV["Z2Y_HOME_REPO"] || Dir.pwd,
  force: false,
  dry_run: false
}

OptionParser.new do |parser|
  parser.banner = "Usage: create_release_post.rb --app ID --version VERSION --date YYYY-MM-DD --title TITLE [options]"
  parser.on("--repo PATH", "Zero2You website repository") { |value| options[:repo] = value }
  parser.on("--app ID", "App id") { |value| options[:app] = value }
  parser.on("--version VERSION", "Released version") { |value| options[:version] = value }
  parser.on("--date DATE", "Release date in YYYY-MM-DD") { |value| options[:date] = value }
  parser.on("--title TITLE", "Chinese title") { |value| options[:title] = value }
  parser.on("--title-en TITLE", "English title") { |value| options[:title_en] = value }
  parser.on("--summary-zh TEXT", "Chinese excerpt") { |value| options[:summary_zh] = value }
  parser.on("--summary-en TEXT", "English excerpt") { |value| options[:summary_en] = value }
  parser.on("--body-zh TEXT", "Chinese body") { |value| options[:body_zh] = value }
  parser.on("--body-en TEXT", "English body") { |value| options[:body_en] = value }
  parser.on("--force", "Overwrite an existing post") { options[:force] = true }
  parser.on("--dry-run", "Print the post without writing") { options[:dry_run] = true }
end.parse!

%w[app version date title title_en summary_zh summary_en].each do |key|
  abort "Missing --#{key.tr('_', '-')}" if options[key.to_sym].to_s.strip == ""
end

begin
  date = Date.strptime(options[:date], "%Y-%m-%d")
rescue ArgumentError
  abort "--date must use YYYY-MM-DD"
end

repo = Pathname.new(options[:repo]).expand_path
apps_file = repo.join("_data/apps.yml")
abort "Not a Zero2You site repo: #{repo}" unless apps_file.file?

apps = load_yaml(apps_file.read) || []
app = apps.find { |item| item.is_a?(Hash) && item["id"].to_s == options[:app] }
abort "Unknown app id: #{options[:app]}" unless app

slug = options[:version].to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
post_path = repo.join("_posts/#{date.strftime('%Y-%m-%d')}-#{options[:app]}-#{slug}.md")
if post_path.file? && !options[:force] && !options[:dry_run]
  abort "Post already exists: #{post_path} (use --force to overwrite)"
end

body_zh = compact_body(options[:body_zh] || options[:summary_zh])
body_en = compact_body(options[:body_en] || options[:summary_en])

content = <<~POST
  ---
  layout: single
  title: #{yaml_string(options[:title])}
  title_en: #{yaml_string(options[:title_en])}
  date: #{date.strftime('%Y-%m-%d')} 18:00:00 +0800
  categories:
    - app-update
  app_id: #{yaml_string(options[:app])}
  version: #{yaml_string(options[:version])}
  excerpt: #{yaml_string(options[:summary_zh])}
  excerpt_en: #{yaml_string(options[:summary_en])}
  author_profile: false
  share: false
  related: false
  ---

  <div data-lang="zh">

  #{body_zh}

  </div>

  <div data-lang="en">

  #{body_en}

  </div>
POST

if options[:dry_run]
  puts "POST_PATH=#{post_path}"
  puts content
  exit 0
end

FileUtils.mkdir_p(post_path.dirname)
post_path.write(content)
puts "Created #{post_path}"

validator = repo.join(".codex/skills/zero2you-site-manager/scripts/validate_site_content.rb")
abort "Release post written, but validation failed" unless system(RbConfig.ruby, validator.to_s, repo.to_s)
