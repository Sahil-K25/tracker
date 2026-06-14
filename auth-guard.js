/* ============================================================
 * auth-guard.js — per-page login gate for the Patron / Rowan suite.
 *
 * Include near the top of <head>, right after the theme-flash script,
 * paired with `<style>html{visibility:hidden}</style>`:
 *
 *   <style>html{visibility:hidden}</style>
 *   <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
 *   <script src="auth-guard.js"></script>
 *
 * Key resolution mirrors db.js (localStorage override, then /api/config).
 * If this deploy has no Supabase project configured at all, there's nothing
 * to authenticate against — reveal the page as-is (same local-only fallback
 * as db.js). Otherwise, require a signed-in session; if there isn't one,
 * bounce to login.html?redirect=<this page>.
 * ============================================================ */
(function () {
  function reveal() { document.documentElement.style.visibility = ''; }

  function start(url, key) {
    if (!url || !key || !window.supabase || url.indexOf('PASTE-') === 0) { reveal(); return; }
    try {
      var sb = window.supabase.createClient(url, key);
      sb.auth.getSession().then(function (res) {
        var session = res.data && res.data.session;
        if (!session) {
          location.replace('login.html?redirect=' + encodeURIComponent(location.pathname + location.search));
          return;
        }
        window.PatronAuth = {
          client: sb,
          user: session.user,
          signOut: function () { return sb.auth.signOut().then(function () { location.href = 'login.html'; }); },
        };
        reveal();
        sb.auth.onAuthStateChange(function (event) {
          if (event === 'SIGNED_OUT') location.href = 'login.html';
        });
      }).catch(reveal);
    } catch (_) { reveal(); }
  }

  var ovUrl = '', ovKey = '';
  try {
    ovUrl = (localStorage.getItem('po_supabase_url') || '').trim();
    ovKey = (localStorage.getItem('po_supabase_key') || '').trim();
  } catch (_) {}
  if (ovUrl && ovKey) { start(ovUrl, ovKey); return; }

  fetch('/api/config', { cache: 'no-store' })
    .then(function (r) { return r.ok ? r.json() : { url: '', key: '' }; })
    .then(function (cfg) { start((cfg && cfg.url || '').trim(), (cfg && cfg.key || '').trim()); })
    .catch(reveal);
})();
