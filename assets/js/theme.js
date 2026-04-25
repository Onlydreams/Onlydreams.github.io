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

  function updateGiscusTheme(theme) {
    const giscusScript = document.querySelector('script[src*="giscus.app"]');
    if (giscusScript) {
      giscusScript.setAttribute('data-theme', theme === 'dark' ? GISCUS_DARK : GISCUS_LIGHT);
    }

    // Update existing giscus iframe via postMessage
    const iframe = document.querySelector('iframe.giscus-frame');
    if (iframe && iframe.contentWindow) {
      iframe.contentWindow.postMessage({
        giscus: {
          setConfig: {
            theme: theme === 'dark' ? GISCUS_DARK : GISCUS_LIGHT
          }
        }
      }, 'https://giscus.app');
    }
  }

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
    btn.textContent = theme === 'dark' ? '☀️' : '🌙';
    btn.setAttribute('aria-label', theme === 'dark' ? '切换到日间模式' : '切换到夜间模式');
  }

  function init() {
    const theme = getTheme();
    applyTheme(theme);

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
