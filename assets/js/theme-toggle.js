(function () {
  "use strict";

  const STORAGE_KEY = "blog-theme";

  const ICON_SUN =
    '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 2v2"/><path d="M12 20v2"/><path d="m4.93 4.93 1.41 1.41"/><path d="m17.66 17.66 1.41 1.41"/><path d="M2 12h2"/><path d="M20 12h2"/><path d="m6.34 17.66-1.41 1.41"/><path d="m19.07 4.93-1.41 1.41"/></svg>';
  const ICON_MOON =
    '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"/></svg>';

  let lastPostedGiscusTheme = null;
  let pendingGiscusTheme = null;

  function onReady(callback) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", callback);
    } else {
      callback();
    }
  }

  function getSystemTheme() {
    return window.matchMedia("(prefers-color-scheme: dark)").matches
      ? "dark"
      : "light";
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
    document.documentElement.setAttribute("data-theme", theme);
    updateGiscusTheme(theme);
  }

  function sendGiscusMessage(message, retries, onPost, onGiveUp) {
    retries = retries || 0;
    const iframe = document.querySelector("iframe.giscus-frame");
    if (
      iframe &&
      iframe.src &&
      iframe.src.indexOf("giscus.app") !== -1 &&
      iframe.contentWindow
    ) {
      try {
        iframe.contentWindow.postMessage(
          { giscus: message },
          "https://giscus.app",
        );
        if (onPost) onPost();
      } catch (e) {
        // Silently ignore cross-origin errors during iframe load
      }
    } else if (retries < 30) {
      setTimeout(function () {
        sendGiscusMessage(message, retries + 1, onPost, onGiveUp);
      }, 300);
    } else if (onGiveUp) {
      onGiveUp();
    }
  }

  function getGiscusThemeUrl(theme) {
    const giscusScript = document.querySelector('script[src*="giscus.app"]');
    if (!giscusScript) return null;

    if (theme === "dark") {
      return giscusScript.getAttribute("data-theme-dark") || "dark";
    }

    return giscusScript.getAttribute("data-theme-light") || "light";
  }

  function updateGiscusTheme(theme, force) {
    const newTheme = getGiscusThemeUrl(theme);
    if (!newTheme) return;

    const giscusScript = document.querySelector('script[src*="giscus.app"]');
    if (giscusScript) {
      giscusScript.setAttribute("data-theme", newTheme);
    }

    if (
      !force &&
      (lastPostedGiscusTheme === newTheme || pendingGiscusTheme === newTheme)
    ) {
      return;
    }

    pendingGiscusTheme = newTheme;

    sendGiscusMessage(
      { setConfig: { theme: newTheme } },
      0,
      function () {
        lastPostedGiscusTheme = newTheme;
        if (pendingGiscusTheme === newTheme) {
          pendingGiscusTheme = null;
        }
      },
      function () {
        if (pendingGiscusTheme === newTheme) {
          pendingGiscusTheme = null;
        }
      },
    );
  }

  function updateToggleButton(theme) {
    const btn = document.getElementById("theme-toggle");
    if (!btn) return;
    btn.innerHTML =
      theme === "dark"
        ? ICON_SUN + "<span>浅色</span>"
        : ICON_MOON + "<span>深色</span>";
    btn.setAttribute(
      "aria-label",
      theme === "dark" ? "切换到日间模式" : "切换到夜间模式",
    );
  }

  function toggleTheme() {
    const current = getTheme();
    const next = current === "dark" ? "light" : "dark";
    setStoredTheme(next);
    document.documentElement.setAttribute("data-theme", next);
    updateGiscusTheme(next, true);
    updateToggleButton(next);
  }

  window.addEventListener("message", function (event) {
    if (event.origin !== "https://giscus.app") return;
    if (event.data && event.data.giscus) {
      updateGiscusTheme(getTheme());
    }
  });

  function initThemeToggle() {
    const theme = getTheme();
    applyTheme(theme);

    let btn = document.getElementById("theme-toggle");
    if (!btn) {
      btn = document.createElement("button");
      btn.id = "theme-toggle";
      btn.className = "theme-toggle";
      btn.setAttribute("aria-label", "切换主题");
      btn.addEventListener("click", toggleTheme);
      document.body.appendChild(btn);
    }
    updateToggleButton(theme);

    window
      .matchMedia("(prefers-color-scheme: dark)")
      .addEventListener("change", function (e) {
        if (!getStoredTheme()) {
          const newTheme = e.matches ? "dark" : "light";
          applyTheme(newTheme);
          updateToggleButton(newTheme);
        }
      });
  }

  onReady(initThemeToggle);
})();
