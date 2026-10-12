#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "json"
require "fileutils"
require "optparse"
require "pathname"
require "rbconfig"

UPDATER_VERSION = "1.0.0"

def load_yaml(raw)
  YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(raw) : YAML.load(raw)
end

def deep_merge(base, patch)
  base.merge(patch) do |_key, old_value, new_value|
    if old_value.is_a?(Hash) && new_value.is_a?(Hash)
      deep_merge(old_value, new_value)
    else
      new_value
    end
  end
end

options = {
  repo: ENV["Z2Y_HOME_REPO"] || Dir.pwd,
  create_page: false,
  dry_run: false
}

OptionParser.new do |parser|
  parser.banner = "Usage: upsert_app.rb --app APP_ID --patch PATCH.json [options]"
  parser.on("--repo PATH", "Zero2You website repository") { |value| options[:repo] = value }
  parser.on("--app ID", "App id, such as z2y-ai") { |value| options[:app] = value }
  parser.on("--patch PATH", "JSON object containing fields to merge") { |value| options[:patch] = value }
  parser.on("--create-page", "Create _apps/<id>.md when missing") { options[:create_page] = true }
  parser.on("--dry-run", "Print the merged app without writing") { options[:dry_run] = true }
  parser.on("--version", "Print helper version") do
    puts UPDATER_VERSION
    exit 0
  end
end.parse!

abort "Missing --app" unless options[:app]
abort "Missing --patch" unless options[:patch]

repo = Pathname.new(options[:repo]).expand_path
apps_file = repo.join("_data/apps.yml")
abort "Not a Zero2You site repo: #{repo}" unless apps_file.file?
abort "Patch not found: #{options[:patch]}" unless File.file?(options[:patch])

app_id = options[:app].to_s
abort "Invalid app id: #{app_id.inspect}" unless app_id.match?(/\A[a-z0-9][a-z0-9-]*\z/)

patch = JSON.parse(File.read(options[:patch]))
abort "Patch must be a JSON object" unless patch.is_a?(Hash)
abort "Patch cannot change app id" if patch.key?("id") && patch["id"].to_s != app_id

apps = load_yaml(apps_file.read) || []
abort "_data/apps.yml must contain an array" unless apps.is_a?(Array)

existing = apps.find { |app| app.is_a?(Hash) && app["id"].to_s == app_id }
if existing
  apps[apps.index(existing)] = deep_merge(existing, patch)
else
  max_order = apps.map { |app| app.is_a?(Hash) ? app["order"].to_i : 0 }.max || 0
  defaults = {
    "id" => app_id,
    "order" => max_order + 1,
    "status" => "in-development",
    "featured" => false,
    "platforms" => ["macOS"],
    "price" => { "zh" => "免费", "en" => "Free" },
    "links" => {},
    "highlights" => [],
    "requirements" => [],
    "install" => [],
    "faq" => [],
    "changelog" => []
  }
  apps << deep_merge(defaults, patch).merge("id" => app_id)
end

updated = apps.find { |app| app["id"].to_s == app_id }

if options[:dry_run]
  puts YAML.dump(updated)
  exit 0
end

File.write(apps_file, YAML.dump(apps))

if options[:create_page]
  page = repo.join("_apps/#{app_id}.md")
  unless page.file?
    FileUtils.mkdir_p(page.dirname)
    page.write("---\nlayout: app\napp_id: \"#{app_id}\"\n---\n")
  end
end

validator = repo.join(".codex/skills/zero2you-site-manager/scripts/validate_site_content.rb")
unless system(RbConfig.ruby, validator.to_s, repo.to_s)
  abort "App patch written, but validation failed"
end

puts "Updated app #{app_id} in #{apps_file}"
puts "Created app page #{repo.join("_apps/#{app_id}.md")}" if options[:create_page]
