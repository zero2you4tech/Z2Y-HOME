(function () {
  "use strict";

  var root = document.documentElement;

  function setLanguage(language, persist) {
    var normalized = language === "en" ? "en" : "zh";
    root.setAttribute("data-lang", normalized);
    root.lang = normalized === "zh" ? "zh-CN" : "en";

    document.querySelectorAll("[data-set-lang]").forEach(function (button) {
      var active = button.getAttribute("data-set-lang") === normalized;
      button.classList.toggle("is-active", active);
      button.setAttribute("aria-pressed", active ? "true" : "false");
    });

    document.querySelectorAll("[data-placeholder-zh][data-placeholder-en]").forEach(function (input) {
      var placeholder = input.getAttribute(normalized === "zh" ? "data-placeholder-zh" : "data-placeholder-en");
      input.setAttribute("placeholder", placeholder);
      input.setAttribute("aria-label", placeholder);
    });

    if (persist) {
      try {
        localStorage.setItem("z2y-lang", normalized);
      } catch (error) {
        // Language still applies for the current page when storage is unavailable.
      }
    }
  }

  document.querySelectorAll("[data-set-lang]").forEach(function (button) {
    button.addEventListener("click", function () {
      setLanguage(button.getAttribute("data-set-lang"), true);
    });
  });

  var savedLanguage = null;
  try {
    savedLanguage = localStorage.getItem("z2y-lang");
  } catch (error) {
    savedLanguage = null;
  }

  setLanguage(savedLanguage || root.getAttribute("data-lang") || "zh", false);

  document.querySelectorAll("[data-app-controls]").forEach(function (controls) {
    var page = controls.closest(".z2y-page") || document;
    var grid = page.querySelector("[data-app-grid]");
    if (!grid) return;

    var emptyState = page.querySelector("[data-app-empty]");
    var searchInput = controls.querySelector("[data-app-search]");
    var filterButtons = controls.querySelectorAll("[data-filter]");
    var activeFilter = "all";

    function matchesFilter(card) {
      var platform = (card.getAttribute("data-platform") || "").toLowerCase();
      var status = (card.getAttribute("data-status") || "").toLowerCase();

      if (activeFilter === "all") return true;
      if (activeFilter === "macos") return platform.indexOf("macos") !== -1;
      if (activeFilter === "ios") return platform.indexOf("ios") !== -1;
      if (activeFilter === "available") return status === "available";
      if (activeFilter === "in-development") return status === "in-development" || status === "preview";
      return true;
    }

    function applyFilters() {
      var query = (searchInput && searchInput.value ? searchInput.value : "").trim().toLowerCase();
      var visible = 0;

      grid.querySelectorAll("[data-app-card]").forEach(function (card) {
        var haystack = (card.getAttribute("data-search") || "").toLowerCase();
        var show = matchesFilter(card) && (!query || haystack.indexOf(query) !== -1);
        card.classList.toggle("is-filtered", !show);
        if (show) visible += 1;
      });

      if (emptyState) {
        emptyState.hidden = visible !== 0;
      }
    }

    filterButtons.forEach(function (button) {
      button.addEventListener("click", function () {
        activeFilter = button.getAttribute("data-filter") || "all";
        filterButtons.forEach(function (item) {
          item.classList.toggle("is-active", item === button);
        });
        applyFilters();
      });
    });

    if (searchInput) {
      searchInput.addEventListener("input", applyFilters);
    }

    applyFilters();
  });

  window.addEventListener("storage", function (event) {
    if (event.key === "z2y-lang" && event.newValue) {
      setLanguage(event.newValue, false);
    }
  });
})();
