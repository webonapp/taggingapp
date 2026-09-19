# Tagging App

Applicazione nativa macOS per analisi video sportiva, ispirata ai flussi di lavoro di codifica, timeline e playlist usati negli strumenti professionali di performance analysis.

> Il repository contiene il codice sorgente. La pagina `github.io` è una pagina informativa: l’applicazione vera viene eseguita su macOS tramite Xcode.

## Stato del progetto

Il prototipo implementa il primo flusso operativo:

- player video MOV/MP4 con AVFoundation;
- progetto salvabile in JSON;
- timeline con righe e istanze temporali;
- Code Window con pulsanti e hotkey;
- label, note e playlist;
- importazione sperimentale di `.SCVideo`, `.SCTimeline` e `Playlist.SCClips`;
- esportazione XML e del primo clip video;
- salvataggio del progetto come pacchetto `.analysisproject`;
- undo/redo e spostamento delle istanze sulla timeline;
- slide immagine nella playlist con durata predefinita di 3 secondi e conversione in MP4;
- Find Window per ricercare righe, label, note e flag;
- esportazione CSV della timeline;
- Database, Sorter, Matrix e Report sulla timeline corrente;
- Heatmap con coordinate spaziali normalizzate associate agli eventi;
- supporto iniziale per più angoli video nel progetto;
- selezione dell’angolo video attivo dal player;
- Sorter playlist con riordino drag & drop;
- editor Heatmap tramite selezione evento e click sul campo;
- Output Window con scripting di conteggi, durate, label e righe;
- titoli e overlay testuali salvati nella playlist;
- diagnostica di file `.CWcode2SC` e export JSON della playlist nativa;
- catalogo centralizzato delle shortcut Sportscode fornite.

Le funzioni di compatibilità completa con `.CWcode2SC` e `.SCPlaylist` sono ancora in sviluppo.

## Apertura con Xcode

1. Installa Xcode su macOS.
2. Clona il repository oppure scarica il codice.
3. Apri `Package.swift` con Xcode.
4. Seleziona lo scheme `VideoAnalysisApp`.
5. Esegui con `⌘R`.

Il progetto usa Swift 6, SwiftUI, AVFoundation e macOS 14 o superiore.

## Primo utilizzo

1. Premi **Importa video** e scegli un file `.mov` o `.mp4`.
2. Crea una riga con **Nuova riga** oppure usa la Code Window.
3. Premi un pulsante della Code Window per creare un’istanza.
4. Aggiungi label e note nella timeline.
5. Inserisci il tag nella playlist.
6. Salva il progetto.

## Struttura

```text
Package.swift
Sources/VideoAnalysisApp/
  Models.swift
  ProjectStore.swift
  ContentView.swift
  TimelineView.swift
  CodeWindowView.swift
  SportscodeInterop.swift
  SportscodePackageImporter.swift
  VideoExporter.swift
  ShortcutCatalog.swift
Tests/VideoAnalysisAppTests/
```

## Formati

Il formato nativo dell’app è separato dai formati proprietari Sportscode. I pacchetti Sportscode vengono importati in copia e gli originali non vengono modificati.

## Sviluppo futuro

- progetto Xcode macOS distribuito;
- timeline editabile con drag e resize;
- undo/redo completo;
- playlist con Sorter e gruppi;
- XML Sportscode compatibile;
- import/export `.SCPlaylist`;
- analisi `.CWcode2SC`;
- database, Matrix e report;
- supporto multi-angolo.
