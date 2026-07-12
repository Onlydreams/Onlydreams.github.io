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

  function createHighlightedText(element, value, query) {
    const text = (value || "").toString();
    const normalizedQuery = normalizeSearchText(query);
    const normalizedText = text.toLowerCase();
    let cursor = 0;
    let matchIndex = normalizedText.indexOf(normalizedQuery, cursor);

    element.textContent = "";
    if (!normalizedQuery || matchIndex === -1) {
      element.appendChild(document.createTextNode(text));
      return;
    }

    while (matchIndex !== -1) {
      element.appendChild(document.createTextNode(text.slice(cursor, matchIndex)));

      const highlight = document.createElement("mark");
      highlight.className = "search-highlight";
      highlight.textContent = text.slice(matchIndex, matchIndex + normalizedQuery.length);
      element.appendChild(highlight);

      cursor = matchIndex + normalizedQuery.length;
      matchIndex = normalizedText.indexOf(normalizedQuery, cursor);
    }

    element.appendChild(document.createTextNode(text.slice(cursor)));
  }

  function excerptForSearchResult(content, query) {
    const text = (content || "").toString();
    const normalizedQuery = normalizeSearchText(query);
    const matchIndex = text.toLowerCase().indexOf(normalizedQuery);

    if (!normalizedQuery || matchIndex === -1) {
      return text.slice(0, 180);
    }

    const start = Math.max(0, matchIndex - 72);
    const end = Math.min(text.length, matchIndex + normalizedQuery.length + 108);
    return `${start > 0 ? "…" : ""}${text.slice(start, end)}${end < text.length ? "…" : ""}`;
  }

  function appendMetaGroup(meta, label, values, query) {
    const normalizedValues = values.filter(Boolean);
    if (normalizedValues.length === 0) return;

    const group = document.createElement("span");
    group.className = "search-result-meta-group";
    group.appendChild(document.createTextNode(`${label}：`));

    normalizedValues.forEach(function (value, index) {
      if (index > 0) {
        group.appendChild(document.createTextNode("、"));
      }
      const valueEl = document.createElement("span");
      createHighlightedText(valueEl, value, query);
      group.appendChild(valueEl);
    });

    meta.appendChild(group);
  }

  function createSearchResult(item, query) {
    const li = document.createElement("li");
    li.className = "search-result";

    const link = document.createElement("a");
    link.href = item.url;
    createHighlightedText(link, item.title, query);

    const meta = document.createElement("div");
    meta.className = "search-result-meta";
    appendMetaGroup(meta, item.updated ? "更新" : "发布", [item.updated || item.date], query);
    appendMetaGroup(meta, "分类", item.categories || [], query);
    appendMetaGroup(meta, "标签", item.tags || [], query);
    appendMetaGroup(meta, "状态", [item.status], query);

    const excerpt = document.createElement("p");
    excerpt.className = "search-result-excerpt";
    createHighlightedText(excerpt, excerptForSearchResult(item.content, query), query);

    li.appendChild(link);
    li.appendChild(meta);
    li.appendChild(excerpt);
    return li;
  }

  function hasSearchCriteria(state) {
    return Boolean(state.query || state.category || state.tag || state.status);
  }

  function renderSearchResults(results, resultsEl, statusEl, state) {
    resultsEl.innerHTML = "";

    if (!hasSearchCriteria(state)) {
      statusEl.textContent = "输入关键词或选择筛选条件开始浏览。";
      return;
    }

    if (results.length === 0) {
      statusEl.textContent = "没有找到匹配文章。";
      return;
    }

    const visibleResults = results.slice(0, 10);
    statusEl.textContent =
      results.length > visibleResults.length
        ? `找到 ${results.length} 篇相关文章，显示前 ${visibleResults.length} 篇。`
        : `找到 ${results.length} 篇相关文章。`;
    visibleResults.forEach(function (item) {
      resultsEl.appendChild(createSearchResult(item, state.query));
    });
  }

  function searchPosts(index, state) {
    const normalizedQuery = normalizeSearchText(state.query);

    return index
      .filter(function (item) {
        const haystack = normalizeSearchText(
          [
            item.title,
            item.content,
            (item.categories || []).join(" "),
            (item.tags || []).join(" "),
            item.status,
          ].join(" "),
        );
        const matchesQuery = !normalizedQuery || haystack.indexOf(normalizedQuery) !== -1;
        const matchesCategory =
          !state.category || (item.categories || []).indexOf(state.category) !== -1;
        const matchesTag = !state.tag || (item.tags || []).indexOf(state.tag) !== -1;
        const matchesStatus = !state.status || item.status === state.status;

        return matchesQuery && matchesCategory && matchesTag && matchesStatus;
      })
      .sort(function (left, right) {
        return right.date.localeCompare(left.date);
      });
  }

  function uniqueValues(index, field) {
    return Array.from(
      new Set(
        index.flatMap(function (item) {
          const value = item[field];
          return Array.isArray(value) ? value : [value];
        }),
      ),
    )
      .filter(Boolean)
      .sort(function (left, right) {
        return left.localeCompare(right, "zh-CN");
      });
  }

  function populateSelect(select, values) {
    values.forEach(function (value) {
      const option = document.createElement("option");
      option.value = value;
      option.textContent = value;
      select.appendChild(option);
    });
  }

  function searchStateFromControls(input, category, tag, status) {
    return {
      query: input.value.trim(),
      category: category.value,
      tag: tag.value,
      status: status.value,
    };
  }

  function syncSearchUrl(state) {
    const params = new URLSearchParams(window.location.search);
    const values = {
      q: state.query,
      category: state.category,
      tag: state.tag,
      status: state.status,
    };

    Object.keys(values).forEach(function (key) {
      params.delete(key);
      if (values[key]) params.set(key, values[key]);
    });

    const query = params.toString();
    const url = `${window.location.pathname}${query ? `?${query}` : ""}${window.location.hash}`;
    window.history.replaceState(null, "", url);
  }

  function initSiteSearch() {
    const input = document.getElementById("search-input");
    const category = document.getElementById("search-category");
    const tag = document.getElementById("search-tag");
    const status = document.getElementById("search-status-filter");
    const resultsEl = document.getElementById("search-results");
    const statusEl = document.getElementById("search-status");
    if (!input || !category || !tag || !status || !resultsEl || !statusEl) return;

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
        const params = new URLSearchParams(window.location.search);
        input.value = params.get("q") || "";
        populateSelect(category, uniqueValues(index, "categories"));
        populateSelect(tag, uniqueValues(index, "tags"));
        populateSelect(status, uniqueValues(index, "status"));
        category.value = params.get("category") || "";
        tag.value = params.get("tag") || "";
        status.value = params.get("status") || "";

        function runSearch(shouldSyncUrl) {
          const state = searchStateFromControls(input, category, tag, status);
          if (shouldSyncUrl) syncSearchUrl(state);
          renderSearchResults(searchPosts(index, state), resultsEl, statusEl, state);
        }

        input.addEventListener("compositionstart", function () {
          composing = true;
        });

        input.addEventListener("compositionend", function () {
          composing = false;
          runSearch(true);
        });

        input.addEventListener("input", function () {
          if (composing) return;
          runSearch(true);
        });

        [category, tag, status].forEach(function (select) {
          select.addEventListener("change", function () {
            runSearch(true);
          });
        });

        runSearch(false);
      })
      .catch(function (error) {
        console.error("Search index load failed:", error);
        statusEl.textContent = "搜索索引加载失败。";
      });
  }

  onReady(initSiteSearch);
})();
