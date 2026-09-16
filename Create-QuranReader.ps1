#requires -Version 5.1

<#
============================================================
 QUR'AN READER V2
 React + Vite Static Website Generator
============================================================

 Creates:

    QuranReader/
    ├── public/
    │   └── data/
    │       ├── surahs.json
    │       └── surahs/
    │           ├── 001.json
    │           ├── 002.json
    │           └── ...
    │           └── 114.json
    │
    ├── src/
    │   ├── main.jsx
    │   ├── App.jsx
    │   └── styles.css
    │
    ├── index.html
    ├── package.json
    ├── vite.config.js
    ├── staticwebapp.config.json
    └── README.md

 Features:

    • Premium Islamic glassmorphism UI
    • Dark / Light / Midnight themes
    • 114 individually lazy-loaded Surahs
    • Automatic next/previous Surah prefetch
    • Responsive mobile design
    • Search Surahs
    • Revelation type filters
    • Arabic reading controls
    • Font size control
    • Line-height control
    • Compact reading mode
    • Focus mode
    • Verse bookmarks
    • Last-read position
    • Verse copy
    • Native share
    • Keyboard shortcuts
    • URL ?surah=N navigation
    • Browser localStorage persistence
    • Reduced-motion accessibility
    • Azure Static Web Apps compatible
    • No backend required
    • No database required

============================================================
#>

param(
    [string]$SourceJson = ".\quran.json",
    [string]$ProjectPath = ".\QuranReader",
    [switch]$SkipNpmInstall
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "       QUR'AN READER V2 - WEBSITE GENERATOR" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# Resolve paths
# ------------------------------------------------------------

$SourceJson = [System.IO.Path]::GetFullPath($SourceJson)
$ProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)

Write-Host "Source JSON:" -ForegroundColor Yellow
Write-Host "  $SourceJson"

Write-Host "Project:" -ForegroundColor Yellow
Write-Host "  $ProjectPath"

Write-Host ""

# ------------------------------------------------------------
# Check source JSON
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $SourceJson)) {
    Write-Host ""
    Write-Host "ERROR: Source JSON was not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Expected:" -ForegroundColor Yellow
    Write-Host "  $SourceJson"
    Write-Host ""
    Write-Host "Place your Qur'an JSON file there or run the script with:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host '  .\Create-QuranReader-V2.ps1 -SourceJson ".\yourfile.json"'
    Write-Host ""
    exit 1
}

# ------------------------------------------------------------
# Check Node.js / npm
# ------------------------------------------------------------

try {
    $nodeVersion = node --version 2>$null
}
catch {
    $nodeVersion = $null
}

try {
    $npmVersion = npm --version 2>$null
}
catch {
    $npmVersion = $null
}

if (-not $nodeVersion) {
    Write-Host "ERROR: Node.js is not installed or not available in PATH." -ForegroundColor Red
    Write-Host ""
    Write-Host "Install Node.js and then run this script again." -ForegroundColor Yellow
    exit 1
}

if (-not $npmVersion) {
    Write-Host "ERROR: npm is not installed or not available in PATH." -ForegroundColor Red
    exit 1
}

Write-Host "Node.js: $nodeVersion" -ForegroundColor Green
Write-Host "npm:     $npmVersion" -ForegroundColor Green
Write-Host ""

# ------------------------------------------------------------
# Read Qur'an JSON
# ------------------------------------------------------------

Write-Host "Reading Qur'an JSON..." -ForegroundColor Cyan

try {
    $rawJson = Get-Content -LiteralPath $SourceJson -Raw -Encoding UTF8
    $quran = $rawJson | ConvertFrom-Json
}
catch {
    Write-Host ""
    Write-Host "ERROR: Could not parse the JSON file." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

if ($null -eq $quran) {
    Write-Host "ERROR: JSON contained no data." -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# Normalize top-level array
# ------------------------------------------------------------

if ($quran.PSObject.Properties.Name -contains "data") {
    $surahs = @($quran.data)
}
elseif ($quran.PSObject.Properties.Name -contains "surahs") {
    $surahs = @($quran.surahs)
}
else {
    $surahs = @($quran)
}

if ($surahs.Count -eq 0) {
    Write-Host "ERROR: No Surahs were found." -ForegroundColor Red
    exit 1
}

Write-Host "Found $($surahs.Count) Surah records." -ForegroundColor Green
Write-Host ""

# ------------------------------------------------------------
# Create directories
# ------------------------------------------------------------

$publicPath = Join-Path $ProjectPath "public"
$dataPath = Join-Path $publicPath "data"
$surahsPath = Join-Path $dataPath "surahs"
$srcPath = Join-Path $ProjectPath "src"

New-Item -ItemType Directory -Force -Path $ProjectPath | Out-Null
New-Item -ItemType Directory -Force -Path $publicPath | Out-Null
New-Item -ItemType Directory -Force -Path $dataPath | Out-Null
New-Item -ItemType Directory -Force -Path $surahsPath | Out-Null
New-Item -ItemType Directory -Force -Path $srcPath | Out-Null

# ------------------------------------------------------------
# Clean old generated Surah files
# ------------------------------------------------------------

Get-ChildItem -LiteralPath $surahsPath -Filter "*.json" -File -ErrorAction SilentlyContinue |
    Remove-Item -Force

# ------------------------------------------------------------
# Build lightweight Surah metadata
# ------------------------------------------------------------

$metadata = New-Object System.Collections.Generic.List[object]

foreach ($surah in $surahs) {

    $id = 0

    if ($null -ne $surah.id) {
        $id = [int]$surah.id
    }

    if ($id -lt 1) {
        continue
    }

    $name = [string]$surah.name
    $transliteration = [string]$surah.transliteration
    $type = [string]$surah.type
    $totalVerses = 0

    if ($null -ne $surah.total_verses) {
        $totalVerses = [int]$surah.total_verses
    }
    elseif ($null -ne $surah.verses) {
        $totalVerses = @($surah.verses).Count
    }

    $metadata.Add(
        [ordered]@{
            id             = $id
            name           = $name
            transliteration = $transliteration
            type           = $type
            total_verses   = $totalVerses
        }
    )

    $surahFileName = "{0:D3}.json" -f $id
    $surahFilePath = Join-Path $surahsPath $surahFileName

    $surahJson = $surah | ConvertTo-Json -Depth 20 -Compress
    [System.IO.File]::WriteAllText(
        $surahFilePath,
        $surahJson,
        [System.Text.UTF8Encoding]::new($false)
    )

    Write-Host ("  Created Surah {0:D3} - {1}" -f $id, $transliteration) -ForegroundColor DarkGray
}

# ------------------------------------------------------------
# Sort metadata
# ------------------------------------------------------------

$metadata = @($metadata | Sort-Object id)

$metadataJson = $metadata | ConvertTo-Json -Depth 10

$metadataPath = Join-Path $dataPath "surahs.json"

[System.IO.File]::WriteAllText(
    $metadataPath,
    $metadataJson,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host ""
Write-Host "Created lightweight Surah metadata." -ForegroundColor Green
Write-Host ""

# ------------------------------------------------------------
# package.json
# ------------------------------------------------------------

$packageJson = @'
{
  "name": "quran-reader",
  "private": true,
  "version": "2.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "lucide-react": "^0.468.0",
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.3.4",
    "vite": "^6.0.5"
  }
}
'@

Set-Content -LiteralPath (Join-Path $ProjectPath "package.json") `
    -Value $packageJson `
    -Encoding UTF8

# ------------------------------------------------------------
# vite.config.js
# ------------------------------------------------------------

$viteConfig = @'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  base: "/",
  build: {
    target: "es2020",
    sourcemap: false,
    cssMinify: true,
    rollupOptions: {
      output: {
        manualChunks: {
          react: ["react", "react-dom"],
          icons: ["lucide-react"]
        }
      }
    }
  }
});
'@

Set-Content -LiteralPath (Join-Path $ProjectPath "vite.config.js") `
    -Value $viteConfig `
    -Encoding UTF8

# ------------------------------------------------------------
# staticwebapp.config.json
# ------------------------------------------------------------

$staticWebApp = @'
{
  "navigationFallback": {
    "rewrite": "/index.html",
    "exclude": [
      "/data/*",
      "/assets/*",
      "/*.css",
      "/*.js",
      "/*.png",
      "/*.jpg",
      "/*.jpeg",
      "/*.svg",
      "/*.ico",
      "/*.webp",
      "/*.woff",
      "/*.woff2"
    ]
  },
  "globalHeaders": {
    "X-Content-Type-Options": "nosniff",
    "Referrer-Policy": "strict-origin-when-cross-origin"
  },
  "mimeTypes": {
    ".json": "application/json"
  }
}
'@

Set-Content -LiteralPath (Join-Path $ProjectPath "staticwebapp.config.json") `
    -Value $staticWebApp `
    -Encoding UTF8

# ------------------------------------------------------------
# index.html
# ------------------------------------------------------------

$indexHtml = @'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />

    <meta
      name="viewport"
      content="width=device-width, initial-scale=1.0"
    />

    <meta
      name="theme-color"
      content="#08111f"
    />

    <meta
      name="description"
      content="A beautiful, accessible and lightweight Qur'an reader."
    />

    <title>Qur'an Reader</title>

    <link rel="preconnect" href="https://fonts.googleapis.com">

    <link
      href="https://fonts.googleapis.com/css2?family=Amiri:wght@400;700&family=Inter:wght@400;500;600;700;800&display=swap"
      rel="stylesheet"
    />
  </head>

  <body>
    <div id="root"></div>

    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
