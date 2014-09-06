module CustomHelpers
  require "date"
  require "tzinfo"

  def formatted_date_in_eastern(date_string, format = "%F")
    tz = TZInfo::Timezone.get("America/New_York")
    local = tz.utc_to_local(DateTime.parse(date_string))
    local.strftime(format)
  end

  def photoblog_image_tag(photo)
    caption = photo.plain_caption || "Latest from my photoblog"
    src = image_path "photoblog/#{photo.id}_600.jpg"
    srcset = []
    sizes = [1280, 1000, 950, 900, 850, 800, 750, 700, 650, 600, 550, 500, 450, 400, 350, 300, 250, 200, 150, 100]
    sizes.each do |size|
      srcset << "#{image_path("photoblog/#{photo.id}_#{size}.jpg")} #{size}w"
    end
    sizes = "(min-width: 1408px) calc(25vw - 5rem), (min-width: 1120px) calc(33.333vw - 5.333rem), (min-width: 768px) calc(50vw - 6rem), (min-width: 400px) calc(100vw - 8rem), calc(100vw - 4rem)"
    "<img src=\"#{src}\" srcset=\"#{srcset.join(", ")}\" sizes=\"#{sizes}\" alt=\"#{caption}\" title=\"#{caption}\" />"
  end

  def instagram_image_tag(photo)
    caption = photo.caption.nil? ? "Instagram photo" : photo.caption.text
    src = image_path "instagram/#{photo.id}_300.jpg"
    srcset = []
    sizes = [640, 600, 550, 500, 450, 400, 350, 300, 250, 200, 150, 100, 50]
    sizes.each do |size|
      srcset << "#{image_path("instagram/#{photo.id}_#{size}.jpg")} #{size}w"
    end
    sizes = "(min-width: 1408px) calc((25vw - 5rem) * 0.3), (min-width: 1120px) calc((33.333vw - 5.333rem) * 0.3), (min-width: 768px) calc((50vw - 6rem) * 0.3), (min-width: 400px) calc((100vw - 4rem) * 0.3), calc((100vw - 4rem) * 0.3)"
    "<img src=\"#{src}\" srcset=\"#{srcset.join(", ")}\" sizes=\"#{sizes}\" alt=\"#{caption}\" title=\"#{caption}\" />"
  end

  def rdio_image_tag(album)
    alt = album.name
    src = image_path "rdio/#{album["key"]}_100.jpg"
    srcset = []
    sizes = [200, 150, 100, 50]
    sizes.each do |size|
      srcset << "#{image_path("rdio/#{album["key"]}_#{size}.jpg")} #{size}w"
    end
    sizes = "50px"
    "<img src=\"#{src}\" srcset=\"#{srcset.join(", ")}\" sizes=\"#{sizes}\" alt=\"#{alt}\" />"
  end

  def twitter_avatar_image_tag(username, name)
    src = image_path "twitter/#{username}_100.jpg"
    srcset = []
    sizes = [200, 150, 100, 50]
    sizes.each do |size|
      srcset << "#{image_path("twitter/#{username}_#{size}.jpg")} #{size}w"
    end
    sizes = "50px"
    "<img src=\"#{src}\" srcset=\"#{srcset.join(", ")}\" sizes=\"#{sizes}\" alt=\"#{name}\" />"
  end

  def untappd_image_tag(beer)
    alt = beer.name
    src = image_path "untappd/#{beer.checkin}_100.jpg"
    srcset = []
    sizes = [100, 50]
    sizes.each do |size|
      srcset << "#{image_path("untappd/#{beer.checkin}_#{size}.jpg")} #{size}w"
    end
    sizes = "50px"
    "<img src=\"#{src}\" srcset=\"#{srcset.join(", ")}\" sizes=\"#{sizes}\" alt=\"#{alt}\" />"
  end

  def goodreads_image_tag(book)
    alt = book.title
    src = image_path "goodreads/#{book.id}_100.jpg"
    srcset = []
    sizes = [150, 100, 50]
    sizes.each do |size|
      srcset << "#{image_path("goodreads/#{book.id}_#{size}.jpg")} #{size}w"
    end
    sizes = "50px"
    "<img src=\"#{src}\" srcset=\"#{srcset.join(", ")}\" sizes=\"#{sizes}\" alt=\"#{alt}\" />"
  end

  def photo_exif(photo)
    exif = []
    exif << photo.exif.camera unless photo.exif.camera.nil?
    exif << photo.exif.lens unless photo.exif.lens.nil?
    exif << photo.exif.film unless photo.exif.lens.nil?
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
end