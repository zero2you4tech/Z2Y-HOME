#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "date"
require "pathname"


def load_yaml(raw)
  YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(raw) : YAML.load(raw)
end


repo = Pathname.new(ARGV[0] || Dir.pwd).expand_path
errors = []

app_file = repo.join("_data/apps.yml")
ui_file = repo.join("_data/ui.yml")
unless app_file.file?
  warn "Missing #{app_file}"
  exit 1
end

apps = load_yaml(app_file.read) || []
unless apps.is_a?(Array)
  warn "#{app_file} must contain an array"
  exit 1
end

required_bilingual = %w[name tagline summary description price min_os]
required_bilingual_lists = %w[highlights requirements install]
required_fields = %w[id order logo accent platforms price status featured links highlights requirements install faq changelog]

def lang_hash?(value)
  value.is_a?(Hash) && value["zh"].to_s.strip != "" && value["en"].to_s.strip != ""
end

def nonempty_array?(value)
  value.is_a?(Array) && !value.empty?
end

ids = {}
apps.each_with_index do |app, index|
  label = "apps[#{index}]"
  unless app.is_a?(Hash)
    errors << "#{label} must be a mapping"
    next
  end

  required_fields.each do |field|
    errors << "#{label} missing #{field}" if app[field].nil?
  end

  id = app["id"].to_s
  errors << "#{label} has invalid id #{id.inspect}" unless id.match?(/\A[a-z0-9][a-z0-9-]*\z/)
  errors << "duplicate app id: #{id}" if ids[id]
  ids[id] = true

  required_bilingual.each do |field|
    errors << "#{id}.#{field} must contain zh and en" unless lang_hash?(app[field])
  end

  required_bilingual_lists.each do |field|
    values = app[field]
    errors << "#{id}.#{field} must be a non-empty array" unless nonempty_array?(values)
    next unless values.is_a?(Array)

    values.each_with_index do |item, item_index|
      errors << "#{id}.#{field}[#{item_index}] must contain zh and en" unless lang_hash?(item)
    end
  end

  unless %w[available preview in-development].include?(app["status"].to_s)
    errors << "#{id}.status must be available, preview, or in-development"
  end

  platforms = app["platforms"]
  errors << "#{id}.platforms must be an array" unless platforms.is_a?(Array) && !platforms.empty?
  errors << "#{id}.links must be a mapping" unless app["links"].is_a?(Hash)

  if app["updated_at"].to_s.strip != ""
    begin
      Date.strptime(app["updated_at"].to_s, "%Y-%m-%d")
    rescue ArgumentError
      errors << "#{id}.updated_at must use YYYY-MM-DD"
    end
  end

  if app["released_at"].to_s.strip != ""
    begin
      Date.strptime(app["released_at"].to_s, "%Y-%m-%d")
    rescue ArgumentError
      errors << "#{id}.released_at must use YYYY-MM-DD"
    end
  end

  logo = app["logo"].to_s
  errors << "#{id}.logo does not exist: #{logo}" unless logo.start_with?("/") && repo.join(logo.sub(%r{\A/}, "")).file?

  page = repo.join("_apps/#{id}.md")
  if page.file?
    front_matter = page.read.split(/^---\s*$/, 3)[1].to_s
    page_data = load_yaml(front_matter) || {}
    errors << "#{page} must set app_id: #{id}" unless page_data["app_id"].to_s == id
  else
    errors << "missing app page: _apps/#{id}.md"
  end

  faq = app["faq"]
  if faq && !faq.is_a?(Array)
    errors << "#{id}.faq must be an array"
  elsif faq.is_a?(Array)
    faq.each_with_index do |item, item_index|
      unless item.is_a?(Hash) && lang_hash?(item["q"]) && lang_hash?(item["a"])
        errors << "#{id}.faq[#{item_index}] must contain bilingual q and a"
      end
    end
  end
end

ui = ui_file.file? ? (load_yaml(ui_file.read) || {}) : {}
if ui.empty? || !ui["zh"].is_a?(Hash) || !ui["en"].is_a?(Hash)
  errors << "_data/ui.yml must contain zh and en maps"
else
  missing_en = ui["zh"].keys - ui["en"].keys
  missing_zh = ui["en"].keys - ui["zh"].keys
  errors << "ui keys missing from en: #{missing_en.join(', ')}" unless missing_en.empty?
  errors << "ui keys missing from zh: #{missing_zh.join(', ')}" unless missing_zh.empty?
end

Dir[repo.join("_posts/*.md")].sort.each do |path|
  raw = File.read(path)
  parts = raw.split(/^---\s*$/, 3)
  next unless parts.length == 3

  post = load_yaml(parts[1]) || {}
  categories = Array(post["categories"]).map(&:to_s)
  body = parts[2]
  next unless categories.include?("app-update") || categories.include?("article")

  if post["title"].to_s.strip == "" || post["title_en"].to_s.strip == ""
    errors << "#{File.basename(path)} must contain title and title_en"
  end
  if post["excerpt"].to_s.strip == "" || post["excerpt_en"].to_s.strip == ""
    errors << "#{File.basename(path)} must contain excerpt and excerpt_en"
  end
  unless body.include?('data-lang="zh"') && body.include?('data-lang="en"')
    errors << "#{File.basename(path)} must contain bilingual data-lang sections"
  end
  # kramdown（parse_block_html 关闭）不会解析 HTML 块内部的 markdown，
  # 双语 div 必须带 markdown="1"，否则链接、加粗会以纯文本平铺显示。
  bare_divs = body.scan(/<div data-lang="(?:zh|en)">/).size
  if bare_divs.positive?
    errors << "#{File.basename(path)} must add markdown=\"1\" to #{bare_divs} bilingual <div> block(s) so markdown renders"
  end

  if categories.include?("app-update")
    unless ids[post["app_id"].to_s]
      errors << "#{File.basename(path)} references unknown app_id #{post['app_id'].inspect}"
    end
    errors << "#{File.basename(path)} must contain version" if post["version"].to_s.strip == ""
  end
end

# 页面（支持页、关于页等）同样使用双语 div，规则保持一致。
Dir[repo.join("_pages/*.md")].sort.each do |path|
  raw = File.read(path)
  bare_divs = raw.scan(/<div data-lang="(?:zh|en)">/).size
  next unless bare_divs.positive?

  errors << "#{File.basename(path)} must add markdown=\"1\" to #{bare_divs} bilingual <div> block(s) so markdown renders"
end

if errors.empty?
  puts "Site content valid: #{apps.length} apps, #{Dir[repo.join('_posts/*.md')].length} posts"
  exit 0
end

warn "Site content validation failed:"
errors.each { |error| warn "  - #{error}" }
exit 1