'@

Set-Content -LiteralPath (Join-Path $ProjectPath "index.html") `
    -Value $indexHtml `
    -Encoding UTF8

# ------------------------------------------------------------
# main.jsx
# ------------------------------------------------------------

$mainJsx = @'
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./styles.css";

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
'@

Set-Content -LiteralPath (Join-Path $srcPath "main.jsx") `
    -Value $mainJsx `
    -Encoding UTF8

# ------------------------------------------------------------
# App.jsx
# ------------------------------------------------------------

$appJsx = @'
import React, {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState
} from "react";

import {
  BookOpen,
  Bookmark,
  BookmarkCheck,
  ChevronLeft,
  ChevronRight,
  CircleHelp,
  Copy,
  Eye,
  EyeOff,
  Focus,
  Hash,
  Heart,
  Home,
  Languages,
  Menu,
  Moon,
  PanelLeft,
  Search,
  Settings,
  Share2,
  Sparkles,
  Sun,
  X,
  Zap
} from "lucide-react";

const METADATA_URL = "/data/surahs.json";

const STORAGE_KEYS = {
  theme: "quran-reader-theme",
  fontSize: "quran-reader-font-size",
  lineHeight: "quran-reader-line-height",
  compact: "quran-reader-compact",
  bookmarks: "quran-reader-bookmarks",
  lastSurah: "quran-reader-last-surah",
  lastVerse: "quran-reader-last-verse"
};

const THEMES = [
  {
    id: "midnight",
    label: "Midnight",
    icon: Moon
  },
  {
    id: "light",
    label: "Pearl",
    icon: Sun
  },
  {
    id: "dark",
    label: "Obsidian",
    icon: Sparkles
  }
];

function readStorage(key, fallback) {
  try {
    const value = localStorage.getItem(key);

    if (value === null) {
      return fallback;
    }

    return JSON.parse(value);
  } catch {
    return fallback;
  }
}

function writeStorage(key, value) {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch {
    // Ignore storage failures.
  }
}

function formatNumber(number) {
  return new Intl.NumberFormat("en-US").format(number);
}

function getSurahFromUrl() {
  const params = new URLSearchParams(window.location.search);
  const value = Number(params.get("surah"));

  if (Number.isInteger(value) && value >= 1 && value <= 114) {
    return value;
  }

  return null;
}

function updateUrl(surahId) {
  const url = new URL(window.location.href);

  url.searchParams.set("surah", String(surahId));

  window.history.replaceState(
    {},
    "",
    url.pathname + "?" + url.searchParams.toString()
  );
}

