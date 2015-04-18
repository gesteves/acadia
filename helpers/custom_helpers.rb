module CustomHelpers
  require "date"
  require "tzinfo"
  require "ruby-thumbor"

  def formatted_date_in_eastern(date_string, format = "%F")
    tz = TZInfo::Timezone.get("America/New_York")
    local = tz.utc_to_local(DateTime.parse(date_string))
    local.strftime(format)
  end

  def thumbor_url(url, width = 0, height = 0)
    url.gsub!(/^https?:\/\//, '')
    crypto = Thumbor::CryptoURL.new thumbor_key
    "#{thumbor_server_url}#{crypto.generate(:filters => ["quality(#{thumbor_jpg_quality})"], :width => width, :height => height, :image => url)}"
  end

  def build_srcset(url, sizes, square = false)
    srcset = []
    sizes.each do |size|
      width = size
      height = square ? size : 0
      srcset << "#{thumbor_url(url, width, height)} #{size}w"
    end
    srcset.join(', ')
  end

  def photoblog_image_tag(photo)
    caption = photo.plain_caption || "Latest from my photoblog"
    photo_url = photo.photos[0].original_size.url
    src = thumbor_url(photo_url, 693, 693)
    sizes_array = [1280, 693, 558, 526, 498, 484, 470, 416, 334, 278, 249, 242, 235]
    srcset = build_srcset(photo_url, sizes_array, true)
    sizes = "(min-width: 1090px) 249px, (min-width: 1000px) calc((100vw - 8rem)/4 - 1px), (min-width: 600px) calc((100vw - 4rem)/3 - 1px), calc((100vw - 4rem)/2 - 1px)"
    "<img src=\"#{src}\" srcset=\"#{srcset}\" sizes=\"#{sizes}\" alt=\"#{caption}\" title=\"#{caption}\" />"
  end

  def instagram_image_tag(photo)
    caption = photo.caption.nil? ? "Instagram photo" : photo.caption.text
    photo_url = photo.images.standard_resolution.url
    src = thumbor_url(photo_url, 372, 372)
    sizes_array = [640, 372, 350, 324, 228, 222, 194, 184, 172, 114, 92, 86]
    srcset = build_srcset(photo_url, sizes_array, true)
    sizes = "(min-width: 1360px) 92px, (min-width: 1000px) calc(((100vw - 8rem)/4 - 4rem)/3 - 1px), (min-width: 600px) calc(((100vw - 4rem)/2 - 2rem)/3 - 1px), calc((100vw - 4rem)/3 - 1px)"
    "<img src=\"#{src}\" srcset=\"#{srcset}\" sizes=\"#{sizes}\" alt=\"#{caption}\" title=\"#{caption}\" />"
  end

  def rdio_image_tag(album)
    alt = album.name
    photo_url = album.icon
    src = thumbor_url(photo_url, 150)
    sizes_array = [200, 150, 100, 50]
    srcset = build_srcset(photo_url, sizes_array)
    sizes = "50px"
    "<img src=\"#{src}\" srcset=\"#{srcset}\" sizes=\"#{sizes}\" alt=\"#{alt}\" />"
  end

  def twitter_avatar_image_tag(username, name)
    photo_url = username.profile_image_url.sub('_normal', '')
    src = thumbor_url(photo_url, 150)
    sizes_array = [200, 150, 100, 50]
    srcset = build_srcset(photo_url, sizes_array)
    sizes = "50px"
    "<img src=\"#{src}\" srcset=\"#{srcset}\" sizes=\"#{sizes}\" alt=\"#{name}\" />"
  end

  def untappd_image_tag(beer)
    alt = beer.beer_name
    photo_url = beer.beer_label
    src = thumbor_url(photo_url, 100)
    sizes_array = [100, 50]
    srcset = build_srcset(photo_url, sizes_array)
    sizes = "50px"
    "<img src=\"#{src}\" srcset=\"#{srcset}\" sizes=\"#{sizes}\" alt=\"#{alt}\" />"
  end

  def goodreads_image_tag(book)
    alt = book.title
    photo_url = book.image
    src = thumbor_url(photo_url, 150)
    sizes_array = [150, 100, 50]
    srcset = build_srcset(photo_url, sizes_array)
    sizes = "50px"
    "<img src=\"#{src}\" srcset=\"#{srcset}\" sizes=\"#{sizes}\" alt=\"#{alt}\" />"
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
end
