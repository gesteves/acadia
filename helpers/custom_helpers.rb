module CustomHelpers
  require "date"
  require "tzinfo"
  require "imgix"

  def formatted_date_in_eastern(date_string, format = "%F")
    tz = TZInfo::Timezone.get("America/New_York")
    local = tz.utc_to_local(DateTime.parse(date_string))
    local.strftime(format)
  end

  def imgix_url(url, options)
    if ENV['RACK_ENV'] == 'production'
      opts = { auto: 'format', fit: 'max' }.merge(options)
      client = Imgix::Client.new(hosts: imgix_domains.split(','), token: imgix_token, secure: true, include_library_param: false).path(url)
      if opts[:square]
        opts[:fit] = 'crop'
        opts[:h] = opts[:w]
        opts.delete(:square)
      end
      client.to_url(opts)
    else
      url
    end
  end

  def build_srcset(url, sizes, square = false)
    srcset = []
    sizes.each do |size|
      opts = { w: size }
      opts[:square] = true if square
      srcset << "#{imgix_url(url, opts)} #{size}w"
    end
    srcset.join(', ')
  end

  def photoblog_image_tag(photo, caption = "Latest from my photoblog")
    photo_url = image_path "photoblog/#{photo.id}.jpg"
    sizes_array = [558, 498, 249]
    srcset = build_srcset(photo_url, sizes_array)
    src = imgix_url(photo_url, { w: sizes_array.first })
    sizes = "(min-width: 1090px) 249px, (min-width: 1000px) calc((100vw - 8rem)/4 - 1px), (min-width: 600px) calc((100vw - 4rem)/3 - 1px), calc((100vw - 4rem)/2 - 1px)"
    "<img class=\"js-lazy-load\" data-src=\"#{src}\" data-srcset=\"#{srcset}\" sizes=\"#{sizes}\" alt=\"#{caption}\" title=\"#{caption}\" />"
  end

  def instagram_image_tag(photo)
    caption = photo.caption.nil? ? "Instagram photo" : photo.caption.text
    photo_url = image_path "instagram/#{photo.id}.jpg"
    sizes_array = [347, 172, 86]
    srcset = build_srcset(photo_url, sizes_array, true)
    src = imgix_url(photo_url, { w: sizes_array.first, square: true })
    sizes = "(min-width: 1360px) 92px, (min-width: 1000px) calc(((100vw - 8rem)/4 - 4rem)/3 - 1px), (min-width: 600px) calc(((100vw - 4rem)/2 - 2rem)/3 - 1px), calc((100vw - 4rem)/3 - 1px)"
    "<img class=\"js-lazy-load\" data-src=\"#{src}\" data-srcset=\"#{srcset}\" sizes=\"#{sizes}\" alt=\"#{caption}\" title=\"#{caption}\" />"
  end

  def artist_image_tag(artist)
    alt = artist.name
    photo_url = image_path "music/#{artist.id}.jpg"
    sizes_array = [150, 100, 50]
    srcset = build_srcset(photo_url, sizes_array)
    src = imgix_url(photo_url, { w: sizes_array.first })
    sizes = "50px"
    "<img class=\"js-lazy-load\" data-src=\"#{src}\" data-srcset=\"#{srcset}\" sizes=\"#{sizes}\" alt=\"#{alt}\" />"
  end

  def twitter_avatar_image_tag(username, name)
    photo_url = image_path "twitter/#{username.screen_name}.jpg"
    sizes_array = [150, 100, 50]
    srcset = build_srcset(photo_url, sizes_array)
    src = imgix_url(photo_url, { w: sizes_array.first })
    sizes = "50px"
    "<img class=\"js-lazy-load\" data-src=\"#{src}\" data-srcset=\"#{srcset}\" sizes=\"#{sizes}\" alt=\"#{name}\" />"
  end

  def untappd_image_tag(beer)
    alt = beer.beer_name
    photo_url = image_path "untappd/#{beer.bid}.jpg"
    sizes_array = [100, 50]
    srcset = build_srcset(photo_url, sizes_array)
    src = imgix_url(photo_url, { w: sizes_array.first })
    sizes = "50px"
    "<img class=\"js-lazy-load\" data-src=\"#{src}\" data-srcset=\"#{srcset}\" sizes=\"#{sizes}\" alt=\"#{alt}\" />"
  end

  def goodreads_image_tag(book)
    alt = book.title
    photo_url = image_path "goodreads/#{book.id}.jpg"
    sizes_array = [150, 100, 50]
    srcset = build_srcset(photo_url, sizes_array)
    src = imgix_url(photo_url, { w: sizes_array.first })
    sizes = "50px"
    "<img class=\"js-lazy-load\" data-src=\"#{src}\" data-srcset=\"#{srcset}\" sizes=\"#{sizes}\" alt=\"#{alt}\" />"
  end

  def photo_exif(photo)
    exif = []
    exif << photo.exif.camera unless photo.exif.camera.nil?
    exif << photo.exif.lens unless photo.exif.lens.nil?
    exif << photo.exif.film unless photo.exif.film.nil?
    exif.join(" &middot ")
  end

  def host_with_port
    [host, optional_port].compact.join(':')
  end

  def optional_port
    port unless port.to_i == 80
  end

  def image_url(source)
    protocol + host_with_port + image_path(source)
  end

  def format_number(number)
    number = number.to_s
    while number.match(/(\d+)(\d\d\d)/)
      number.gsub!(/(\d+)(\d\d\d)/, "\\1,\\2")
    end
    number
  end

  def inline_svg(svg_id, svg_class = "p-svg")
    svg_id = svg_id.gsub("#", "")
    "<svg viewBox=\"0 0 100 100\" class=\"#{svg_class} #{svg_id}\"><use xlink:href=\"##{svg_id}\"></use></svg>"
  end

  # Render inline css
  # Source: http://blog.ruppel.io/post/52645746944/inline-assets-in-middleman
  def inline_stylesheet(name)
    content_tag :style do
      sprockets["#{name}.css"].to_s
    end
  end

  def inline_javascript(name)
    content_tag :script do
      sprockets["#{name}.js"].to_s
    end
  end
end
