# Localy

<img width="912" alt="Screenshot 2024-05-18 at 23 15 43" src="https://github.com/dev-err418/localy/assets/59390256/407fa291-2d81-4dc2-9709-80b5b2885562">

### Todo

- [ ] Auto complete (suggestions) in the search bar like spotlight
- [ ] Launch app at login or reboot
- [ ] Find files
- [ ] Splitter: comment on va split les fichiers pour les embeddings ?

### Errors
- Error due to textfield : https://forums.developer.apple.com/forums/thread/742826

### nathan
#### FileSystem
Classe generale qui gère les embeddings et tout les fichiers (pas encore les restrictions). En gros il suffit d'initialiser cette classe en donnant le nom du modèle d'embedding et un callback optionnel quand le modèle est téléchargé.
```swift
await FileSystem(embeddingModelName: "ane-snowflake-arctic-embed-s", callBack: { progress in print(progress) })
```
Les fonctions importantes sont: `embedFiles(urls: [URL])` qui embed tous les fichiers donnés (et aussi les fichiers dans les sous-dossiers) et `searchFiles(query: String, num_results: Int = 6)` qui renvoie les fichiers qui correspondent à la recherche.

#### ChatModel:
Protocole qui régie comment un modèle de chat doit etre.
