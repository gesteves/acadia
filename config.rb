set :css_dir, 'stylesheets'

set :js_dir, 'javascripts'

set :images_dir, 'images'

activate :gzip
activate :s3_sync do |s3|
  s3.prefer_gzip = true
end

# Build-specific configuration
configure :build do
  activate :minify_css
  activate :minify_javascript
  activate :asset_hash
  activate :relative_assets
end

after_configuration do
  caching_policy "text/html",    max_age: 0, must_revalidate: true
  caching_policy "image/x-icon", max_age: 60 * 60 * 24 * 365
  default_caching_policy         max_age: 60 * 60 * 24 * 365
end