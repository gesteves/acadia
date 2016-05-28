var Acadia = Acadia || {};

Acadia.LazyLoad = (function () {
  'use strict';

  var opts = {
    load_class : 'js-lazy-load'
  };

  var requested_animation_frame = false;
  var observer;

  var init = function () {
    var images;

    if (typeof IntersectionObserver === 'undefined') {
      document.addEventListener('scroll', handleScroll);
    } else {
      observer = new IntersectionObserver(handleIntersection);
      images = document.querySelectorAll('.' + opts.load_class);
      for (var i = 0; i < images.length; i++) {
        observer.observe(images[i]);
      }
    }
  };

  var handleIntersection = function (entries) {
    entries.forEach(function (entry) {
      loadImage(entry.target);
      observer.unobserve(entry.target);
    });
  };

  var handleScroll = function () {
    if (requested_animation_frame) {
      return;
    }
    requested_animation_frame = true;
    requestAnimationFrame(loadImages);
  };

  var loadImages = function () {
    var image,
        images,
        image_top,
        bottom;

    images = document.querySelectorAll('.' + opts.load_class);

    if (images.length === 0) {
      return;
    }

    bottom = window.pageYOffset + document.documentElement.clientHeight;

    for (var i = 0; i < images.length; i++) {
      image = images[i];
      image_top = image.getBoundingClientRect().top;
      if (image_top <= bottom) {
        loadImage(image);
      }
    }

    requested_animation_frame = false;
  };

  var loadImage = function (image) {
    if (image.hasAttribute('data-srcset') && typeof image.srcset !== 'undefined') {
      image.setAttribute('srcset', image.getAttribute('data-srcset'));
      image.removeAttribute('data-srcset');
    } else if (image.hasAttribute('data-src')) {
      image.src = image.getAttribute('data-src');
      image.removeAttribute('data-src');
    }
    image.classList.remove(opts.load_class);
  };

  return {
    init : init,
    loadImages : loadImages
  };
})();
