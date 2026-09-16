import React, { useEffect, useMemo, useState } from "react";
import {
    BookOpen,
    Bookmark,
    BookmarkCheck,
    ChevronLeft,
    ChevronRight,
    CircleHelp,
    Menu,
    Minus,
    Moon,
    Plus,
    Search,
    Settings,
    Sun,
    X
} from "lucide-react";

const STORAGE_BOOKMARKS = "quran-reader-bookmarks";
const STORAGE_THEME = "quran-reader-theme";
const STORAGE_FONT = "quran-reader-font-size";
const STORAGE_SPACING = "quran-reader-spacing";

function getInitialSurah() {
    const params = new URLSearchParams(window.location.search);
    const value = Number(params.get("surah"));

    if (Number.isInteger(value) && value >= 1) {
        return value;
    }

    return 1;
}

function App() {
    const [surahs, setSurahs] = useState([]);
    const [selectedSurah, setSelectedSurah] = useState(getInitialSurah());
    const [currentSurah, setCurrentSurah] = useState(null);
    const [search, setSearch] = useState("");
    const [loading, setLoading] = useState(true);
    const [loadingSurah, setLoadingSurah] = useState(false);
    const [sidebarOpen, setSidebarOpen] = useState(false);
    const [settingsOpen, setSettingsOpen] = useState(false);
    const [fontSize, setFontSize] = useState(
        Number(localStorage.getItem(STORAGE_FONT)) || 34
    );
    const [spacing, setSpacing] = useState(
        Number(localStorage.getItem(STORAGE_SPACING)) || 2
    );
    const [theme, setTheme] = useState(
        localStorage.getItem(STORAGE_THEME) || "dark"
    );
    const [bookmarks, setBookmarks] = useState(() => {
        try {
            return JSON.parse(localStorage.getItem(STORAGE_BOOKMARKS) || "[]");
        } catch {
            return [];
        }
    });

    useEffect(() => {
        document.documentElement.dataset.theme = theme;
        localStorage.setItem(STORAGE_THEME, theme);
    }, [theme]);

    useEffect(() => {
        localStorage.setItem(STORAGE_FONT, String(fontSize));
    }, [fontSize]);

    useEffect(() => {
        localStorage.setItem(STORAGE_SPACING, String(spacing));
    }, [spacing]);

    useEffect(() => {
        localStorage.setItem(STORAGE_BOOKMARKS, JSON.stringify(bookmarks));
    }, [bookmarks]);

    useEffect(() => {
        fetch("/data/surahs.json")
            .then(response => {
                if (!response.ok) {
                    throw new Error("Unable to load Surah metadata.");
                }

                return response.json();
            })
            .then(data => {
                setSurahs(data);
                setLoading(false);
            })
            .catch(error => {
                console.error(error);
                setLoading(false);
            });
    }, []);

    useEffect(() => {
        if (!surahs.length) {
            return;
        }

        const found = surahs.find(x => Number(x.id) === Number(selectedSurah));

        if (!found) {
            return;
        }

        setLoadingSurah(true);

        fetch(`/data/${found.file}`)
            .then(response => {
                if (!response.ok) {
                    throw new Error("Unable to load this Surah.");
                }

                return response.json();
            })
            .then(data => {
                setCurrentSurah(data);
                setLoadingSurah(false);

                const url = new URL(window.location.href);
                url.searchParams.set("surah", String(data.id));
                window.history.replaceState({}, "", url);
                window.scrollTo({ top: 0, behavior: "smooth" });
            })
            .catch(error => {
                console.error(error);
                setLoadingSurah(false);
            });
    }, [selectedSurah, surahs]);

    useEffect(() => {
        const handler = event => {
            if (event.key === "/" && event.target.tagName !== "INPUT") {
                event.preventDefault();
                document.getElementById("surah-search")?.focus();
            }

            if (event.key === "Escape") {
                setSidebarOpen(false);
                setSettingsOpen(false);
            }

            if (event.key === "ArrowRight" && currentSurah) {
                goNext();
            }

            if (event.key === "ArrowLeft" && currentSurah) {
                goPrevious();
            }
        };

        window.addEventListener("keydown", handler);

        return () => window.removeEventListener("keydown", handler);
    }, [currentSurah, selectedSurah, surahs]);

    const filteredSurahs = useMemo(() => {
        const term = search.trim().toLowerCase();

        if (!term) {
            return surahs;
        }

        return surahs.filter(surah =>
            String(surah.id).includes(term) ||
            String(surah.name || "").toLowerCase().includes(term) ||
            String(surah.transliteration || "").toLowerCase().includes(term) ||
            String(surah.type || "").toLowerCase().includes(term)
        );
    }, [surahs, search]);

    function selectSurah(id) {
        setSelectedSurah(Number(id));
        setSidebarOpen(false);
    }

    function goNext() {
        const next = Number(selectedSurah) + 1;

        if (next <= surahs.length) {
            selectSurah(next);
        }
    }

    function goPrevious() {
        const previous = Number(selectedSurah) - 1;

        if (previous >= 1) {
            selectSurah(previous);
        }
    }

    function toggleBookmark(verseId) {
        if (!currentSurah) {
            return;
        }

        const key = `${currentSurah.id}:${verseId}`;

        setBookmarks(previous => {
            if (previous.includes(key)) {
                return previous.filter(item => item !== key);
            }

            return [...previous, key];
        });
    }

    function isBookmarked(verseId) {
        if (!currentSurah) {
            return false;
        }

        return bookmarks.includes(`${currentSurah.id}:${verseId}`);
    }

    function resetSettings() {
        setFontSize(34);
        setSpacing(2);
    }

    return (
        <div className="app-shell">
            <div className="ambient ambient-one"></div>
            <div className="ambient ambient-two"></div>
            <div className="ambient ambient-three"></div>

            <header className="topbar">
                <button
                    className="icon-button mobile-menu"
                    onClick={() => setSidebarOpen(true)}
                    aria-label="Open Surah menu"
                >
                    <Menu size={22} />
                </button>

                <div className="brand">
                    <div className="brand-icon">
                        <BookOpen size={23} />
                    </div>

                    <div>
                        <div className="brand-title">Qur'an Reader</div>
                        <div className="brand-subtitle">Read • Reflect • Remember</div>
                    </div>
                </div>

                <div className="topbar-actions">
                    <button
                        className="icon-button"
                        onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
                        aria-label="Toggle theme"
                    >
                        {theme === "dark" ? <Sun size={20} /> : <Moon size={20} />}
                    </button>

                    <button
                        className="icon-button"
                        onClick={() => setSettingsOpen(true)}
                        aria-label="Open settings"
                    >
                        <Settings size={20} />
                    </button>
                </div>
            </header>

            <div className="layout">
                <aside className={`sidebar ${sidebarOpen ? "sidebar-open" : ""}`}>
                    <div className="sidebar-header">
                        <div>
                            <div className="sidebar-title">Surahs</div>
                            <div className="sidebar-count">
                                {surahs.length} chapters
                            </div>
                        </div>

                        <button
                            className="icon-button mobile-close"
                            onClick={() => setSidebarOpen(false)}
                            aria-label="Close Surah menu"
                        >
                            <X size={20} />
                        </button>
                    </div>

                    <div className="search-box">
                        <Search size={18} />
                        <input
                            id="surah-search"
                            value={search}
                            onChange={event => setSearch(event.target.value)}
                            placeholder="Search Surahs..."
                            aria-label="Search Surahs"
                        />
                        <span className="shortcut">/</span>
                    </div>

                    <div className="surah-list">
                        {loading && (
                            <div className="sidebar-loading">
                                Loading Surahs...
                            </div>
                        )}

                        {!loading && filteredSurahs.map(surah => (
                            <button
                                key={surah.id}
                                className={`surah-item ${
                                    Number(selectedSurah) === Number(surah.id)
                                        ? "active"
                                        : ""
                                }`}
                                onClick={() => selectSurah(surah.id)}
                            >
                                <span className="surah-number">
                                    {String(surah.id).padStart(3, "0")}
                                </span>

                                <span className="surah-info">
                                    <strong>{surah.transliteration}</strong>
                                    <small>
                                        {surah.type} • {surah.total_verses} verses
                                    </small>
                                </span>

                                <span className="surah-arabic">
                                    {surah.name}
                                </span>
                            </button>
                        ))}
                    </div>
                </aside>

                {sidebarOpen && (
                    <div
                        className="sidebar-overlay"
                        onClick={() => setSidebarOpen(false)}
                    ></div>
                )}

                <main className="main-content">
                    {loadingSurah && (
                        <div className="loading-card">
                            <div className="spinner"></div>
                            <div>Loading Surah...</div>
                        </div>
                    )}

                    {!loadingSurah && currentSurah && (
                        <>
                            <section className="surah-hero">
                                <div className="hero-glow"></div>

                                <div className="surah-kicker">
                                    SURAH {currentSurah.id}
                                </div>

                                <h1>{currentSurah.transliteration}</h1>

                                <div className="hero-arabic">
                                    {currentSurah.name}
                                </div>

                                <div className="hero-meta">
                                    <span>{currentSurah.type}</span>
                                    <span>{currentSurah.total_verses} verses</span>
                                </div>
                            </section>

                            <section className="reader-toolbar">
                                <div className="toolbar-group">
                                    <button
                                        className="toolbar-button"
                                        onClick={() =>
                                            setFontSize(value => Math.max(22, value - 2))
                                        }
                                        title="Decrease Arabic text size"
                                    >
                                        <Minus size={17} />
                                    </button>

                                    <span className="toolbar-value">
                                        {fontSize}px
                                    </span>

                                    <button
                                        className="toolbar-button"
                                        onClick={() =>
                                            setFontSize(value => Math.min(58, value + 2))
                                        }
                                        title="Increase Arabic text size"
                                    >
                                        <Plus size={17} />
                                    </button>
                                </div>

                                <div className="toolbar-spacer"></div>

                                <button
                                    className="toolbar-button"
                                    onClick={() => setSettingsOpen(true)}
                                >
                                    <Settings size={17} />
                                    <span>Reading settings</span>
                                </button>
                            </section>

                            <section
                                className="verses"
                                style={{
                                    "--arabic-size": `${fontSize}px`,
                                    "--arabic-spacing": spacing
                                }}
                            >
                                {currentSurah.verses.map(verse => (
                                    <article
                                        className={`verse ${
                                            isBookmarked(verse.id)
                                                ? "verse-bookmarked"
                                                : ""
                                        }`}
                                        key={verse.id}
                                        id={`verse-${verse.id}`}
                                    >
                                        <div className="verse-number">
                                            {verse.id}
                                        </div>

                                        <div className="verse-content">
                                            <p className="arabic" dir="rtl">
                                                {verse.text}
                                            </p>
                                        </div>

                                        <button
                                            className={`bookmark-button ${
                                                isBookmarked(verse.id)
                                                    ? "bookmarked"
                                                    : ""
                                            }`}
                                            onClick={() =>
                                                toggleBookmark(verse.id)
                                            }
                                            aria-label={
                                                isBookmarked(verse.id)
                                                    ? "Remove bookmark"
                                                    : "Bookmark verse"
                                            }
                                        >
                                            {isBookmarked(verse.id) ? (
                                                <BookmarkCheck size={19} />
                                            ) : (
                                                <Bookmark size={19} />
                                            )}
                                        </button>
                                    </article>
                                ))}
                            </section>

                            <nav className="surah-navigation">
                                <button
                                    className="nav-card"
                                    disabled={selectedSurah <= 1}
                                    onClick={goPrevious}
                                >
                                    <ChevronLeft size={22} />
                                    <div>
                                        <small>Previous</small>
                                        <strong>
                                            {selectedSurah > 1
                                                ? surahs[selectedSurah - 2]?.transliteration
                                                : "Beginning"}
                                        </strong>
                                    </div>
                                </button>

                                <button
                                    className="nav-card nav-next"
                                    disabled={selectedSurah >= surahs.length}
                                    onClick={goNext}
                                >
                                    <div>
                                        <small>Next</small>
                                        <strong>
                                            {selectedSurah < surahs.length
                                                ? surahs[selectedSurah]?.transliteration
                                                : "End"}
                                        </strong>
                                    </div>
                                    <ChevronRight size={22} />
                                </button>
                            </nav>
                        </>
                    )}

                    {!loading && !loadingSurah && !currentSurah && (
                        <div className="error-card">
                            <CircleHelp size={34} />
                            <h2>Unable to load the Qur'an</h2>
                            <p>
                                Please check that the generated data files exist.
                            </p>
                        </div>
                    )}
                </main>
            </div>

            {settingsOpen && (
                <div
                    className="settings-overlay"
                    onClick={() => setSettingsOpen(false)}
                >
                    <section
                        className="settings-panel"
                        onClick={event => event.stopPropagation()}
                    >
                        <div className="settings-header">
                            <div>
                                <h2>Reading Settings</h2>
                                <p>Customize your reading experience.</p>
                            </div>

                            <button
                                className="icon-button"
                                onClick={() => setSettingsOpen(false)}
                            >
                                <X size={20} />
                            </button>
                        </div>

                        <label className="setting-row">
                            <div>
                                <strong>Arabic text size</strong>
                                <span>{fontSize}px</span>
                            </div>

                            <input
                                type="range"
                                min="22"
                                max="58"
                                step="1"
                                value={fontSize}
                                onChange={event =>
                                    setFontSize(Number(event.target.value))
                                }
                            />
                        </label>

                        <label className="setting-row">
                            <div>
                                <strong>Line spacing</strong>
                                <span>{spacing.toFixed(1)}</span>
                            </div>

                            <input
                                type="range"
                                min="1.2"
                                max="3.2"
                                step="0.1"
                                value={spacing}
                                onChange={event =>
                                    setSpacing(Number(event.target.value))
                                }
                            />
                        </label>

                        <div className="settings-actions">
                            <button
                                className="secondary-button"
                                onClick={resetSettings}
                            >
                                Reset
                            </button>

                            <button
                                className="primary-button"
                                onClick={() => setSettingsOpen(false)}
                            >
                                Done
                            </button>
                        </div>

                        <div className="keyboard-help">
                            <div><kbd>/</kbd> Search Surahs</div>
                            <div><kbd>←</kbd><kbd>→</kbd> Navigate Surahs</div>
                            <div><kbd>Esc</kbd> Close panels</div>
                        </div>
                    </section>
                </div>
            )}
        </div>
    );
}

export default App;