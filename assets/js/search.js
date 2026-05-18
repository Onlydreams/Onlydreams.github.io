(function () {
  "use strict";

  function onReady(callback) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", callback);
    } else {
      callback();
    }
  }

  function normalizeSearchText(value) {
    return (value || "").toString().trim().toLowerCase();
  }

  function createSearchResult(item) {
    const li = document.createElement("li");
    li.className = "search-result";

    const link = document.createElement("a");
    link.href = item.url;
    link.textContent = item.title;

    const meta = document.createElement("div");
    meta.className = "search-result-meta";
    meta.textContent = item.updated ? `更新于 ${item.updated}` : item.date;

    const excerpt = document.createElement("p");
    excerpt.className = "search-result-excerpt";
    excerpt.textContent = item.content.slice(0, 120);

    li.appendChild(link);
    li.appendChild(meta);
    li.appendChild(excerpt);
    return li;
  }

  function renderSearchResults(results, resultsEl, statusEl, query) {
    resultsEl.innerHTML = "";

    if (!query) {
      statusEl.textContent = "输入关键词开始搜索。";
      return;
    }

    if (results.length === 0) {
      statusEl.textContent = "没有找到匹配文章。";
      return;
    }

    statusEl.textContent = `找到 ${results.length} 篇相关文章。`;
    results.forEach(function (item) {
      resultsEl.appendChild(createSearchResult(item));
    });
  }

  function searchPosts(index, query) {
    const normalizedQuery = normalizeSearchText(query);
    if (!normalizedQuery) return [];

    return index
      .filter(function (item) {
        const haystack = normalizeSearchText(
          [
            item.title,
            item.content,
            (item.categories || []).join(" "),
            (item.tags || []).join(" "),
          ].join(" "),
        );
        return haystack.indexOf(normalizedQuery) !== -1;
      })
      .slice(0, 10);
  }

  function initSiteSearch() {
    const input = document.getElementById("search-input");
    const resultsEl = document.getElementById("search-results");
    const statusEl = document.getElementById("search-status");
    if (!input || !resultsEl || !statusEl) return;

    const indexUrl = input.getAttribute("data-search-index") || "/search.json";
    let composing = false;
    statusEl.textContent = "加载搜索索引…";

    fetch(indexUrl)
      .then(function (response) {
        if (!response.ok) {
          throw new Error("Search index request failed");
        }
        return response.json();
      })
      .then(function (index) {
        function runSearch() {
          const query = input.value;
          renderSearchResults(
            searchPosts(index, query),
            resultsEl,
            statusEl,
            query,
          );
        }

        input.addEventListener("compositionstart", function () {
          composing = true;
        });

        input.addEventListener("compositionend", function () {
          composing = false;
          runSearch();
        });

        input.addEventListener("input", function () {
          if (composing) return;
          runSearch();
        });

        runSearch();
      })
      .catch(function (error) {
        console.error("Search index load failed:", error);
        statusEl.textContent = "搜索索引加载失败。";
      });
  }

  onReady(initSiteSearch);
})();