function App() {
  const initialSurah =
    getSurahFromUrl() ||
    readStorage(STORAGE_KEYS.lastSurah, 1);

  const [surahs, setSurahs] = useState([]);
  const [currentSurahId, setCurrentSurahId] = useState(
    Math.min(Math.max(Number(initialSurah) || 1, 1), 114)
  );

  const [loadedSurahs, setLoadedSurahs] = useState({});
  const [loadingSurah, setLoadingSurah] = useState(false);
  const [error, setError] = useState("");

  const [search, setSearch] = useState("");
  const [revelationFilter, setRevelationFilter] = useState("all");

  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [settingsOpen, setSettingsOpen] = useState(false);

  const [theme, setTheme] = useState(
    readStorage(STORAGE_KEYS.theme, "midnight")
  );

  const [fontSize, setFontSize] = useState(
    readStorage(STORAGE_KEYS.fontSize, 34)
  );

  const [lineHeight, setLineHeight] = useState(
    readStorage(STORAGE_KEYS.lineHeight, 2.15)
  );

  const [compact, setCompact] = useState(
    readStorage(STORAGE_KEYS.compact, false)
  );

  const [focusMode, setFocusMode] = useState(false);

  const [bookmarks, setBookmarks] = useState(
    readStorage(STORAGE_KEYS.bookmarks, [])
  );

  const [lastVerse, setLastVerse] = useState(
    readStorage(STORAGE_KEYS.lastVerse, {})
  );

  const contentRef = useRef(null);

  // ----------------------------------------------------------
  // Load lightweight metadata
  // ----------------------------------------------------------

  useEffect(() => {
    let cancelled = false;

    async function loadMetadata() {
      try {
        const response = await fetch(METADATA_URL, {
          cache: "force-cache"
        });

        if (!response.ok) {
          throw new Error("Unable to load Surah metadata.");
        }

        const data = await response.json();

        if (!cancelled) {
          setSurahs(Array.isArray(data) ? data : []);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err.message || "Unable to load Qur'an data.");
        }
      }
    }

    loadMetadata();

    return () => {
      cancelled = true;
    };
  }, []);

  // ----------------------------------------------------------
  // Theme / preferences
  // ----------------------------------------------------------

  useEffect(() => {
    document.documentElement.dataset.theme = theme;

    writeStorage(STORAGE_KEYS.theme, theme);
  }, [theme]);

  useEffect(() => {
    writeStorage(STORAGE_KEYS.fontSize, fontSize);
  }, [fontSize]);

  useEffect(() => {
    writeStorage(STORAGE_KEYS.lineHeight, lineHeight);
  }, [lineHeight]);

  useEffect(() => {
    writeStorage(STORAGE_KEYS.compact, compact);
  }, [compact]);

  useEffect(() => {
    writeStorage(STORAGE_KEYS.bookmarks, bookmarks);
  }, [bookmarks]);

  useEffect(() => {
    writeStorage(STORAGE_KEYS.lastVerse, lastVerse);
  }, [lastVerse]);

  // ----------------------------------------------------------
  // Load individual Surah
  // ----------------------------------------------------------

  const loadSurah = useCallback(
    async (id, silent = false) => {
      if (!id || loadedSurahs[id]) {
        return loadedSurahs[id] || null;
      }

      if (!silent) {
        setLoadingSurah(true);
        setError("");
      }

      try {
        const file = String(id).padStart(3, "0");

        const response = await fetch(
          `/data/surahs/${file}.json`,
          {
            cache: "force-cache"
          }
        );

        if (!response.ok) {
          throw new Error(`Unable to load Surah ${id}.`);
        }

        const data = await response.json();

        setLoadedSurahs((previous) => ({
          ...previous,
          [id]: data
        }));

        return data;
      } catch (err) {
        if (!silent) {
          setError(
            err.message ||
              "Unable to load this Surah."
          );
        }

        return null;
      } finally {
        if (!silent) {
          setLoadingSurah(false);
        }
      }
    },
    [loadedSurahs]
  );

  // ----------------------------------------------------------
  // Current Surah
  // ----------------------------------------------------------

  useEffect(() => {
    if (surahs.length > 0) {
      loadSurah(currentSurahId);
    }
  }, [currentSurahId, surahs.length, loadSurah]);

  useEffect(() => {
    updateUrl(currentSurahId);

    writeStorage(
      STORAGE_KEYS.lastSurah,
      currentSurahId
    );
  }, [currentSurahId]);

  // ----------------------------------------------------------
  // Intelligent prefetch
  // ----------------------------------------------------------

  useEffect(() => {
    if (surahs.length === 0) {
      return;
    }

    const nextId = currentSurahId + 1;
    const previousId = currentSurahId - 1;

    const timer = window.setTimeout(() => {
      if (nextId <= 114) {
        loadSurah(nextId, true);
      }

      if (previousId >= 1) {
        loadSurah(previousId, true);
      }
    }, 1200);

    return () => {
      window.clearTimeout(timer);
    };
  }, [currentSurahId, surahs.length, loadSurah]);

  // ----------------------------------------------------------
  // Current data
  // ----------------------------------------------------------

  const currentSurah = loadedSurahs[currentSurahId];

  const currentMetadata = useMemo(() => {
    return (
      surahs.find(
        (surah) => Number(surah.id) === currentSurahId
      ) || null
    );
  }, [surahs, currentSurahId]);

  // ----------------------------------------------------------
  // Search
  // ----------------------------------------------------------

  const filteredSurahs = useMemo(() => {
    const query = search.trim().toLowerCase();

    return surahs.filter((surah) => {
      const matchesType =
        revelationFilter === "all" ||
        String(surah.type).toLowerCase() ===
          revelationFilter;

      if (!matchesType) {
        return false;
      }

      if (!query) {
        return true;
      }

      return (
        String(surah.id).includes(query) ||
        String(surah.name || "")
          .toLowerCase()
          .includes(query) ||
        String(surah.transliteration || "")
          .toLowerCase()
          .includes(query)
      );
    });
  }, [surahs, search, revelationFilter]);

  // ----------------------------------------------------------
  // Navigate
  // ----------------------------------------------------------

  const selectSurah = useCallback((id) => {
    setCurrentSurahId(id);
    setSidebarOpen(false);

    window.setTimeout(() => {
      window.scrollTo({
        top: 0,
        behavior: "smooth"
      });
    }, 20);
  }, []);

  const goPrevious = useCallback(() => {
    if (currentSurahId > 1) {
      selectSurah(currentSurahId - 1);
    }
  }, [currentSurahId, selectSurah]);

  const goNext = useCallback(() => {
    if (currentSurahId < 114) {
      selectSurah(currentSurahId + 1);
    }
  }, [currentSurahId, selectSurah]);

  // ----------------------------------------------------------
  // Bookmark helpers
  // ----------------------------------------------------------

  function bookmarkKey(surahId, verseId) {
    return `${surahId}:${verseId}`;
  }

  function isBookmarked(surahId, verseId) {
    return bookmarks.some(
      (item) =>
        item.key === bookmarkKey(surahId, verseId)
    );
  }

  function toggleBookmark(surah, verse) {
    const key = bookmarkKey(
      surah.id,
      verse.id
    );

    setBookmarks((previous) => {
      const exists = previous.some(
        (item) => item.key === key
      );

      if (exists) {
        return previous.filter(
          (item) => item.key !== key
        );
      }

      return [
        ...previous,
        {
          key,
          surahId: surah.id,
          verseId: verse.id,
          surahName: surah.name,
          surahTransliteration:
            surah.transliteration,
          text: verse.text,
          createdAt: Date.now()
        }
      ];
    });
  }

  // ----------------------------------------------------------
  // Verse actions
  // ----------------------------------------------------------

  async function copyVerse(surah, verse) {
    const text =
      `${surah.transliteration} ${surah.id}:${verse.id}\n\n` +
      verse.text;

    try {
      await navigator.clipboard.writeText(text);
    } catch {
      // Ignore clipboard failures.
    }
  }

  async function shareVerse(surah, verse) {
    const text =
      `${surah.transliteration} ${surah.id}:${verse.id}\n\n` +
      verse.text;

    if (navigator.share) {
      try {
        await navigator.share({
          title: "Qur'an",
          text
        });
      } catch {
        // User cancelled share.
      }
    } else {
      await copyVerse(surah, verse);
    }
  }

  function markVerseRead(surahId, verseId) {
    setLastVerse((previous) => ({
      ...previous,
      [surahId]: verseId
    }));
  }

  // ----------------------------------------------------------
  // Keyboard shortcuts
  // ----------------------------------------------------------

  useEffect(() => {
    function handleKeyDown(event) {
      if (
        event.target instanceof HTMLInputElement ||
        event.target instanceof HTMLTextAreaElement
      ) {
        return;
      }

      if (event.key === "ArrowLeft") {
        goPrevious();
      }

      if (event.key === "ArrowRight") {
        goNext();
      }

      if (event.key.toLowerCase() === "f") {
        setFocusMode((value) => !value);
      }

      if (event.key.toLowerCase() === "b") {
        setSidebarOpen((value) => !value);
      }

      if (event.key === "Escape") {
        setSidebarOpen(false);
        setSettingsOpen(false);
      }
    }

    window.addEventListener(
      "keydown",
      handleKeyDown
    );

    return () =>
      window.removeEventListener(
        "keydown",
        handleKeyDown
      );
  }, [goPrevious, goNext]);

  // ----------------------------------------------------------
  // Reset reading position
  // ----------------------------------------------------------

  useEffect(() => {
    if (!currentSurah) {
      return;
    }

    const savedVerse =
      Number(lastVerse[currentSurahId]);

    if (!savedVerse) {
      return;
    }

    const timer = window.setTimeout(() => {
      const element =
        document.getElementById(
          `ayah-${currentSurahId}-${savedVerse}`
        );

      if (element) {
        element.scrollIntoView({
          behavior: "smooth",
          block: "center"
        });
      }
    }, 400);

    return () => {
      window.clearTimeout(timer);
    };
  }, [currentSurahId, currentSurah]);

  // ----------------------------------------------------------
  // Render
  // ----------------------------------------------------------

  return (
    <div
      className={
        `app-shell ` +
        `${focusMode ? "focus-active" : ""}`
      }
    >
      <BackgroundEffects />

      {!focusMode && (
        <Header
          onMenu={() =>
            setSidebarOpen(true)
          }
          onSettings={() =>
            setSettingsOpen(true)
          }
          onFocus={() =>
            setFocusMode(true)
          }
        />
      )}

      <div className="app-layout">
        {!focusMode && (
          <Sidebar
            open={sidebarOpen}
            onClose={() =>
              setSidebarOpen(false)
            }
            surahs={filteredSurahs}
            search={search}
            setSearch={setSearch}
            revelationFilter={revelationFilter}
            setRevelationFilter={
              setRevelationFilter
            }
            currentSurahId={currentSurahId}
            onSelect={selectSurah}
            bookmarks={bookmarks}
          />
        )}

        <main
          className="reader-main"
          ref={contentRef}
        >
          <ReaderTop
            currentSurah={currentMetadata}
            currentData={currentSurah}
            loading={loadingSurah}
            onPrevious={goPrevious}
            onNext={goNext}
            canPrevious={
              currentSurahId > 1
            }
            canNext={
              currentSurahId < 114
            }
            focusMode={focusMode}
            setFocusMode={setFocusMode}
          />

          {error && (
            <div className="error-banner">
              <CircleHelp size={18} />
              <span>{error}</span>
              <button
                className="icon-button"
                onClick={() =>
                  loadSurah(currentSurahId)
                }
              >
                Retry
              </button>
            </div>
          )}

          <Reader
            surah={currentSurah}
            metadata={currentMetadata}
            fontSize={fontSize}
            lineHeight={lineHeight}
            compact={compact}
            isBookmarked={isBookmarked}
            toggleBookmark={toggleBookmark}
            copyVerse={copyVerse}
            shareVerse={shareVerse}
            markVerseRead={markVerseRead}
            lastVerse={lastVerse[currentSurahId]}
            loading={loadingSurah}
          />

          <ReaderBottom
            currentSurahId={currentSurahId}
            onPrevious={goPrevious}
            onNext={goNext}
            canPrevious={
              currentSurahId > 1
            }
            canNext={
              currentSurahId < 114
            }
          />
        </main>
      </div>

      {!focusMode && (
        <MobileBottomBar
          onMenu={() =>
            setSidebarOpen(true)
          }
          onSettings={() =>
            setSettingsOpen(true)
          }
          onHome={() =>
            window.scrollTo({
              top: 0,
              behavior: "smooth"
            })
          }
          onFocus={() =>
            setFocusMode(true)
          }
        />
      )}

      <SettingsPanel
        open={settingsOpen}
        onClose={() =>
          setSettingsOpen(false)
        }
        theme={theme}
        setTheme={setTheme}
        fontSize={fontSize}
        setFontSize={setFontSize}
        lineHeight={lineHeight}
        setLineHeight={setLineHeight}
        compact={compact}
        setCompact={setCompact}
      />

      {focusMode && (
        <button
          className="focus-exit"
          onClick={() =>
            setFocusMode(false)
          }
          aria-label="Exit focus mode"
          title="Exit focus mode"
        >
          <EyeOff size={19} />
          <span>Exit Focus</span>
        </button>
      )}
    </div>
  );
}

// ============================================================
// Background
// ============================================================

function BackgroundEffects() {
  return (
    <div className="background-effects" aria-hidden="true">
      <div className="orb orb-one" />
      <div className="orb orb-two" />
      <div className="orb orb-three" />

      <div className="star-field">
        {Array.from(
          { length: 28 },
          (_, index) => (
            <span
              key={index}
              style={{
                "--i": index
              }}
            />
          )
        )}
      </div>

      <div className="geometry geometry-one" />
      <div className="geometry geometry-two" />
    </div>
  );
}

// ============================================================
// Header
// ============================================================

function Header({
  onMenu,
  onSettings,
  onFocus
}) {
  return (
    <header className="top-header">
      <div className="header-inner">

        <button
          className="mobile-menu-button"
          onClick={onMenu}
          aria-label="Open Surah menu"
        >
          <Menu size={22} />
        </button>

        <div className="brand">
          <div className="brand-icon">
            <BookOpen size={23} />
          </div>

          <div>
            <div className="brand-title">
              Qur'an Reader
            </div>

            <div className="brand-subtitle">
              Read • Reflect • Remember
            </div>
          </div>
        </div>

        <div className="header-actions">

          <button
            className="header-button"
            onClick={onFocus}
            title="Focus mode"
          >
            <Focus size={18} />
            <span>Focus</span>
          </button>

          <button
            className="header-button"
            onClick={onSettings}
            title="Reading settings"
          >
            <Settings size={18} />
            <span>Settings</span>
          </button>

        </div>
      </div>
    </header>
  );
}

// ============================================================
// Sidebar
// ============================================================

