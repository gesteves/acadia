set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'

set :protocol, 'http://'
set :host, '0.0.0.0'
set :port, 4567

activate :gzip
activate :autoprefixer
activate :dotenv
activate :s3_sync do |s3|
  s3.prefer_gzip           = true
  s3.bucket                = ENV['AWS_BUCKET']
  s3.region                = ENV['AWS_REGION']
  s3.aws_access_key_id     = ENV['AWS_ACCESS_KEY_ID']
  s3.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY_ID']
end

# Build-specific configuration
configure :build do
  ignore 'svg/*'
  activate :minify_css
  activate :minify_javascript
  activate :minify_html
  activate :asset_hash
  activate :relative_assets
  activate :imageoptim do |options|
    options.manifest         = false
    options.image_extensions = %w(.jpg)
    options.allow_lossy      = true
    options.jpegoptim        = { :strip => ['all'], :max_quality => 80 }
    options.jpegtran         = false
    options.advpng           = false
    options.gifsicle         = false
    options.optipng          = false
    options.pngcrush         = false
    options.pngout           = false
    options.svgo             = false
  end
  set :protocol, 'http://'
  set :host, 'www.gesteves.com/'
  set :port, 80
end

after_configuration do
  caching_policy 'text/html',    :max_age => 0, :must_revalidate => true
  default_caching_policy         :max_age => 60 * 60 * 24 * 365
end
