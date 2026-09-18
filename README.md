# Video Analysis App

Applicazione nativa macOS per analisi video sportiva.

## Direzione approvata

- Swift 6 e SwiftUI
- AVFoundation per video, audio ed esportazioni
- timeline interna JSON versionata
- Code Window nativa dell'app
- playlist interna con esportazione video
- importazione sperimentale dei pacchetti `.SCVideo` e `.SCPlaylist`
- import/export XML in un modulo separato

## Ordine di sviluppo

1. Player video e progetto salvabile
2. Timeline con righe e istanze temporali
3. Code Window con hotkey e codifica
4. Label, note, flag e undo/redo
5. Playlist e tagli esportabili
6. Importazione dei campioni Sportscode
7. Interoperabilità XML e compatibilità `.CWcode2SC`

Il secondo incremento include l'importazione dei JSON `.SCTimeline` e
`Playlist.SCClips`, l'esportazione XML generica e l'esportazione del primo clip
della playlist tramite AVFoundation.

## Shortcut

Le shortcut fornite per macOS, Sportscode, playback, timeline, playlist, sorter,
instance player e Code Window sono raccolte in `ShortcutCatalog.swift`. Il catalogo
è centralizzato per consentire in seguito personalizzazione, conflitti e gestione
delle modalità attive.

## Decisione sui formati

Il formato nativo dell'app sarà separato dai formati Sportscode. I pacchetti Sportscode verranno importati in copia, senza modificare gli originali. La compatibilità `.CWcode2SC` sarà implementata solo dopo aver verificato più campioni reali.

## Primo criterio di successo

Importare un `.mov` o `.mp4`, creare un pulsante Code Window, generare un evento sulla timeline, aggiungere una label e una nota, salvare il progetto, riaprirlo ed esportare il taglio.