function Sidebar({
  open,
  onClose,
  surahs,
  search,
  setSearch,
  revelationFilter,
  setRevelationFilter,
  currentSurahId,
  onSelect,
  bookmarks
}) {
  return (
    <>
      {open && (
        <div
          className="sidebar-backdrop"
          onClick={onClose}
        />
      )}

      <aside
        className={
          `sidebar ` +
          `${open ? "sidebar-open" : ""}`
        }
      >
        <div className="sidebar-header">

          <div>
            <div className="sidebar-title">
              Surahs
            </div>

            <div className="sidebar-count">
              114 chapters
            </div>
          </div>

          <button
            className="icon-button mobile-close"
            onClick={onClose}
            aria-label="Close menu"
          >
            <X size={20} />
          </button>
        </div>

        <div className="search-box">
          <Search size={17} />

          <input
            value={search}
            onChange={(event) =>
              setSearch(event.target.value)
            }
            placeholder="Search Surahs..."
            aria-label="Search Surahs"
          />

          {search && (
            <button
              className="search-clear"
              onClick={() =>
                setSearch("")
              }
            >
              <X size={15} />
            </button>
          )}
        </div>

        <div className="filter-row">

          <button
            className={
              revelationFilter === "all"
                ? "filter-active"
                : ""
            }
            onClick={() =>
              setRevelationFilter("all")
            }
          >
            All
          </button>

          <button
            className={
              revelationFilter === "meccan"
                ? "filter-active"
                : ""
            }
            onClick={() =>
              setRevelationFilter("meccan")
            }
          >
            Meccan
          </button>

          <button
            className={
              revelationFilter === "medinan"
                ? "filter-active"
                : ""
            }
            onClick={() =>
              setRevelationFilter("medinan")
            }
          >
            Medinan
          </button>

        </div>

        <div className="bookmark-summary">
          <BookmarkCheck size={16} />

          <span>
            {bookmarks.length} bookmarked
          </span>
        </div>

        <div className="surah-list">

          {surahs.map((surah) => {
            const active =
              Number(surah.id) ===
              currentSurahId;

            return (
              <button
                key={surah.id}
                className={
                  `surah-item ` +
                  `${active ? "surah-active" : ""}`
                }
                onClick={() =>
                  onSelect(Number(surah.id))
                }
              >

                <div className="surah-number">
                  {surah.id}
                </div>

                <div className="surah-info">

                  <div className="surah-translit">
                    {surah.transliteration}
                  </div>

                  <div className="surah-meta">
                    {surah.type} •{" "}
                    {surah.total_verses} Ayahs
                  </div>

                </div>

                <div className="surah-arabic">
                  {surah.name}
                </div>

              </button>
            );
          })}

          {surahs.length === 0 && (
            <div className="empty-state">
              No Surahs found.
            </div>
          )}

        </div>
      </aside>
    </>
  );
}

// ============================================================
// Reader top
// ============================================================

function ReaderTop({
  currentSurah,
  currentData,
  loading,
  onPrevious,
  onNext,
  canPrevious,
  canNext,
  focusMode,
  setFocusMode
}) {
  return (
    <section className="reader-top">

      <div className="breadcrumb">
        <span>Qur'an</span>
        <span className="breadcrumb-dot">•</span>
        <span>
          Surah {currentSurah?.id || "—"}
        </span>
      </div>

      <div className="surah-hero">

        <div className="surah-hero-number">
          {currentSurah?.id || "—"}
        </div>

        <div className="surah-hero-content">

          <div className="surah-hero-arabic">
            {currentSurah?.name || "Loading…"}
          </div>

          <div className="surah-hero-title">
            {currentSurah?.transliteration ||
              "Qur'an"}
          </div>

          <div className="surah-hero-meta">

            <span>
              {currentSurah?.type || "—"}
            </span>

            <span>•</span>

            <span>
              {currentSurah?.total_verses || 0} Ayahs
            </span>

            {currentData && (
              <>
                <span>•</span>
                <span>
                  Loaded locally
                </span>
              </>
            )}

          </div>

        </div>

        <div className="hero-actions">

          <button
            className="round-action"
            onClick={onPrevious}
            disabled={!canPrevious}
            title="Previous Surah"
          >
            <ChevronLeft size={20} />
          </button>

          <button
            className="round-action"
            onClick={onNext}
            disabled={!canNext}
            title="Next Surah"
          >
            <ChevronRight size={20} />
          </button>

        </div>
      </div>

      {loading && (
        <div className="loading-strip">
          <div className="loading-spinner" />
          <span>
            Loading Surah…
          </span>
        </div>
      )}
    </section>
  );
}

// ============================================================
// Reader
// ============================================================

function Reader({
  surah,
  metadata,
  fontSize,
  lineHeight,
  compact,
  isBookmarked,
  toggleBookmark,
  copyVerse,
  shareVerse,
  markVerseRead,
  lastVerse,
  loading
}) {
  if (loading && !surah) {
    return (
      <div className="reader-card skeleton-card">

        <div className="skeleton-line skeleton-large" />
        <div className="skeleton-line" />
        <div className="skeleton-line" />
        <div className="skeleton-line skeleton-medium" />

        <div className="skeleton-ayah">
          <div className="skeleton-line" />
          <div className="skeleton-line" />
          <div className="skeleton-line skeleton-medium" />
        </div>

        <div className="skeleton-ayah">
          <div className="skeleton-line" />
          <div className="skeleton-line" />
          <div className="skeleton-line skeleton-medium" />
        </div>

      </div>
    );
  }

  if (!surah) {
    return (
      <div className="reader-card empty-reader">
        <BookOpen size={34} />
        <h2>Select a Surah</h2>
        <p>
          Choose a chapter from the Surah list.
        </p>
      </div>
    );
  }

  const verses = Array.isArray(surah.verses)
    ? surah.verses
    : [];

  return (
    <section
      className={
        `reader-card ` +
        `${compact ? "compact-reader" : ""}`
      }
    >

      <div className="bismillah">
        بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
      </div>

      <div className="reader-divider">
        <span />
        <Sparkles size={15} />
        <span />
      </div>

      <div
        className="ayah-list"
        style={{
          "--arabic-size": `${fontSize}px`,
          "--arabic-line-height": lineHeight
        }}
      >

        {verses.map((verse) => {
          const bookmarked =
            isBookmarked(
              surah.id,
              verse.id
            );

          const isLastRead =
            Number(lastVerse) ===
            Number(verse.id);

          return (
            <article
              className={
                `ayah ` +
                `${bookmarked ? "ayah-bookmarked" : ""} ` +
                `${isLastRead ? "ayah-last-read" : ""}`
              }
              id={`ayah-${surah.id}-${verse.id}`}
              key={verse.id}
              onClick={() =>
                markVerseRead(
                  surah.id,
                  verse.id
                )
              }
            >

              <div className="ayah-top">

                <div className="ayah-number">
                  <span>
                    {verse.id}
                  </span>
                </div>

                <div className="ayah-actions">

                  <button
                    className={
                      bookmarked
                        ? "ayah-action active"
                        : "ayah-action"
                    }
                    onClick={(event) => {
                      event.stopPropagation();

                      toggleBookmark(
                        surah,
                        verse
                      );
                    }}
                    title={
                      bookmarked
                        ? "Remove bookmark"
                        : "Bookmark Ayah"
                    }
                  >
                    {bookmarked ? (
                      <BookmarkCheck
                        size={17}
                      />
                    ) : (
                      <Bookmark
                        size={17}
                      />
                    )}
                  </button>

                  <button
                    className="ayah-action"
                    onClick={(event) => {
                      event.stopPropagation();

                      copyVerse(
                        surah,
                        verse
                      );
                    }}
                    title="Copy Ayah"
                  >
                    <Copy size={16} />
                  </button>

                  <button
                    className="ayah-action"
                    onClick={(event) => {
                      event.stopPropagation();

                      shareVerse(
                        surah,
                        verse
                      );
                    }}
                    title="Share Ayah"
                  >
                    <Share2 size={16} />
                  </button>

                </div>

              </div>

              <div className="ayah-text">
                {verse.text}
              </div>

            </article>
          );
        })}

      </div>

      <div className="reader-end">

        <div className="reader-divider">
          <span />
          <Heart size={15} />
          <span />
        </div>

        <div className="end-arabic">
          صَدَقَ اللَّهُ الْعَظِيمُ
        </div>

        <div className="end-caption">
          May Allah increase us in understanding.
        </div>

      </div>

    </section>
  );
}

// ============================================================
// Reader bottom
// ============================================================

function ReaderBottom({
  currentSurahId,
  onPrevious,
  onNext,
  canPrevious,
  canNext
}) {
  return (
    <div className="reader-navigation">

      <button
        className="nav-card"
        onClick={onPrevious}
        disabled={!canPrevious}
      >
        <ChevronLeft size={21} />

        <div>
          <span>Previous</span>
          <strong>
            {canPrevious
              ? `Surah ${currentSurahId - 1}`
              : "Beginning"}
          </strong>
        </div>
      </button>

      <div className="nav-center">
        <Hash size={17} />
        <span>
          {currentSurahId} / 114
        </span>
      </div>

      <button
        className="nav-card nav-card-right"
        onClick={onNext}
        disabled={!canNext}
      >
        <div>
          <span>Next</span>
          <strong>
            {canNext
              ? `Surah ${currentSurahId + 1}`
              : "End"}
          </strong>
        </div>

        <ChevronRight size={21} />
      </button>

    </div>
  );
}

// ============================================================
// Mobile bottom bar
// ============================================================

function MobileBottomBar({
  onMenu,
  onSettings,
  onHome,
  onFocus
}) {
  return (
    <nav className="mobile-bottom-bar">

      <button onClick={onHome}>
        <Home size={20} />
        <span>Top</span>
      </button>

      <button onClick={onMenu}>
        <PanelLeft size={20} />
        <span>Surahs</span>
      </button>

      <button
        className="mobile-focus"
        onClick={onFocus}
      >
        <Focus size={20} />
        <span>Focus</span>
      </button>

      <button onClick={onSettings}>
        <Settings size={20} />
        <span>Settings</span>
      </button>

    </nav>
  );
}

