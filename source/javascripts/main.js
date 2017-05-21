//= require_tree ./application

if (document.readyState !== 'loading') {
  Acadia.LazyLoad.init();
} else {
  document.addEventListener('DOMContentLoaded', Acadia.LazyLoad.init);
}
