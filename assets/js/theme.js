(function() {
  'use strict';

  const STORAGE_KEY = 'blog-theme';
  const GISCUS_LIGHT = 'https://onlydreams.github.io/assets/giscus-theme.css';
  const GISCUS_DARK = 'https://onlydreams.github.io/assets/giscus-theme-dark.css';

  function getSystemTheme() {
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }

  function getStoredTheme() {
    try {
      return localStorage.getItem(STORAGE_KEY);
    } catch (e) {
      return null;
    }
  }

  function setStoredTheme(theme) {
    try {
      localStorage.setItem(STORAGE_KEY, theme);
    } catch (e) {
      // ignore
    }
  }

  function getTheme() {
    return getStoredTheme() || getSystemTheme();
  }

  function applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    updateGiscusTheme(theme);
  }

  function sendGiscusMessage(message, retries) {
    retries = retries || 0;
    const iframe = document.querySelector('iframe.giscus-frame');
    if (iframe && iframe.src && iframe.src.indexOf('giscus.app') !== -1 && iframe.contentWindow) {
      try {
        iframe.contentWindow.postMessage({ giscus: message }, 'https://giscus.app');
      } catch (e) {
        // Silently ignore cross-origin errors during iframe load
      }
    } else if (retries < 10) {
      setTimeout(function() {
        sendGiscusMessage(message, retries + 1);
      }, 300);
    }
  }

  function updateGiscusTheme(theme) {
    var newTheme = theme === 'dark' ? GISCUS_DARK : GISCUS_LIGHT;

    // Update script tag for future loads
    var giscusScript = document.querySelector('script[src*="giscus.app"]');
    if (giscusScript) {
      giscusScript.setAttribute('data-theme', newTheme);
    }

    // Update existing giscus iframe via postMessage with retry
    sendGiscusMessage({ setConfig: { theme: newTheme } });
  }

  // Listen for giscus iframe ready events and re-apply theme
  window.addEventListener('message', function(event) {
    if (event.origin !== 'https://giscus.app') return;
    if (event.data && event.data.giscus) {
      var theme = getTheme();
      updateGiscusTheme(theme);
    }
  });

  function toggleTheme() {
    const current = getTheme();
    const next = current === 'dark' ? 'light' : 'dark';
    setStoredTheme(next);
    applyTheme(next);
    updateToggleButton(next);
  }

  function updateToggleButton(theme) {
    const btn = document.getElementById('theme-toggle');
    if (!btn) return;
    btn.innerHTML = theme === 'dark' ? '☀️<span>浅色</span>' : '🌙<span>深色</span>';
    btn.setAttribute('aria-label', theme === 'dark' ? '切换到日间模式' : '切换到夜间模式');
  }

  function autoTagCallouts() {
    const keywords = /注意|提示|警告|warning|note|tip|caution|alert|important/i;
    document.querySelectorAll('blockquote').forEach(function(bq) {
      if (keywords.test(bq.textContent) && !bq.classList.contains('note')) {
        bq.classList.add('note');
      }
    });
  }

  function init() {
    const theme = getTheme();
    applyTheme(theme);
    autoTagCallouts();

    // Create toggle button if not exists
    let btn = document.getElementById('theme-toggle');
    if (!btn) {
      btn = document.createElement('button');
      btn.id = 'theme-toggle';
      btn.className = 'theme-toggle';
      btn.setAttribute('aria-label', '切换主题');
      btn.addEventListener('click', toggleTheme);
      document.body.appendChild(btn);
    }
    updateToggleButton(theme);

    // Listen for system theme changes
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function(e) {
      if (!getStoredTheme()) {
        const newTheme = e.matches ? 'dark' : 'light';
        applyTheme(newTheme);
        updateToggleButton(newTheme);
      }
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
