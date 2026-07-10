// urlbar-nav.js — Vivaldi UI mod
// Make Ctrl+N / Ctrl+P navigate the address-bar suggestion list
// (down / up), instead of macOS Emacs bindings jumping the caret to
// end / start of the field.
//
// Set window.__urlbarNavDebug = true in the UI devtools console to log
// which element each keystroke targets (useful if the address field
// isn't being matched on some future Vivaldi version).
(function () {
  'use strict';
  if (window.__urlbarNavInstalled) return;
  window.__urlbarNavInstalled = true;

  // Identify an autocomplete text field (address bar / search field).
  // Prefer version-resilient ARIA signals; fall back to container names.
  function isAutocompleteField(el) {
    if (!el || el.tagName !== 'INPUT') return false;
    const type = (el.type || 'text').toLowerCase();
    if (type !== 'text' && type !== 'search' && type !== 'url') return false;

    if (el.getAttribute('role') === 'combobox') return true;
    if (el.getAttribute('aria-autocomplete')) return true;
    if (el.getAttribute('aria-controls')) return true;

    let node = el;
    for (let i = 0; i < 6 && node; i++, node = node.parentElement) {
      const bag = String(node.id || '') + ' ' + String(node.className || '');
      if (/url|address/i.test(bag)) return true;
    }
    return false;
  }

  function dispatchArrow(el, down) {
    const key = down ? 'ArrowDown' : 'ArrowUp';
    const keyCode = down ? 40 : 38;
    el.dispatchEvent(new KeyboardEvent('keydown', {
      key: key, code: key, keyCode: keyCode, which: keyCode,
      bubbles: true, cancelable: true
    }));
  }

  window.addEventListener('keydown', function (e) {
    // Only bare Ctrl+N / Ctrl+P (no other modifiers).
    if (!e.ctrlKey || e.metaKey || e.altKey || e.shiftKey) return;
    const k = e.key.toLowerCase();
    if (k !== 'n' && k !== 'p') return;

    const el = e.target;
    if (window.__urlbarNavDebug) {
      console.log('[urlbar-nav]', k, el && el.tagName, el && el.className,
                  'match=' + isAutocompleteField(el));
    }
    if (!isAutocompleteField(el)) return;

    // Suppress the macOS Emacs caret-jump default, then drive the list.
    e.preventDefault();
    e.stopPropagation();
    dispatchArrow(el, k === 'n');
  }, true); // capture phase: run before the text-editing default
})();
