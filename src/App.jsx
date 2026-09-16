import React, { useEffect, useMemo, useState } from "react";




const STORAGE = {
  theme: "quran-v3-theme",
  tajweed: "quran-v3-tajweed",
  fontSize: "quran-v3-font-size",
  spacing: "quran-v3-spacing",
  bookmarks: "quran-v3-bookmarks",
  lastRead: "quran-v3-last-read"
};

const TAJWEED_RULES = {
  ham_wasl: {
    label: "Hamzat al-Wasl",
    short: "Wasl",
    color: "#a7f3d0"
  },
  laam_shamsiyah: {
    label: "Lam Shamsiyyah",
    short: "Lam Shamsiyyah",
    color: "#67e8f9"
  },
  madda_normal: {
    label: "Madd",
    short: "Madd",
    color: "#fcd34d"
  },
  madda_permissible: {
    label: "Madd Permissible",
    short: "Madd Perm.",
    color: "#fde68a"
  },
  madda_obligatory: {
    label: "Madd Obligatory",
    short: "Madd Obl.",
    color: "#f59e0b"
  },
  madda_necessary: {
    label: "Madd Necessary",
    short: "Madd Nec.",
    color: "#fb923c"
  },
  ghunnah: {
    label: "Ghunnah",
    short: "Ghunnah",
    color: "#34d399"
  },
  ikhfa: {
    label: "Ikhfa",
    short: "Ikhfa",
    color: "#a78bfa"
  },
  ikhfa_shafawi: {
    label: "Ikhfa Shafawi",
    short: "Ikhfa Shafawi",
    color: "#c084fc"
  },
  iqlab: {
    label: "Iqlab",
    short: "Iqlab",
    color: "#fb7185"
  },
  idgham: {
    label: "Idgham",
    short: "Idgham",
    color: "#fb923c"
  },
  idgham_ghunnah: {
    label: "Idgham with Ghunnah",
    short: "Idgham + Ghunnah",
    color: "#f472b6"
  },
  idgham_shafawi: {
    label: "Idgham Shafawi",
    short: "Idgham Shafawi",
    color: "#e879f9"
  },
  qalqalah: {
    label: "Qalqalah",
    short: "Qalqalah",
    color: "#60a5fa"
  },
  qalqalah_major: {
    label: "Qalqalah Major",
    short: "Qalqalah Major",
    color: "#38bdf8"
  },
  qalqalah_minor: {
    label: "Qalqalah Minor",
    short: "Qalqalah Minor",
    color: "#93c5fd"
  },
  silent: {
    label: "Silent Letter",
    short: "Silent",
    color: "#94a3b8"
  },
  small_high: {
    label: "Small High Mark",
    short: "Small Mark",
    color: "#d8b4fe"
  },
  other: {
    label: "Tajweed",
    short: "Tajweed",
    color: "#5eead4"
  }
};

function readStorage(key, fallback) {
  try {
    const value = window.localStorage.getItem(key);
    return value === null ? fallback : JSON.parse(value);
  } catch {
    return fallback;
  }
}

function writeStorage(key, value) {
  try {
    window.localStorage.setItem(key, JSON.stringify(value));
  } catch {
    // Storage may be disabled. Reader still works.
  }
}

async function fetchJson(url) {
  const response = await fetch(url, {
    cache: "no-cache"
  });

  const text = await response.text();

  if (!response.ok) {
    throw new Error(
      `${url} returned HTTP ${response.status}: ${text.slice(0, 300)}`
    );
  }

  try {
    return JSON.parse(text);
  } catch {
    throw new Error(
      `${url} did not return JSON. The server may be rewriting the request to index.html.`
    );
  }
}

