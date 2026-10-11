{{flutter_js}}
{{flutter_build_config}}

// Development previews must not be pinned to yesterday's Flutter bundle.
// The production PWA service worker is unaffected by this localhost-only path.
(async () => {
  const local = location.hostname === 'localhost' ||
                location.hostname === '127.0.0.1';
  if (local) {
    if ('serviceWorker' in navigator) {
      try {
        const registrations = await navigator.serviceWorker.getRegistrations();
        if (registrations.length > 0) {
          await Promise.all(registrations.map((entry) => entry.unregister()));
          // An already-controlled tab needs one reload to release its worker.
          const key = 'wantok-preview-sw-released-v1';
          if (navigator.serviceWorker.controller &&
              sessionStorage.getItem(key) !== '1') {
            sessionStorage.setItem(key, '1');
            location.reload();
            return;
          }
        }
      } catch (error) {
        console.warn('Unable to release preview service worker:', error);
      }
    }
    _flutter.loader.load();
    return;
  }

  _flutter.loader.load({
    serviceWorkerSettings: {
      serviceWorkerVersion: {{flutter_service_worker_version}}
    }
  });
})();
