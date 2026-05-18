(function () {
  "use strict";

  function onReady(callback) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", callback);
    } else {
      callback();
    }
  }

  function markActiveNav() {
    const path = window.location.pathname.replace(/\/$/, "") || "/";
    document.querySelectorAll(".site-nav .page-link").forEach(function (link) {
      try {
        const linkPath =
          new URL(link.href, window.location.origin).pathname.replace(
            /\/$/,
            "",
          ) || "/";
        if (linkPath === path) {
          link.setAttribute("aria-current", "page");
        }
      } catch (e) {
        // ignore
      }
    });
  }

  function autoTagCallouts() {
    const keywords = /注意|提示|警告|warning|note|tip|caution|alert|important/i;
    document.querySelectorAll("blockquote").forEach(function (bq) {
      if (keywords.test(bq.textContent) && !bq.classList.contains("note")) {
        bq.classList.add("note");
      }
    });
  }

  function initBackToTop() {
    const btn = document.getElementById("back-to-top");
    if (!btn) return;

    let ticking = false;

    function onScroll() {
      if (!ticking) {
        window.requestAnimationFrame(function () {
          if (window.scrollY > 400) {
            btn.classList.add("visible");
          } else {
            btn.classList.remove("visible");
          }
          ticking = false;
        });
        ticking = true;
      }
    }

    btn.addEventListener("click", function () {
      const reduceMotion = window.matchMedia(
        "(prefers-reduced-motion: reduce)",
      ).matches;
      window.scrollTo({ top: 0, behavior: reduceMotion ? "auto" : "smooth" });
    });

    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
  }

  function initPostToc() {
    const toc = document.querySelector(".post-toc[data-toc-source]");
    if (!toc) return;

    const source = document.querySelector(toc.dataset.tocSource);
    const list = toc.querySelector("#markdown-toc");
    if (!source || !list) {
      toc.hidden = true;
      return;
    }

    const headings = source.querySelectorAll("h2[id], h3[id]");
    if (!headings.length) {
      toc.hidden = true;
      return;
    }

    let currentSection = null;

    headings.forEach(function (heading) {
      const link = document.createElement("a");
      link.href = "#" + heading.id;
      link.textContent = heading.textContent.trim();

      const item = document.createElement("li");
      item.appendChild(link);

      if (heading.tagName === "H2") {
        list.appendChild(item);
        currentSection = item;
      } else if (currentSection) {
        let childList = currentSection.querySelector("ul");
        if (!childList) {
          childList = document.createElement("ul");
          currentSection.appendChild(childList);
        }
        childList.appendChild(item);
      }
    });

    if (list.children.length) {
      toc.hidden = false;
    }
  }

  window.SiteEnhancements = window.SiteEnhancements || {};
  window.SiteEnhancements.initPostToc = initPostToc;

  onReady(function () {
    autoTagCallouts();
    markActiveNav();
    initBackToTop();
    initPostToc();
  });
})();
