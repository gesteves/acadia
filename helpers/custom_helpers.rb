module CustomHelpers
  require "date"
  require "tzinfo"
  require "active_support/all"

  def formatted_date_in_eastern(date_string, format = "%F")
    tz = TZInfo::Timezone.get("America/New_York")
    local = tz.utc_to_local(DateTime.parse(date_string))
    local.strftime(format)
  end

  def photoblog_image_tag(photo)
    caption = photo.plain_caption || "Latest from my photoblog"
    src = image_path "photoblog/#{photo.id}_1280.jpg"
    srcset = []
    sizes = [1280, 1200, 1100, 1000, 900, 800, 640, 600, 550, 500, 460, 400, 320, 230]
    sizes.each do |size|
      srcset << "#{image_path("photoblog/#{photo.id}_#{size}.jpg")} #{size}w"
    end
    sizes = "(min-width: 1000px) calc(250px - 2rem), (min-width: 600px) calc(33.33vw - 6rem), calc(50vw - 4rem)"
    "<img src=\"#{src}\" srcset=\"#{srcset.join(", ")}\" sizes=\"#{sizes}\" alt=\"#{caption}\" title=\"#{caption}\" />"
  end

  def instagram_image_tag(photo)
    caption = photo.caption.nil? ? "Instagram photo" : photo.caption.text
    src = image_path "instagram/#{photo.id}_640.jpg"
    srcset = []
    sizes = [640, 320, 240, 200, 160, 140, 120, 100, 80, 60]
    sizes.each do |size|
      srcset << "#{image_path("instagram/#{photo.id}_#{size}.jpg")} #{size}w"
    end
    sizes = "(min-width: 1280px) calc((25vw - 6rem) * 0.3), (min-width: 1000px) calc((25vw - 5rem) * 0.3), (min-width: 600px) calc((50vw - 4rem) * 0.3), calc((100vw - 4rem) * 0.3)"
    "<img src=\"#{src}\" srcset=\"#{srcset.join(", ")}\" sizes=\"#{sizes}\" alt=\"#{caption}\" title=\"#{caption}\" />"
  end

  def rdio_image_tag(album)
    alt = album.name
    src = image_path "rdio/#{album["key"]}_150.jpg"
    srcset = []
    sizes = [200, 150, 100, 50]
    sizes.each do |size|
      srcset << "#{image_path("rdio/#{album["key"]}_#{size}.jpg")} #{size}w"
    end
    sizes = "50px"
    "<img src=\"#{src}\" srcset=\"#{srcset.join(", ")}\" sizes=\"#{sizes}\" alt=\"#{alt}\" />"
  end

  def twitter_avatar_image_tag(username, name)
    src = image_path "twitter/#{username}_150.jpg"
    srcset = []
    sizes = [200, 150, 100, 50]
    sizes.each do |size|
      srcset << "#{image_path("twitter/#{username}_#{size}.jpg")} #{size}w"
    end
    sizes = "50px"
    "<img src=\"#{src}\" srcset=\"#{srcset.join(", ")}\" sizes=\"#{sizes}\" alt=\"#{name}\" />"
  end

  def untappd_image_tag(beer)
    alt = beer.beer_name
    src = image_path "untappd/#{beer.bid}_100.jpg"
    srcset = []
    sizes = [100, 50]
    sizes.each do |size|
      srcset << "#{image_path("untappd/#{beer.bid}_#{size}.jpg")} #{size}w"
    end
    sizes = "50px"
    "<img src=\"#{src}\" srcset=\"#{srcset.join(", ")}\" sizes=\"#{sizes}\" alt=\"#{alt}\" />"
  end

  def goodreads_image_tag(book)
    alt = book.title
    src = image_path "goodreads/#{book.id}_150.jpg"
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
    number.to_s(:delimited)
  end

  def local_time(format = "%F", zone = "America/New_York")
    Time.zone = zone
    Time.zone.now.strftime(format)
  end
end
