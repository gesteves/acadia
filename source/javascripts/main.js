//= require_tree ./application

if (document.readyState !== 'loading') {
  Acadia.LazyLoad.init();
} else {
  document.addEventListener('DOMContentLoaded', Acadia.LazyLoad.init);
}

if (navigator.serviceWorker) {
  navigator.serviceWorker.register('/service_worker.js', {
    scope: '/'
  });
}