// ============================================================
// Settings
// ============================================================

function SettingsPanel({
  open,
  onClose,
  theme,
  setTheme,
  fontSize,
  setFontSize,
  lineHeight,
  setLineHeight,
  compact,
  setCompact
}) {
  return (
    <>
      {open && (
        <div
          className="settings-backdrop"
          onClick={onClose}
        />
      )}

      <aside
        className={
          `settings-panel ` +
          `${open ? "settings-open" : ""}`
        }
      >

        <div className="settings-header">

          <div>
            <div className="settings-title">
              Reading Settings
            </div>

            <div className="settings-subtitle">
              Make the Qur'an comfortable for you.
            </div>
          </div>

          <button
            className="icon-button"
            onClick={onClose}
          >
            <X size={20} />
          </button>

        </div>

        <div className="settings-section">

          <div className="settings-label">
            <span>Theme</span>
            <span className="settings-value">
              {theme}
            </span>
          </div>

          <div className="theme-grid">

            {THEMES.map((item) => {
              const Icon = item.icon;

              return (
                <button
                  key={item.id}
                  className={
                    `theme-option ` +
                    `${theme === item.id ? "theme-selected" : ""}`
                  }
                  onClick={() =>
                    setTheme(item.id)
                  }
                >
                  <Icon size={19} />
                  <span>{item.label}</span>
                </button>
              );
            })}

          </div>

        </div>

        <div className="settings-section">

          <div className="settings-label">
            <span>Arabic Font Size</span>
            <span className="settings-value">
              {fontSize}px
            </span>
          </div>

          <input
            className="range"
            type="range"
            min="24"
            max="58"
            step="1"
            value={fontSize}
            onChange={(event) =>
              setFontSize(
                Number(event.target.value)
              )
            }
          />

        </div>

        <div className="settings-section">

          <div className="settings-label">
            <span>Line Spacing</span>
            <span className="settings-value">
              {Number(lineHeight).toFixed(2)}
            </span>
          </div>

          <input
            className="range"
            type="range"
            min="1.55"
            max="3"
            step="0.05"
            value={lineHeight}
            onChange={(event) =>
              setLineHeight(
                Number(event.target.value)
              )
            }
          />

        </div>

        <div className="settings-section">

          <div className="setting-toggle-row">

            <div>
              <strong>
                Compact Reading
              </strong>

              <span>
                Reduce spacing between Ayahs.
              </span>
            </div>

            <button
              className={
                `toggle ` +
                `${compact ? "toggle-on" : ""}`
              }
              onClick={() =>
                setCompact((value) => !value)
              }
              aria-label="Toggle compact reading"
            >
              <span />
            </button>

          </div>

        </div>

        <div className="settings-help">

          <Zap size={18} />

          <div>
            <strong>
              Keyboard shortcuts
            </strong>

            <p>
              ← / → previous and next Surah
              <br />
              F focus mode
              <br />
              B sidebar
              <br />
              Esc close panels
            </p>
          </div>

        </div>

        <div className="settings-footer">
          Qur'an Reader V2
        </div>

      </aside>
    </>
  );
}

export default App;
'@

Set-Content -LiteralPath (Join-Path $srcPath "App.jsx") `
    -Value $appJsx `
    -Encoding UTF8

# ------------------------------------------------------------
# styles.css
# ------------------------------------------------------------

$stylesCss = @'
:root {
  font-family: Inter, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;

  color-scheme: dark;

  --bg: #050b14;
  --bg-secondary: #091322;
  --surface: rgba(13, 25, 43, 0.72);
  --surface-solid: #0c1727;
  --surface-soft: rgba(255, 255, 255, 0.045);

  --text: #edf6ff;
  --text-soft: #9db0c8;
  --text-muted: #71839b;

  --accent: #7dd3fc;
  --accent-strong: #38bdf8;
  --accent-soft: rgba(56, 189, 248, 0.12);

  --gold: #f5d58a;
  --gold-soft: rgba(245, 213, 138, 0.11);

  --border: rgba(255, 255, 255, 0.09);
  --border-strong: rgba(125, 211, 252, 0.25);

  --shadow:
    0 20px 70px rgba(0, 0, 0, 0.32);

  --radius: 22px;
  --sidebar-width: 340px;
}

:root[data-theme="light"] {
  color-scheme: light;

  --bg: #eef5f7;
  --bg-secondary: #f8fbfc;
  --surface: rgba(255, 255, 255, 0.8);
  --surface-solid: #ffffff;
  --surface-soft: rgba(7, 37, 54, 0.045);

  --text: #10212d;
  --text-soft: #526776;
  --text-muted: #778b98;

  --accent: #087ea4;
  --accent-strong: #056b8d;
  --accent-soft: rgba(8, 126, 164, 0.09);

  --gold: #aa7610;
  --gold-soft: rgba(170, 118, 16, 0.09);

  --border: rgba(15, 43, 58, 0.1);
  --border-strong: rgba(8, 126, 164, 0.25);

  --shadow:
    0 20px 70px rgba(33, 65, 77, 0.13);
}

:root[data-theme="dark"] {
  color-scheme: dark;

  --bg: #070708;
  --bg-secondary: #101012;
  --surface: rgba(22, 22, 25, 0.8);
  --surface-solid: #141417;
  --surface-soft: rgba(255, 255, 255, 0.045);

  --text: #f4f4f5;
  --text-soft: #a1a1aa;
  --text-muted: #71717a;

  --accent: #c4b5fd;
  --accent-strong: #a78bfa;
  --accent-soft: rgba(167, 139, 250, 0.11);

  --gold: #facc15;
  --gold-soft: rgba(250, 204, 21, 0.1);

  --border: rgba(255, 255, 255, 0.09);
  --border-strong: rgba(196, 181, 253, 0.25);
}

* {
  box-sizing: border-box;
}

html {
  min-width: 320px;
  background: var(--bg);
  scroll-behavior: smooth;
}

body {
  margin: 0;
  min-width: 320px;
  min-height: 100vh;
  background:
    radial-gradient(
      circle at 20% 10%,
      var(--accent-soft),
      transparent 28rem
    ),
    var(--bg);
  color: var(--text);
}

button,
input {
  font: inherit;
}

button {
  color: inherit;
}

button:focus-visible,
input:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}

.app-shell {
  position: relative;
  min-height: 100vh;
  overflow-x: clip;
}

.background-effects {
  position: fixed;
  inset: 0;
  pointer-events: none;
  overflow: hidden;
  z-index: 0;
}

.orb {
  position: absolute;
  width: 35rem;
  height: 35rem;
  border-radius: 50%;
  filter: blur(100px);
  opacity: 0.11;
}

.orb-one {
  top: -20rem;
  left: -10rem;
  background: var(--accent-strong);
}

.orb-two {
  right: -18rem;
  top: 25%;
  background: var(--gold);
}

.orb-three {
  left: 35%;
  bottom: -30rem;
  background: #6366f1;
}

.star-field {
  position: absolute;
  inset: 0;
  opacity: 0.2;
}

.star-field span {
  position: absolute;
  width: 2px;
  height: 2px;
  border-radius: 50%;
  background: currentColor;
  left: calc((var(--i) * 37) % 100 * 1%);
  top: calc((var(--i) * 61) % 100 * 1%);
  opacity: calc(0.15 + ((var(--i) % 5) * 0.12));
  animation: twinkle 4s ease-in-out infinite;
  animation-delay: calc(var(--i) * -0.17s);
}

.geometry {
  position: absolute;
  width: 32rem;
  height: 32rem;
  border: 1px solid var(--border);
  transform: rotate(45deg);
  opacity: 0.14;
}

.geometry-one {
  right: -22rem;
  top: 8rem;
}

.geometry-two {
  left: -24rem;
  bottom: 5rem;
}

@keyframes twinkle {
  0%, 100% {
    transform: scale(0.7);
    opacity: 0.15;
  }

  50% {
    transform: scale(1.7);
    opacity: 0.55;
  }
}

.top-header {
  position: sticky;
  top: 0;
  z-index: 50;

  border-bottom: 1px solid var(--border);

  background:
    linear-gradient(
      180deg,
      rgba(5, 11, 20, 0.93),
      rgba(5, 11, 20, 0.74)
    );

  backdrop-filter: blur(24px);
}

:root[data-theme="light"] .top-header {
  background:
    linear-gradient(
      180deg,
      rgba(248, 251, 252, 0.95),
      rgba(248, 251, 252, 0.78)
    );
}

.header-inner {
  max-width: 1700px;
  min-height: 76px;
  margin: auto;
  padding: 0 26px;

  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
}

.brand {
  display: flex;
  align-items: center;
  gap: 13px;
}

.brand-icon {
  width: 42px;
  height: 42px;
  border-radius: 14px;

  display: grid;
  place-items: center;

  color: var(--accent);

  background:
    linear-gradient(
      135deg,
      var(--accent-soft),
      var(--gold-soft)
    );

  border: 1px solid var(--border-strong);

  box-shadow:
    0 8px 30px rgba(56, 189, 248, 0.08);
}

