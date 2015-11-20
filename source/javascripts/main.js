//= require_tree .

if (document.readyState !== 'loading') {
  Acadia.LazyLoad.loadImages();
}

document.addEventListener('scroll', Acadia.LazyLoad.handleScroll);
