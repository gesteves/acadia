set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'

set :protocol, 'http://'
set :host, '0.0.0.0'
set :port, 4567

activate :dotenv
activate :autoprefixer do |config|
  config.browsers = ['last 1 version', 'last 3 safari versions']
  config.inline   = true
end
activate :s3_sync do |s3|
  s3.bucket                = ENV['AWS_BUCKET']
  s3.region                = ENV['AWS_REGION']
  s3.aws_access_key_id     = ENV['AWS_ACCESS_KEY_ID']
  s3.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY_ID']
end

set :imgix_token, ENV['IMGIX_TOKEN']
set :imgix_domains, ENV['IMGIX_DOMAIN']

# Build-specific configuration
configure :build do
  ignore 'svg/*'
  activate :minify_css, :inline => true
  activate :minify_javascript, :inline => true
  activate :minify_html
  activate :asset_hash
  activate :relative_assets
  set :protocol, 'https://'
  set :host, 'www.gesteves.com/'
  set :port, 80
end

after_configuration do
  caching_policy 'text/html',    :max_age => ENV['MAX_AGE'] || 300, :must_revalidate => true
  default_caching_policy         :max_age => 60 * 60 * 24 * 365
end