.brand-title {
  font-size: 16px;
  font-weight: 800;
  letter-spacing: -0.025em;
}

.brand-subtitle {
  margin-top: 2px;
  font-size: 10px;
  color: var(--text-muted);
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.header-button,
.mobile-menu-button {
  border: 1px solid var(--border);
  background: var(--surface-soft);

  min-height: 40px;
  padding: 0 13px;

  border-radius: 12px;

  display: flex;
  align-items: center;
  gap: 8px;

  cursor: pointer;

  transition:
    transform 160ms ease,
    background 160ms ease,
    border-color 160ms ease;
}

.header-button:hover,
.mobile-menu-button:hover {
  transform: translateY(-1px);
  border-color: var(--border-strong);
  background: var(--accent-soft);
}

.mobile-menu-button {
  display: none;
  padding: 0;
  width: 42px;
  justify-content: center;
}

.app-layout {
  position: relative;
  z-index: 2;

  display: grid;
  grid-template-columns: var(--sidebar-width) minmax(0, 1fr);

  max-width: 1700px;
  margin: auto;
}

.sidebar {
  position: sticky;
  top: 76px;

  height: calc(100vh - 76px);

  overflow: hidden;

  border-right: 1px solid var(--border);

  background:
    linear-gradient(
      180deg,
      rgba(9, 19, 34, 0.82),
      rgba(5, 11, 20, 0.68)
    );

  backdrop-filter: blur(18px);
}

:root[data-theme="light"] .sidebar {
  background:
    linear-gradient(
      180deg,
      rgba(255, 255, 255, 0.88),
      rgba(245, 249, 250, 0.78)
    );
}

.sidebar-header {
  padding: 24px 20px 15px;

  display: flex;
  align-items: flex-start;
  justify-content: space-between;
}

.sidebar-title {
  font-size: 18px;
  font-weight: 800;
}

.sidebar-count {
  margin-top: 3px;
  font-size: 11px;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.1em;
}

.search-box {
  margin: 0 16px;

  min-height: 44px;

  display: flex;
  align-items: center;
  gap: 9px;

  padding: 0 13px;

  border: 1px solid var(--border);
  border-radius: 13px;

  background: var(--surface-soft);

  color: var(--text-muted);
}

.search-box input {
  flex: 1;
  width: 0;

  border: 0;
  outline: 0;

  background: transparent;
  color: var(--text);
}

.search-box input::placeholder {
  color: var(--text-muted);
}

.search-clear {
  border: 0;
  background: transparent;
  color: var(--text-muted);
  cursor: pointer;
  display: grid;
  place-items: center;
}

.filter-row {
  display: flex;
  gap: 6px;
  padding: 12px 16px 7px;
}

.filter-row button {
  flex: 1;

  min-height: 31px;

  border: 1px solid var(--border);
  border-radius: 9px;

  background: transparent;
  color: var(--text-muted);

  font-size: 10px;
  font-weight: 700;

  text-transform: uppercase;
  letter-spacing: 0.05em;

  cursor: pointer;
}

.filter-row button:hover,
.filter-row button.filter-active {
  color: var(--accent);
  background: var(--accent-soft);
  border-color: var(--border-strong);
}

.bookmark-summary {
  margin: 6px 16px 8px;
  padding: 8px 10px;

  display: flex;
  align-items: center;
  gap: 8px;

  color: var(--gold);

  font-size: 11px;
}

.surah-list {
  height: calc(100vh - 260px);
  overflow-y: auto;

  padding: 4px 10px 30px;
}

.surah-list::-webkit-scrollbar {
  width: 5px;
}

.surah-list::-webkit-scrollbar-thumb {
  background: var(--border);
  border-radius: 20px;
}

.surah-item {
  width: 100%;

  border: 1px solid transparent;
  background: transparent;

  padding: 10px;

  margin-bottom: 4px;

  border-radius: 13px;

  display: grid;
  grid-template-columns: 35px minmax(0, 1fr) auto;
  align-items: center;
  gap: 10px;

  text-align: left;

  cursor: pointer;

  transition:
    background 150ms ease,
    border-color 150ms ease,
    transform 150ms ease;
}

.surah-item:hover {
  transform: translateX(2px);
  background: var(--surface-soft);
}

.surah-item.surah-active {
  border-color: var(--border-strong);
  background:
    linear-gradient(
      135deg,
      var(--accent-soft),
      transparent
    );
}

.surah-number {
  width: 31px;
  height: 31px;

  display: grid;
  place-items: center;

  border: 1px solid var(--border);

  border-radius: 10px;

  font-size: 11px;
  font-weight: 800;

  color: var(--text-muted);
}

.surah-active .surah-number {
  color: var(--accent);
  border-color: var(--border-strong);
}

.surah-info {
  min-width: 0;
}

.surah-translit {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;

  font-size: 12px;
  font-weight: 700;
}

.surah-meta {
  margin-top: 3px;

  font-size: 9px;
  color: var(--text-muted);

  text-transform: capitalize;
}

.surah-arabic {
  font-family: Amiri, serif;
  font-size: 19px;
  color: var(--gold);
  direction: rtl;
}

.reader-main {
  min-width: 0;
  width: 100%;

  padding: 28px clamp(18px, 4vw, 60px) 100px;
}

.reader-top {
  max-width: 1000px;
  margin: auto;
}

.breadcrumb {
  display: flex;
  align-items: center;
  gap: 8px;

  margin: 0 0 15px;

  color: var(--text-muted);

  font-size: 11px;
  font-weight: 700;

  text-transform: uppercase;
  letter-spacing: 0.09em;
}

.breadcrumb-dot {
  color: var(--accent);
}

.surah-hero {
  position: relative;

  min-height: 155px;

  padding: 27px;

  display: flex;
  align-items: center;
  gap: 20px;

  overflow: hidden;

  border: 1px solid var(--border);
  border-radius: var(--radius);

  background:
    radial-gradient(
      circle at 85% 20%,
      var(--gold-soft),
      transparent 20rem
    ),
    linear-gradient(
      135deg,
      var(--surface),
      var(--surface-soft)
    );

  box-shadow: var(--shadow);

  backdrop-filter: blur(22px);
}

.surah-hero::after {
  content: "";

  position: absolute;
  width: 180px;
  height: 180px;

  right: -80px;
  bottom: -100px;

  border: 1px solid var(--border-strong);
  transform: rotate(45deg);
}

.surah-hero-number {
  width: 74px;
  height: 74px;

  flex: 0 0 auto;

  display: grid;
  place-items: center;

  border-radius: 22px;

  font-size: 22px;
  font-weight: 800;

  color: var(--accent);

  background:
    linear-gradient(
      135deg,
      var(--accent-soft),
      var(--gold-soft)
    );

  border: 1px solid var(--border-strong);
}

.surah-hero-content {
  position: relative;
  z-index: 1;

  min-width: 0;
}

.surah-hero-arabic {
  direction: rtl;

  font-family: Amiri, serif;
  font-size: 32px;

  color: var(--gold);

  line-height: 1.15;
}

.surah-hero-title {
  margin-top: 3px;

  font-size: 24px;
  font-weight: 800;

  letter-spacing: -0.04em;
}

.surah-hero-meta {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 7px;

  margin-top: 8px;

  color: var(--text-muted);

  font-size: 11px;
  font-weight: 600;

  text-transform: capitalize;
}

.hero-actions {
  position: relative;
  z-index: 2;

  margin-left: auto;

  display: flex;
  gap: 7px;
}

.round-action,
.icon-button {
  border: 1px solid var(--border);

  background: var(--surface-soft);

  display: grid;
  place-items: center;

  cursor: pointer;

  transition:
    background 150ms ease,
    border-color 150ms ease,
    transform 150ms ease;
}

.round-action {
  width: 42px;
  height: 42px;
  border-radius: 50%;
}

.round-action:hover:not(:disabled),
.icon-button:hover {
  transform: translateY(-1px);
  border-color: var(--border-strong);
  background: var(--accent-soft);
}

.round-action:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.icon-button {
  width: 38px;
  height: 38px;
  border-radius: 11px;
}

.mobile-close {
  display: none;
}

.loading-strip {
  margin-top: 10px;

  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;

  color: var(--accent);

  font-size: 11px;
  font-weight: 700;
}

.loading-spinner {
  width: 14px;
  height: 14px;

  border-radius: 50%;

  border: 2px solid var(--border);
  border-top-color: var(--accent);

  animation: spin 700ms linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.error-banner {
  max-width: 1000px;

  margin: 14px auto 0;
  padding: 12px 14px;

  display: flex;
  align-items: center;
  gap: 9px;

  color: #fecaca;

  border: 1px solid rgba(248, 113, 113, 0.25);
  background: rgba(127, 29, 29, 0.2);

  border-radius: 12px;

  font-size: 12px;
}

.error-banner span {
  flex: 1;
}

.error-banner .icon-button {
  width: auto;
  padding: 0 10px;
  color: inherit;
}

.reader-card {
  position: relative;

  max-width: 1000px;

  margin: 22px auto 0;
  padding: clamp(25px, 5vw, 58px);

  border: 1px solid var(--border);
  border-radius: 28px;

  background:
    linear-gradient(
      135deg,
      var(--surface),
      rgba(255, 255, 255, 0.015)
    );

  box-shadow: var(--shadow);

  backdrop-filter: blur(25px);
}

.bismillah {
  direction: rtl;
  text-align: center;

  font-family: Amiri, serif;

  font-size: clamp(27px, 4vw, 39px);

  color: var(--gold);

  line-height: 1.5;
}

.reader-divider {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;

  margin: 25px auto;

  color: var(--gold);
}

.reader-divider span {
  height: 1px;
  flex: 1;
  max-width: 180px;
  background:
    linear-gradient(
      90deg,
      transparent,
      var(--border-strong),
      transparent
    );
}

.ayah-list {
  direction: rtl;
}

.ayah {
  position: relative;

  padding: 25px 0 28px;

  border-bottom: 1px solid var(--border);

  cursor: pointer;

  transition:
    background 180ms ease,
    padding 180ms ease;
}

.ayah:hover {
  background:
    linear-gradient(
      90deg,
      transparent,
      var(--accent-soft),
      transparent
    );
}

.ayah:last-child {
  border-bottom: 0;
}

.ayah-bookmarked {
  border-right: 3px solid var(--gold);
  padding-right: 15px;
}

.ayah-last-read {
  background:
    linear-gradient(
      90deg,
      transparent,
      var(--gold-soft),
      transparent
    );
}

.ayah-top {
  direction: ltr;

  display: flex;
  align-items: center;
  justify-content: space-between;

  margin-bottom: 12px;
}

.ayah-number {
  width: 38px;
  height: 38px;

  display: grid;
  place-items: center;

  border: 1px solid var(--border-strong);
  border-radius: 50%;

  color: var(--accent);

  background: var(--accent-soft);

  font-size: 11px;
  font-weight: 800;
}

.ayah-number span {
  transform: rotate(0deg);
}

.ayah-actions {
  display: flex;
  align-items: center;
  gap: 5px;

  opacity: 0.35;

  transition: opacity 150ms ease;
}

.ayah:hover .ayah-actions,
.ayah:focus-within .ayah-actions,
.ayah-bookmarked .ayah-actions {
  opacity: 1;
}

.ayah-action {
  width: 34px;
  height: 34px;

  display: grid;
  place-items: center;

  border: 1px solid var(--border);
  border-radius: 9px;

  background: var(--surface-soft);

  color: var(--text-muted);

  cursor: pointer;
}

.ayah-action:hover,
.ayah-action.active {
  color: var(--gold);
  border-color: rgba(245, 213, 138, 0.35);
  background: var(--gold-soft);
}

.ayah-text {
  direction: rtl;

  text-align: right;

  font-family: Amiri, "Times New Roman", serif;

  font-size: var(--arabic-size);
  line-height: var(--arabic-line-height);

  color: var(--text);

  word-spacing: 0.12em;
}

.compact-reader .ayah {
  padding-top: 17px;
  padding-bottom: 18px;
}

.reader-end {
  text-align: center;
}

.end-arabic {
  direction: rtl;

  font-family: Amiri, serif;

  font-size: 25px;

  color: var(--gold);
}

.end-caption {
  margin-top: 6px;

  color: var(--text-muted);

  font-size: 11px;
}

.reader-navigation {
  max-width: 1000px;

  margin: 18px auto 0;

  display: grid;
  grid-template-columns: 1fr auto 1fr;
  align-items: center;
  gap: 12px;
}

.nav-card {
  min-height: 66px;

  padding: 11px 15px;

  display: flex;
  align-items: center;
  gap: 10px;

  border: 1px solid var(--border);
  border-radius: 16px;

  background: var(--surface-soft);

  cursor: pointer;

  text-align: left;

  transition:
    transform 150ms ease,
    border-color 150ms ease,
    background 150ms ease;
}

.nav-card-right {
  justify-content: flex-end;
  text-align: right;
}

.nav-card:hover:not(:disabled) {
  transform: translateY(-2px);
  border-color: var(--border-strong);
  background: var(--accent-soft);
}

.nav-card:disabled {
  opacity: 0.35;
  cursor: not-allowed;
}

.nav-card div {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.nav-card span {
  font-size: 9px;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.1em;
}

.nav-card strong {
  font-size: 12px;
}

.nav-center {
  display: flex;
  align-items: center;
  gap: 6px;

  color: var(--text-muted);

  font-size: 11px;
  white-space: nowrap;
}

.mobile-bottom-bar {
  display: none;
}

.settings-backdrop,
.sidebar-backdrop {
  display: none;
}

.settings-panel {
  position: fixed;
  z-index: 100;

  top: 0;
  right: 0;

  width: min(390px, 100vw);
  height: 100vh;

  padding: 25px;

  overflow-y: auto;

  border-left: 1px solid var(--border);

  background:
    linear-gradient(
      180deg,
      var(--surface-solid),
      var(--bg)
    );

  box-shadow:
    -30px 0 90px rgba(0, 0, 0, 0.25);

  transform: translateX(105%);

  transition: transform 220ms ease;
}

.settings-panel.settings-open {
  transform: translateX(0);
}

.settings-header {
  display: flex;
  justify-content: space-between;
  gap: 20px;

  padding-bottom: 25px;

  border-bottom: 1px solid var(--border);
}

.settings-title {
  font-size: 19px;
  font-weight: 800;
}

.settings-subtitle {
  margin-top: 5px;

  color: var(--text-muted);

  font-size: 11px;
  line-height: 1.6;
}

.settings-section {
  padding: 22px 0;

  border-bottom: 1px solid var(--border);
}

.settings-label {
  display: flex;
  align-items: center;
  justify-content: space-between;

  margin-bottom: 13px;

  font-size: 12px;
  font-weight: 700;
}

.settings-value {
  color: var(--accent);
  font-variant-numeric: tabular-nums;
}

.theme-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 7px;
}

.theme-option {
  min-height: 72px;

  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 7px;

  border: 1px solid var(--border);
  border-radius: 13px;

  background: var(--surface-soft);

  color: var(--text-muted);

  cursor: pointer;
}

.theme-option:hover,
.theme-option.theme-selected {
  color: var(--accent);
  border-color: var(--border-strong);
  background: var(--accent-soft);
}

.theme-option span {
  font-size: 10px;
  font-weight: 700;
}

.range {
  width: 100%;

  accent-color: var(--accent);

  cursor: pointer;
}

.setting-toggle-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
}

.setting-toggle-row div {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.setting-toggle-row strong {
  font-size: 12px;
}

.setting-toggle-row span {
  color: var(--text-muted);
  font-size: 10px;
}

.toggle {
  position: relative;

  width: 46px;
  height: 25px;

  flex: 0 0 auto;

  padding: 3px;

  border: 0;
  border-radius: 50px;

  background: var(--surface-soft);

  box-shadow: inset 0 0 0 1px var(--border);

  cursor: pointer;
}

.toggle span {
  display: block;

  width: 19px;
  height: 19px;

  border-radius: 50%;

  background: var(--text-muted);

  transition:
    transform 160ms ease,
    background 160ms ease;
}

.toggle.toggle-on {
  background: var(--accent-soft);
}

.toggle.toggle-on span {
  transform: translateX(21px);
  background: var(--accent);
}

.settings-help {
  margin-top: 22px;

  padding: 15px;

  display: flex;
  gap: 11px;

  border: 1px solid var(--border);
  border-radius: 14px;

  background: var(--surface-soft);

  color: var(--accent);
}

.settings-help strong {
  color: var(--text);
  font-size: 12px;
}

.settings-help p {
  margin: 7px 0 0;

  color: var(--text-muted);

  font-size: 10px;
  line-height: 1.8;
}

.settings-footer {
  padding: 25px 0;

  text-align: center;

  color: var(--text-muted);

  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.12em;
}

.focus-active .reader-main {
  max-width: 1080px;
  margin: auto;
}

.focus-active .reader-card {
  box-shadow: none;
  border-color: transparent;
  background: transparent;
}

.focus-active .reader-top {
  max-width: 1000px;
}

.focus-exit {
  position: fixed;
  z-index: 90;

  top: 20px;
  right: 20px;

  min-height: 42px;

  padding: 0 13px;

  display: flex;
  align-items: center;
  gap: 8px;

  border: 1px solid var(--border);
  border-radius: 12px;

  background: var(--surface);

  color: var(--text-soft);

  backdrop-filter: blur(18px);

  cursor: pointer;
}

.skeleton-card {
  min-height: 650px;
}

.skeleton-line {
  height: 18px;

  margin: 10px 0;

  border-radius: 8px;

  background:
    linear-gradient(
      90deg,
      var(--surface-soft),
      var(--accent-soft),
      var(--surface-soft)
    );

  background-size: 200% 100%;

  animation: shimmer 1.4s ease-in-out infinite;
}

.skeleton-large {
  width: 55%;
  height: 32px;
  margin: 30px auto;
}

.skeleton-medium {
  width: 65%;
}

.skeleton-ayah {
  margin-top: 45px;
}

@keyframes shimmer {
  from {
    background-position: 200% 0;
  }

  to {
    background-position: -200% 0;
  }
}

.empty-reader {
  min-height: 350px;

  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;

  color: var(--text-muted);

  text-align: center;
}

.empty-reader h2 {
  margin: 12px 0 3px;
  color: var(--text);
}

.empty-reader p {
  margin: 0;
  font-size: 12px;
}

.empty-state {
  padding: 30px 15px;

  text-align: center;

  color: var(--text-muted);

  font-size: 12px;
}

/* ----------------------------------------------------------
   Responsive
---------------------------------------------------------- */

@media (max-width: 1000px) {
  :root {
    --sidebar-width: 300px;
  }

  .reader-main {
    padding-left: 25px;
    padding-right: 25px;
  }

  .surah-hero {
    padding: 22px;
  }

  .surah-hero-number {
    width: 62px;
    height: 62px;
  }
}

@media (max-width: 800px) {
  .top-header {
    position: sticky;
  }

  .header-inner {
    min-height: 66px;
    padding: 0 14px;
  }

  .mobile-menu-button {
    display: flex;
  }

  .brand {
    margin-right: auto;
  }

  .brand-icon {
    width: 39px;
    height: 39px;
  }

  .brand-subtitle {
    display: none;
  }

  .header-button {
    padding: 0;
    width: 40px;
    justify-content: center;
  }

  .header-button span {
    display: none;
  }

  .app-layout {
    display: block;
  }

  .sidebar {
    position: fixed;

    top: 0;
    left: 0;

    z-index: 110;

    width: min(350px, 92vw);
    height: 100vh;

    transform: translateX(-105%);

    transition: transform 220ms ease;

    box-shadow:
      25px 0 80px rgba(0, 0, 0, 0.35);
  }

  .sidebar.sidebar-open {
    transform: translateX(0);
  }

  .sidebar-backdrop {
    display: block;

    position: fixed;
    z-index: 105;

    inset: 0;

    background: rgba(0, 0, 0, 0.5);

    backdrop-filter: blur(4px);
  }

  .mobile-close {
    display: grid;
  }

  .surah-list {
    height: calc(100vh - 250px);
  }

  .reader-main {
    padding:
      18px
      12px
      100px;
  }

  .surah-hero {
    min-height: 125px;
    padding: 18px;

    border-radius: 19px;

    gap: 13px;
  }

  .surah-hero-number {
    width: 52px;
    height: 52px;

    border-radius: 15px;

    font-size: 17px;
  }

  .surah-hero-arabic {
    font-size: 25px;
  }

  .surah-hero-title {
    font-size: 19px;
  }

  .surah-hero-meta {
    font-size: 9px;
  }

  .hero-actions {
    display: none;
  }

  .reader-card {
    margin-top: 12px;

    padding:
      23px
      16px;

    border-radius: 20px;
  }

  .ayah {
    padding: 21px 0 24px;
  }

  .ayah-actions {
    opacity: 1;
  }

  .ayah-action {
    width: 32px;
    height: 32px;
  }

  .reader-navigation {
    grid-template-columns: 1fr 1fr;
  }

  .nav-center {
    display: none;
  }

  .nav-card {
    min-height: 59px;
  }

  .mobile-bottom-bar {
    position: fixed;
    z-index: 80;

    left: 10px;
    right: 10px;
    bottom: 10px;

    min-height: 62px;

    display: grid;
    grid-template-columns: repeat(4, 1fr);

    border: 1px solid var(--border);
    border-radius: 18px;

    background:
      linear-gradient(
        135deg,
        var(--surface-solid),
        var(--surface)
      );

    box-shadow:
      0 15px 45px rgba(0, 0, 0, 0.25);

    backdrop-filter: blur(22px);
  }

  .mobile-bottom-bar button {
    border: 0;
    background: transparent;

    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 3px;

    color: var(--text-muted);

    cursor: pointer;
  }

  .mobile-bottom-bar button:hover {
    color: var(--accent);
  }

  .mobile-bottom-bar span {
    font-size: 8px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.04em;
  }

  .mobile-focus {
    color: var(--accent) !important;
  }

  .settings-backdrop {
    display: block;

    position: fixed;
    z-index: 95;

    inset: 0;

    background: rgba(0, 0, 0, 0.48);

    backdrop-filter: blur(3px);
  }

  .focus-exit {
    top: 12px;
    right: 12px;
  }
}

@media (max-width: 520px) {
  .brand-title {
    font-size: 14px;
  }

  .breadcrumb {
    margin-bottom: 9px;
  }

  .surah-hero {
    display: block;
  }

  .surah-hero-number {
    margin-bottom: 10px;
  }

  .surah-hero-arabic {
    font-size: 28px;
  }

  .surah-hero-title {
    font-size: 21px;
  }

  .reader-card {
    padding-left: 12px;
    padding-right: 12px;
  }

  .bismillah {
    font-size: 25px;
  }

  .ayah-top {
    margin-bottom: 9px;
  }

  .ayah-number {
    width: 33px;
    height: 33px;
  }

  .ayah-action {
    width: 29px;
    height: 29px;
  }

  .ayah-text {
    word-spacing: 0.08em;
  }

  .reader-navigation {
    gap: 7px;
  }

  .nav-card {
    padding-left: 10px;
    padding-right: 10px;
  }
}

/* ----------------------------------------------------------
   Accessibility
---------------------------------------------------------- */

@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    scroll-behavior: auto !important;
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
'@

Set-Content -LiteralPath (Join-Path $srcPath "styles.css") `
    -Value $stylesCss `
    -Encoding UTF8

# ------------------------------------------------------------
# README
# ------------------------------------------------------------

$readme = @'
# Qur'an Reader V2

A fast, responsive Qur'an reader built with React + Vite.

## Architecture

The application does NOT load the entire Qur'an when the website starts.

Instead:

```text
/data/surahs.json
        |
        | metadata only
        v
     React UI
        |
        | user selects Surah
        v
/data/surahs/001.json
````

Each Surah is independently cacheable.

The application also prefetches the previous and next Surahs after the current chapter loads.

## Development

```powershell
npm install
npm run dev
```

Then open the local Vite URL.

## Production build

```powershell
npm run build
```

The production files are generated in:

```text
dist/
```

## Azure Static Web Apps

Recommended settings:

```text
App location: /
Output location: dist
API location: leave empty
```

If deploying from the QuranReader folder, configure your Azure Static Web App workflow accordingly.

## Features

* 114 lazy-loaded Surahs
* Search
* Meccan / Medinan filtering
* Responsive UI
* Dark / light themes
* Arabic font controls
* Line spacing controls
* Compact reading
* Focus mode
* Ayah bookmarks
* Ayah copy
* Native sharing
* Last-read Ayah
* Keyboard shortcuts
* Browser persistence
* Automatic Surah prefetch
* Azure Static Web Apps support

## Keyboard shortcuts

```text
Left Arrow   Previous Surah
Right Arrow  Next Surah
F            Focus mode
B            Open/close sidebar
Escape       Close panels
```

## Data

The source Qur'an JSON is split by the PowerShell generator into:

```text
public/data/surahs/001.json
...
public/data/surahs/114.json
```

This keeps the initial website payload small.
'@

Set-Content -LiteralPath (Join-Path $ProjectPath "README.md") `    -Value $readme`
-Encoding UTF8

# ------------------------------------------------------------

# .gitignore

# ------------------------------------------------------------

$gitignore = @'
node_modules/
dist/
.vite/
.DS_Store
Thumbs.db
'@

Set-Content -LiteralPath (Join-Path $ProjectPath ".gitignore") `    -Value $gitignore`
-Encoding UTF8

# ------------------------------------------------------------

# npm install

# ------------------------------------------------------------

if (-not $SkipNpmInstall) {

```
Write-Host ""
Write-Host "Installing npm packages..." -ForegroundColor Cyan
Write-Host ""

Push-Location $ProjectPath

try {
    npm install

    if ($LASTEXITCODE -ne 0) {
        throw "npm install failed."
    }
}
finally {
    Pop-Location
}
```

}

# ------------------------------------------------------------

# Production build

# ------------------------------------------------------------

Write-Host ""
Write-Host "Building production application..." -ForegroundColor Cyan
Write-Host ""

Push-Location $ProjectPath

try {
if (-not (Test-Path "node_modules")) {
Write-Host "node_modules does not exist." -ForegroundColor Yellow
Write-Host "Run npm install first." -ForegroundColor Yellow
}
else {
npm run build

```
    if ($LASTEXITCODE -ne 0) {
        throw "npm run build failed."
    }
}
```

}
finally {
Pop-Location
}

# ------------------------------------------------------------

# Final report

# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "                 QUR'AN READER READY" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

Write-Host "Project:" -ForegroundColor Cyan
Write-Host "  $ProjectPath"

Write-Host ""

Write-Host "Surah data:" -ForegroundColor Cyan
Write-Host "  $surahsPath"

Write-Host ""

Write-Host "Metadata:" -ForegroundColor Cyan
Write-Host "  $metadataPath"

Write-Host ""

Write-Host "To run locally:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  cd `"$ProjectPath`""
Write-Host "  npm run dev"
Write-Host ""

Write-Host "To build for Azure:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  cd `"$ProjectPath`""
Write-Host "  npm run build"
Write-Host ""

Write-Host "Azure Static Web Apps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  App location:    /"
Write-Host "  Output location: dist"
Write-Host "  API location:    leave empty"
Write-Host ""

Write-Host "============================================================" -ForegroundColor Green
Write-Host ""