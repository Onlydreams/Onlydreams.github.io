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

  function clearCopyButtonReset(button) {
    if (button.copyResetTimer) {
      window.clearTimeout(button.copyResetTimer);
      button.copyResetTimer = null;
    }
  }

  function setCopyButtonState(button, label, state) {
    clearCopyButtonReset(button);
    button.textContent = label;
    button.dataset.state = state;

    button.copyResetTimer = window.setTimeout(function () {
      button.textContent = button.dataset.defaultLabel || "复制";
      button.dataset.state = "idle";
      button.copyResetTimer = null;
    }, 1600);
  }

  function getPromptCommand(line) {
    const shellPrompt = line.match(/^\s*(?:[$%>])\s+(.+)$/);
    if (shellPrompt) return shellPrompt[1];

    const powershellPrompt = line.match(/^\s*PS\s+[^>]+>\s*(.+)$/);
    if (powershellPrompt) return powershellPrompt[1];

    const windowsPrompt = line.match(/^\s*[A-Za-z]:\\[^>]*>\s*(.+)$/);
    if (windowsPrompt) return windowsPrompt[1];

    return null;
  }

  function getHeredocTerminator(command) {
    const heredoc = command.match(/<<-?\s*['"]?([A-Za-z0-9_]+)['"]?/);

    return heredoc ? heredoc[1] : null;
  }

  function endsWithLineContinuation(line) {
    return /\\\s*$/.test(line);
  }

  function getCommandBlockElement(block) {
    if (block.closest) {
      const closestBlock = block.closest(".highlighter-rouge");
      if (closestBlock) return closestBlock;
    }

    let element = block;

    while (element && element !== document.body) {
      if (
        element.className &&
        /\bhighlighter-rouge\b/.test(element.className)
      ) {
        return element;
      }

      element = element.parentElement || element.parentNode;
    }

    return block;
  }

  function isCommandBlock(block, code) {
    const commandBlock = getCommandBlockElement(block);
    const className = [commandBlock.className, block.className, code.className].join(
      " "
    );

    return /\blanguage-(bash|sh|shell|zsh|powershell|ps1|console|terminal)\b/.test(
      className
    );
  }

  function getCopyText(block, code) {
    const text = code.textContent.replace(/\s+$/, "");
    if (!isCommandBlock(block, code)) return text;

    const lines = text.split(/\r?\n/);
    const commandLines = [];
    let heredocTerminator = null;
    let inContinuation = false;

    lines.forEach(function (line) {
      const command = getPromptCommand(line);
      if (command !== null) {
        commandLines.push(command);
        heredocTerminator = getHeredocTerminator(command);
        inContinuation = endsWithLineContinuation(command);
        return;
      }

      if (heredocTerminator) {
        commandLines.push(line);
        if (line.trim() === heredocTerminator) {
          heredocTerminator = null;
        }
        return;
      }

      if (inContinuation) {
        commandLines.push(line);
        inContinuation = endsWithLineContinuation(line);
      }
    });

    if (commandLines.length > 0) {
      return commandLines.join("\n");
    }

    return text;
  }

  function getCopyButtonLabel(block, code) {
    if (!isCommandBlock(block, code)) return "复制";

    return "复制命令";
  }

  function initCodeCopyButtons() {
    document.querySelectorAll(".highlighter-rouge").forEach(function (wrapper) {
      const block = wrapper.querySelector(".highlight");
      if (!block) return;

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
      button.dataset.defaultLabel = getCopyButtonLabel(wrapper, code);
      button.dataset.state = "idle";
      button.textContent = button.dataset.defaultLabel;
      button.setAttribute("aria-label", button.dataset.defaultLabel);
      button.setAttribute("aria-live", "polite");

      button.addEventListener("click", function () {
        clearCopyButtonReset(button);
        button.disabled = true;
        button.dataset.state = "copying";
        button.textContent = "复制中";

        copyText(getCopyText(wrapper, code))
          .then(function () {
            setCopyButtonState(button, "已复制", "success");
          })
          .catch(function () {
            setCopyButtonState(button, "复制失败", "error");
          })
          .finally(function () {
            button.disabled = false;
          });
      });

      block.appendChild(button);
    });
  }

  onReady(initCodeCopyButtons);
})();
