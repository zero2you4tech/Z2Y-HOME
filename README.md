# Home

工作室门户网站： http://www.zero2you.tech/

# 本地部署和调试
 
```
gem install jekyll bundler -V
bundle install --path vendor/bundle -V
bundle exec jekyll serve
rm -r _site | bundle exec jekyll serve --incremental
rm -r _site && bundle exec jekyll serve --incremental
rm -r _site | bundle exec jekyll serve --config _config.dev.yml
rm -r _site && bundle exec jekyll serve --config _config.dev.yml
```