function stripTajweedMarkup(text) {
  if (!text) return "";

  return text
    // Remove Tajweed opening tags, including quoted and unquoted class values.
    .replace(/<tajweed\b[^>]*>/gi, "")
    // Remove Tajweed closing tags.
    .replace(/<\/tajweed>/gi, "")
    // Remove Quran Foundation verse-end marker spans only.
    .replace(/<span\b[^>]*class=["']?end["']?[^>]*>[\s\S]*?<\/span>/gi, "")
    // Remove any remaining HTML tags without touching normal text.
    .replace(/<[^>]+>/g, "")
    .replace(/&nbsp;/gi, " ");
}

const AYAH_MARKER_STYLE = {
  display: "inline-flex",
  alignItems: "center",
  justifyContent: "center",
  width: "1.85em",
  height: "1.85em",
  marginInline: "0.28em",
  color: "#c9a227",
  fontFamily: '"Amiri", "Noto Naskh Arabic", serif',
  fontSize: "0.82em",
  fontWeight: 700,
  lineHeight: 1,
  whiteSpace: "nowrap",
  verticalAlign: "middle",
  direction: "rtl",
  unicodeBidi: "isolate",
  position: "relative",
  boxSizing: "border-box",
  border: "0.11em solid currentColor",
  borderRadius: "50%",
  background: "rgba(201, 162, 39, 0.06)",
  boxShadow: "0 0 0 0.07em rgba(201, 162, 39, 0.16), inset 0 0 0.25em rgba(201, 162, 39, 0.08)"
};
function TajweedText({ markup, enabled }) {
  if (!enabled) {
    return (
      <span className="arabic-text" translate="no">
        {stripTajweedMarkup(markup)}
      </span>
    );
  }

  const parts = [];
  let cursor = 0;

  const regex =
    /<tajweed\s+class\s*=\s*(?:"([^"]+)"|'([^']+)'|([^\s>]+))\s*>([\s\S]*?)<\/tajweed>/gi;

  let match;

  while ((match = regex.exec(markup)) !== null) {
    const before = markup.slice(cursor, match.index);

    if (before) {
      parts.push(
        <React.Fragment key={`plain-${cursor}`}>
          {before}
        </React.Fragment>
      );
    }

    const ruleClass = match[1] || match[2] || match[3] || "other";
    const content = match[4];

    const rule =
      TAJWEED_RULES[ruleClass] ||
      TAJWEED_RULES[
        Object.keys(TAJWEED_RULES).find((key) =>
          ruleClass.toLowerCase().includes(key.toLowerCase())
        )
      ] ||
      TAJWEED_RULES.other;

    parts.push(
      <span
        key={`taj-${match.index}`}
        className={`tajweed tajweed-${ruleClass}`}
        style={{ "--tajweed-color": rule.color }}
        title={rule.label}
      >
        {content}
      </span>
    );

    cursor = regex.lastIndex;
  }

  let remaining = markup.slice(cursor);

  /*
   * Quran Foundation includes the ayah number at the end
   * of text_uthmani_tajweed.
   *
   * Example:
   *
   *   عَمَّ يَتَسَآءَلُونَ ١
   *
   * Extract the existing final verse number so we don't
   * create a second number or reference verse.verse_number.
   */

  const numberMatch = remaining.match(/(\d+|[٠-٩]+)\s*$/);

  let ayahNumber = null;

  if (numberMatch) {
    ayahNumber = numberMatch[1];

    remaining = remaining.slice(
      0,
      numberMatch.index
    ).replace(/\s+$/u, "");
  }

  if (remaining) {
    parts.push(
      <React.Fragment key={`remaining-${cursor}`}>
        {remaining}
      </React.Fragment>
    );
  }

  if (ayahNumber) {
    parts.push(
      <span
        key={`ayah-number-${cursor}`}
        className="ayah-marker"
        style={AYAH_MARKER_STYLE}
        aria-label={"Ayah " + ayahNumber}
      >
        <span
          className="ayah-number"
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            width: "100%",
            height: "100%",
            fontSize: "0.62em",
            fontWeight: 700,
            lineHeight: 1,
            position: "relative",
            top: "0.02em"
          }}
        >
          {ayahNumber}
        </span>
      </span>
    );
  }

  return (
    <span className="arabic-text" translate="no">
      {parts}
    </span>
  );
}
function Legend() {
  const entries = Object.entries(TAJWEED_RULES).filter(
    ([key]) => key !== "other" && key !== "small_high"
  );

  return (
    <section className="legend-card">
      <div className="legend-heading">
        <span className="legend-star">✦</span>
        <div>
          <h3>Tajweed Color Guide</h3>
          <p>Quran Foundation Uthmani Tajweed annotations</p>
        </div>
      </div>

      <div className="legend-grid">
        {entries.map(([key, rule]) => (
          <div className="legend-item" key={key}>
            <span
              className="legend-dot"
              style={{ background: rule.color, boxShadow: `0 0 14px ${rule.color}` }}
            />
            <span>{rule.label}</span>
          </div>
        ))}
      </div>
    </section>
  );
}

