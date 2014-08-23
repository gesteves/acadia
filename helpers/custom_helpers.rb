module CustomHelpers
  require "date"
  require "tzinfo"

  def formatted_date_in_eastern(date_string, format = "%F")
    tz = TZInfo::Timezone.get("America/New_York")
    local = tz.utc_to_local(DateTime.parse(date_string))
    local.strftime(format)
  end

  def photoblog_image_tag(photo)
    alt = "Latest from my photoblog"
    src = image_path "photoblog/#{photo.id}_600.jpg"
    srcset = []
    sizes = [1280, 1000, 950, 900, 850, 800, 750, 700, 650, 600, 550, 500, 450, 400, 350, 300, 250, 200, 150, 100]
    sizes.each do |size|
      srcset << "#{image_path("photoblog/#{photo.id}_#{size}.jpg")} #{size}w"
    end
    sizes = "(min-width: 1470px) 312px, (min-width: 1120px) 405px, (min-width: 765px) 465px, (min-width: 400px) 640px, 256px"
    "<img src=\"#{src}\" srcset=\"#{srcset.join(", ")}\" sizes=\"#{sizes}\" alt=\"#{alt}\" />"
  end

  def instagram_image_tag(photo)
    alt = photo.caption.nil? ? "Instagram photo" : photo.caption.text
    src = image_path "instagram/#{photo.id}_300.jpg"
    srcset = []
    sizes = [640, 600, 550, 500, 450, 400, 350, 300, 250, 200, 150, 100, 50]
    sizes.each do |size|
      srcset << "#{image_path("instagram/#{photo.id}_#{size}.jpg")} #{size}w"
    end
    sizes = "(min-width: 1470px) 94px, (min-width: 1120px) 121px, (min-width: 765px) 140px, (min-width: 400px) 192px, 77px"
    "<img src=\"#{src}\" srcset=\"#{srcset.join(", ")}\" sizes=\"#{sizes}\" alt=\"#{alt}\" />"
  end
end