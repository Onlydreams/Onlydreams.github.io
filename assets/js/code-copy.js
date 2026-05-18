(function () {
  "use strict";

  function onReady(callback) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", callback);
    } else {
      callback();
    }
  }

  function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text).catch(function () {
        return copyTextFallback(text);
      });
    }

    return copyTextFallback(text);
  }

  function copyTextFallback(text) {
    return new Promise(function (resolve, reject) {
      const textarea = document.createElement("textarea");
      textarea.value = text;
      textarea.setAttribute("readonly", "");
      textarea.style.position = "fixed";
      textarea.style.top = "-9999px";
      document.body.appendChild(textarea);
      textarea.select();

      try {
        if (document.execCommand("copy")) {
          resolve();
        } else {
          reject(new Error("Copy command was not accepted"));
        }
      } catch (error) {
        reject(error);
      } finally {
        textarea.remove();
      }
    });
  }

  function setCopyButtonState(button, label) {
    button.textContent = label;
    window.setTimeout(function () {
      button.textContent = "复制";
    }, 1600);
  }

  function initCodeCopyButtons() {
    document
      .querySelectorAll(".highlighter-rouge > .highlight")
      .forEach(function (block) {
        const code = block.querySelector("pre code");
        if (!code) return;

        block.classList.add("code-block-with-copy");

        const existingButtons = block.querySelectorAll(".code-copy-button");
        existingButtons.forEach(function (button, index) {
          if (index > 0) {
            button.remove();
          }
        });

        if (existingButtons.length > 0) return;

        const button = document.createElement("button");
        button.type = "button";
        button.className = "code-copy-button";
        button.textContent = "复制";
        button.setAttribute("aria-label", "复制代码");

        button.addEventListener("click", function () {
          copyText(code.textContent)
            .then(function () {
              setCopyButtonState(button, "已复制");
            })
            .catch(function () {
              setCopyButtonState(button, "复制失败");
            });
        });

        block.appendChild(button);
      });
  }

  onReady(initCodeCopyButtons);
})();