function App() {
  const [surahs, setSurahs] = useState([]);
  const [currentSurah, setCurrentSurah] = useState(null);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [loadingSurah, setLoadingSurah] = useState(false);
  const [error, setError] = useState("");

  const [theme, setTheme] = useState(
    readStorage(STORAGE.theme, "emerald")
  );

  const [tajweedEnabled, setTajweedEnabled] = useState(
    readStorage(STORAGE.tajweed, true)
  );

  const [fontSize, setFontSize] = useState(
    readStorage(STORAGE.fontSize, 34)
  );

  const [spacing, setSpacing] = useState(
    readStorage(STORAGE.spacing, 2.3)
  );

  const [bookmarks, setBookmarks] = useState(
    readStorage(STORAGE.bookmarks, [])
  );

  const [lastRead, setLastRead] = useState(
    readStorage(STORAGE.lastRead, null)
  );

  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [settingsOpen, setSettingsOpen] = useState(false);

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    writeStorage(STORAGE.theme, theme);
  }, [theme]);

  useEffect(() => {
    writeStorage(STORAGE.tajweed, tajweedEnabled);
  }, [tajweedEnabled]);

  useEffect(() => {
    writeStorage(STORAGE.fontSize, fontSize);
  }, [fontSize]);

  useEffect(() => {
    writeStorage(STORAGE.spacing, spacing);
  }, [spacing]);

  useEffect(() => {
    writeStorage(STORAGE.bookmarks, bookmarks);
  }, [bookmarks]);

  useEffect(() => {
    let cancelled = false;

    async function loadSurahs() {
      try {
        setLoading(true);
        setError("");

        const data = await fetchJson("/data/surahs.json");

        if (!Array.isArray(data)) {
          throw new Error("/data/surahs.json is not an array.");
        }

        if (!cancelled) {
          setSurahs(data);

          const requested = new URLSearchParams(window.location.search).get(
            "surah"
          );

          const requestedId = Number(requested);

          const initial =
            data.find((item) => item.id === requestedId) ||
            data.find((item) => item.id === lastRead?.surah) ||
            data[0];

          if (initial) {
            await loadSurah(initial.id);
          }
        }
      } catch (err) {
        if (!cancelled) {
          setError(err?.message || String(err));
          setLoading(false);
        }
      }
    }

    loadSurahs();

    return () => {
      cancelled = true;
    };
  }, []);

  async function loadSurah(id) {
    try {
      setLoadingSurah(true);
      setError("");

      const padded = String(id).padStart(3, "0");

      const data = await fetchJson(`/data/surahs/${padded}.json`);

      if (!data || !Array.isArray(data.verses)) {
        throw new Error(
          `/data/surahs/${padded}.json does not contain a verses array.`
        );
      }

      setCurrentSurah({
        ...data,
        metadata: surahs.find((s) => s.id === id) || null
      });

      writeStorage(STORAGE.lastRead, {
        surah: id,
        ayah: 1
      });

      setLastRead({
        surah: id,
        ayah: 1
      });

      const url = new URL(window.location.href);
      url.searchParams.set("surah", id);
      url.searchParams.delete("ayah");
      window.history.replaceState({}, "", url);

      setSidebarOpen(false);
    } catch (err) {
      setError(err?.message || String(err));
    } finally {
      setLoading(false);
      setLoadingSurah(false);
    }
  }

  function toggleBookmark(verseKey) {
    setBookmarks((current) =>
      current.includes(verseKey)
        ? current.filter((item) => item !== verseKey)
        : [...current, verseKey]
    );
  }

  function continueReading() {
    if (!lastRead?.surah) return;
    loadSurah(Number(lastRead.surah));
  }

  const filteredSurahs = useMemo(() => {
    const q = search.trim().toLowerCase();

    if (!q) return surahs;

    return surahs.filter((surah) => {
      return (
        String(surah.id).includes(q) ||
        String(surah.name || "").toLowerCase().includes(q) ||
        String(surah.transliteration || "").toLowerCase().includes(q)
      );
    });
  }, [surahs, search]);

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="brand">
          <div className="brand-mark">ﷲ</div>
          <div>
            <div className="brand-title">Qur&apos;an Reader</div>
            <div className="brand-subtitle">Tajweed Edition</div>
          </div>
        </div>

        <div className="top-actions">
          <button
            className={`tajweed-toggle ${tajweedEnabled ? "active" : ""}`}
            onClick={() => setTajweedEnabled((v) => !v)}
            title="Toggle Tajweed colors"
          >
            <span>✦</span>
            Tajweed
            <strong>{tajweedEnabled ? "ON" : "OFF"}</strong>
          </button>

          <button
            className="icon-button"
            onClick={() => setSettingsOpen(true)}
            aria-label="Settings"
          >
            ⚙
          </button>

          <button
            className="icon-button mobile-only"
            onClick={() => setSidebarOpen((v) => !v)}
            aria-label="Open surahs"
          >
            ☰
          </button>
        </div>
      </header>

      <div className="layout">
        <aside className={`sidebar ${sidebarOpen ? "open" : ""}`}>
          <div className="sidebar-head">
            <div>
              <div className="eyebrow">THE HOLY QUR&apos;AN</div>
              <h2>Surahs</h2>
            </div>
            <button
              className="sidebar-close mobile-only"
              onClick={() => setSidebarOpen(false)}
            >
              ×
            </button>
          </div>

          <div className="search-box">
            <span>⌕</span>
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search surah..."
            />
          </div>

          <div className="surah-list">
            {filteredSurahs.map((surah) => (
              <button
                key={surah.id}
                className={`surah-item ${
                  currentSurah?.surah === surah.id ? "selected" : ""
                }`}
                onClick={() => loadSurah(surah.id)}
              >
                <span className="surah-number">
                  {String(surah.id).padStart(3, "0")}
                </span>

                <span className="surah-name">
                  <strong>{surah.transliteration}</strong>
                  <small>
                    {surah.type} · {surah.total_verses} ayahs
                  </small>
                </span>

                <span className="surah-arabic">{surah.name}</span>
              </button>
            ))}
          </div>
        </aside>

        <main className="content">
          {loading && (
            <div className="loading-card">
              <div className="spinner" />
              <h2>Opening the Qur&apos;an...</h2>
              <p>Preparing your local Tajweed reader.</p>
            </div>
          )}

          {!loading && error && (
            <div className="error-card">
              <div className="error-symbol">!</div>
              <h1>Reader data could not be loaded</h1>
              <p>{error}</p>
              <button onClick={() => window.location.reload()}>
                Reload
              </button>
            </div>
          )}

          {!loading && !error && currentSurah && (
            <>
              <section className="hero">
                <div className="hero-glow" />

                <div className="hero-content">
                  <div className="hero-kicker">
                    {currentSurah.metadata?.type || "QURAN"}
                  </div>

                  <h1>{currentSurah.metadata?.transliteration}</h1>

                  <div className="hero-arabic">
                    {currentSurah.metadata?.name}
                  </div>

                  <div className="hero-meta">
                    <span>
                      Surah {currentSurah.surah}
                    </span>
                    <span>•</span>
                    <span>
                      {currentSurah.verses.length} Ayahs
                    </span>
                    <span>•</span>
                    <span>Hafs</span>
                  </div>
                </div>
              </section>

              <div className="reading-toolbar">
                <div>
                  <strong>Reading</strong>
                  {loadingSurah && <span className="toolbar-loading">Loading…</span>}
                </div>

                <div className="toolbar-actions">
                  <button
                    onClick={() =>
                      setFontSize((value) => Math.max(24, value - 2))
                    }
                  >
                    A−
                  </button>

                  <button
                    onClick={() => setFontSize(34)}
                  >
                    A
                  </button>

                  <button
                    onClick={() =>
                      setFontSize((value) => Math.min(52, value + 2))
                    }
                  >
                    A+
                  </button>

                  <button
                    onClick={() =>
                      setSpacing((value) =>
                        Number(Math.min(3.2, value + 0.2).toFixed(1))
                      )
                    }
                  >
                    Spacing +
                  </button>

                  <button
                    className={tajweedEnabled ? "active-tool" : ""}
                    onClick={() => setTajweedEnabled((v) => !v)}
                  >
                    ✦ Tajweed
                  </button>
                </div>
              </div>

              {tajweedEnabled && <Legend />}

              <section
                className="quran-reader"
                style={{
                  "--quran-font-size": `${fontSize}px`,
                  "--quran-line-height": spacing
                }}
              >
                {currentSurah.verses.map((verse) => {
                  const verseKey =
                    verse.verse_key ||
                    `${currentSurah.surah}:${verse.verse_number}`;

                  const bookmarked = bookmarks.includes(verseKey);

                  return (
                    <article
                      className={`ayah ${
                        bookmarked ? "bookmarked" : ""
                      }`}
                      key={verse.id || verseKey}
                      id={`ayah-${verseKey.replace(":", "-")}`}
                    >
                      <div className="ayah-top">
                        <span className="ayah-number" style={{
          fontSize: "0.48em",
          fontWeight: 700,
          marginInlineStart: "-1.55em",
          position: "relative",
          zIndex: 1
        }}>
                          {verseKey}
                        </span>

                        <button
                          className={`bookmark ${
                            bookmarked ? "saved" : ""
                          }`}
                          onClick={() => toggleBookmark(verseKey)}
                          title={
                            bookmarked
                              ? "Remove bookmark"
                              : "Bookmark ayah"
                          }
                        >
                          {bookmarked ? "★" : "☆"}
                        </button>
                      </div>

                      <div className="ayah-text">
                        <TajweedText
                          markup={verse.text_uthmani_tajweed}
                          enabled={tajweedEnabled}
                        /></div>
                    </article>
                  );
                })}
              </section>
            </>
          )}
        </main>
      </div>

      {settingsOpen && (
        <div
          className="drawer-backdrop"
          onClick={() => setSettingsOpen(false)}
        >
          <aside
            className="settings-drawer"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="drawer-head">
              <div>
                <div className="eyebrow">PERSONALIZE</div>
                <h2>Reading Settings</h2>
              </div>

              <button
                className="drawer-close"
                onClick={() => setSettingsOpen(false)}
              >
                ×
              </button>
            </div>

            <div className="setting-section">
              <label>Theme</label>

              <div className="theme-options">
                {[
                  ["emerald", "Emerald"],
                  ["midnight", "Midnight"],
                  ["ivory", "Ivory"]
                ].map(([value, label]) => (
                  <button
                    key={value}
                    className={theme === value ? "selected" : ""}
                    onClick={() => setTheme(value)}
                  >
                    <span className={`theme-dot ${value}`} />
                    {label}
                  </button>
                ))}
              </div>
            </div>

            <div className="setting-section">
              <label>Font size</label>

              <div className="slider-row">
                <span>A</span>

                <input
                  type="range"
                  min="24"
                  max="52"
                  step="2"
                  value={fontSize}
                  onChange={(e) => setFontSize(Number(e.target.value))}
                />

                <span className="large-a">A</span>
              </div>
            </div>

            <div className="setting-section">
              <label>Line spacing</label>

              <div className="slider-row">
                <span>−</span>

                <input
                  type="range"
                  min="1.8"
                  max="3.2"
                  step="0.1"
                  value={spacing}
                  onChange={(e) => setSpacing(Number(e.target.value))}
                />

                <span>+</span>
              </div>
            </div>

            <div className="setting-section">
              <label>Tajweed</label>

              <button
                className={`large-toggle ${
                  tajweedEnabled ? "enabled" : ""
                }`}
                onClick={() => setTajweedEnabled((v) => !v)}
              >
                <span>
                  {tajweedEnabled
                    ? "Tajweed colors enabled"
                    : "Tajweed colors disabled"}
                </span>

                <strong>
                  {tajweedEnabled ? "ON" : "OFF"}
                </strong>
              </button>
            </div>

            <div className="credits">
              <strong>Qur&apos;an Reader V3</strong>
              <p>
                Tajweed text sourced from Quran Foundation Content API.
              </p>
              <p>
                Credentials are used only during generation and are not
                included in this application.
              </p>
            </div>
          </aside>
        </div>
      )}
    </div>
  );
}

export default App;
