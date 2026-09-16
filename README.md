# Qur'an Reader V3.1

Premium emerald and gold Qur'an reading interface.

## Architecture

public/data/surahs.json

public/data/surahs/001.json
public/data/surahs/002.json
...
public/data/surahs/114.json

The application loads the metadata first and then loads only
the selected Surah.

## Features

- Premium emerald and gold Islamic UI
- Responsive Surah navigation
- Individual Surah JSON files
- Continue Reading
- Last-read Surah and Ayah
- URL Surah/Ayah navigation
- Bookmarks
- Arabic font controls
- Line spacing controls
- Emerald theme
- Midnight theme
- Ivory theme
- Tajweed reference legend
- Mobile navigation
- Error screen instead of blank page
- Azure Static Web Apps compatible

## Development

npm install

npm run dev

## Production

npm run build

## Example URL

?surah=2&ayah=255