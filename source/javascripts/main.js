//= require_tree .

if (document.readyState !== 'loading') {
  Acadia.LazyLoad.init();
} else {
  document.addEventListener('DOMContentLoaded', Acadia.LazyLoad.init);
}
