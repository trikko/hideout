/+
MIT License

Copyright (c) 2026 Andrea Fontana

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
+/

module i18n;

import std.process : environment;
import std.string : startsWith, toLower;
import std.stdio : writeln;

enum Msg {
    app_title,
    select_page_title,
    select_page_desc,
    select_file_btn,
    action_label,
    op_encrypt,
    op_decrypt,
    dest_label,
    dest_placeholder,
    pwd_label,
    cancel_btn,
    start_btn,
    btn_encrypt,
    btn_decrypt,
    btn_open,
    btn_show_folder,
    confirm_title,
    confirm_desc,
    confirm_yes,
    progress_title_generic,
    progress_desc,
    progress_pct,
    done_title,
    done_success,
    done_saved,
    restart_btn,
    btn_retry,
    err_title,
    err_generic,
    err_bad_password,
    err_corrupted,
    err_cancelled,
    err_code,
    err_asymmetric,
    err_unknown_gpg,
    title_encrypt_file,
    title_decrypt_file,
    btn_install,
    btn_about,
    btn_issues,
    btn_website,
    toast_install_success,
    toast_install_fail
}

private __gshared string currentLang = "";
private __gshared string[Msg][string] allTranslations;

shared static this() {
    string lang = environment.get("LANG", "en_US.UTF-8");
    if (lang.length >= 2) {
        currentLang = lang[0..2].toLower();
    } else {
        currentLang = "en";
    }

    allTranslations = [
        "it": [
            Msg.app_title: "Hideout",
            Msg.select_page_title: "Cripta o Decripta",
            Msg.select_page_desc: "Seleziona o trascina un file qui.",
            Msg.select_file_btn: "Seleziona File",
            Msg.action_label: "Azione:",
            Msg.op_encrypt: "Criptazione",
            Msg.op_decrypt: "Decriptazione",
            Msg.dest_label: "Destinazione:",
            Msg.dest_placeholder: "Nome file in output",
            Msg.pwd_label: "Password di sicurezza:",
            Msg.cancel_btn: "Annulla",
            Msg.start_btn: "Inizia",
            Msg.btn_encrypt: "Cripta",
            Msg.btn_decrypt: "Decripta",
            Msg.btn_open: "Apri",
            Msg.btn_show_folder: "Mostra",
            Msg.confirm_title: "File Esistente",
            Msg.confirm_desc: "Il file di destinazione esiste già.\nSovrascriverlo?",
            Msg.confirm_yes: "Sovrascrivi",
            Msg.progress_title_generic: "Elaborazione...",
            Msg.progress_desc: "Inizio operazione...",
            Msg.progress_pct: "%.1f%% completato",
            Msg.done_title: "Operazione Completata",
            Msg.done_success: "Completato",
            Msg.done_saved: "Salvato in:\n",
            Msg.restart_btn: "Ricomincia",
            Msg.btn_retry: "Riprova",
            Msg.err_title: "Errore",
            Msg.err_generic: "Operazione fallita o annullata.",
            Msg.err_bad_password: "Password errata",
            Msg.err_corrupted: "Decriptazione fallita.\nIl file è corrotto o malformato.",
            Msg.err_cancelled: "L'operazione è stata annullata.",
            Msg.err_code: "Errore durante l'operazione (Codice ",
            Msg.err_asymmetric: "Il file richiede una chiave privata, non una password",
            Msg.err_unknown_gpg: "File non supportato o malformato",
            Msg.title_encrypt_file: "Cripta File",
            Msg.title_decrypt_file: "Decripta File",
            Msg.btn_install: "Installa file Desktop",
            Msg.btn_about: "Informazioni",
            Msg.btn_issues: "Segnala un problema",
            Msg.btn_website: "Sito Web",
            Msg.toast_install_success: "File desktop installato!",
            Msg.toast_install_fail: "Installazione fallita: "
        ],
        "en": [
            Msg.app_title: "Hideout",
            Msg.select_page_title: "Encrypt or Decrypt",
            Msg.select_page_desc: "Select or drag a file here.",
            Msg.select_file_btn: "Select File",
            Msg.action_label: "Action:",
            Msg.op_encrypt: "Encryption",
            Msg.op_decrypt: "Decryption",
            Msg.dest_label: "Destination:",
            Msg.dest_placeholder: "Output filename",
            Msg.pwd_label: "Security password:",
            Msg.cancel_btn: "Cancel",
            Msg.start_btn: "Start",
            Msg.btn_encrypt: "Encrypt",
            Msg.btn_decrypt: "Decrypt",
            Msg.btn_open: "Open",
            Msg.btn_show_folder: "Show",
            Msg.confirm_title: "Existing File",
            Msg.confirm_desc: "The destination file already exists.\nOverwrite it?",
            Msg.confirm_yes: "Overwrite",
            Msg.progress_title_generic: "Processing...",
            Msg.progress_desc: "Starting operation...",
            Msg.progress_pct: "%.1f%% completed",
            Msg.done_title: "Operation Completed",
            Msg.done_success: "Completed",
            Msg.done_saved: "Saved to:\n",
            Msg.restart_btn: "Restart",
            Msg.btn_retry: "Retry",
            Msg.err_title: "Error",
            Msg.err_generic: "Operation failed or cancelled.",
            Msg.err_bad_password: "Wrong password",
            Msg.err_corrupted: "Decryption failed.\nThe file is corrupted or malformed.",
            Msg.err_cancelled: "The operation was cancelled.",
            Msg.err_code: "Error during operation (Code ",
            Msg.err_asymmetric: "The file requires a private key, not a password.",
            Msg.err_unknown_gpg: "File not supported or malformed.",
            Msg.title_encrypt_file: "Encrypt File",
            Msg.title_decrypt_file: "Decrypt File",
            Msg.btn_install: "Install Desktop Entry",
            Msg.btn_about: "About",
            Msg.btn_issues: "Report an Issue",
            Msg.btn_website: "Website",
            Msg.toast_install_success: "Desktop Entry installed!",
            Msg.toast_install_fail: "Installation failed: "
        ],
        "fr": [
            Msg.app_title: "Hideout",
            Msg.select_page_title: "Chiffrer ou Déchiffrer",
            Msg.select_page_desc: "Sélectionnez ou glissez un fichier ici.",
            Msg.select_file_btn: "Sélectionner un Fichier",
            Msg.action_label: "Action:",
            Msg.op_encrypt: "Chiffrement",
            Msg.op_decrypt: "Déchiffrement",
            Msg.dest_label: "Destination:",
            Msg.dest_placeholder: "Nom du fichier de sortie",
            Msg.pwd_label: "Mot de passe de sécurité:",
            Msg.cancel_btn: "Annuler",
            Msg.start_btn: "Démarrer",
            Msg.btn_encrypt: "Chiffrer",
            Msg.btn_decrypt: "Déchiffrer",
            Msg.btn_open: "Ouvrir",
            Msg.btn_show_folder: "Afficher",
            Msg.confirm_title: "Fichier Existant",
            Msg.confirm_desc: "Le fichier de destination existe déjà.\nL'écraser ?",
            Msg.confirm_yes: "Écraser",
            Msg.progress_title_generic: "Traitement en cours...",
            Msg.progress_desc: "Début de l'opération...",
            Msg.progress_pct: "%.1f%% terminé",
            Msg.done_title: "Opération Terminée",
            Msg.done_success: "Terminé",
            Msg.done_saved: "Enregistré dans:\n",
            Msg.restart_btn: "Recommencer",
            Msg.btn_retry: "Réessayer",
            Msg.err_title: "Erreur",
            Msg.err_generic: "L'opération a échoué ou a été annulée.",
            Msg.err_bad_password: "Mot de passe incorrect",
            Msg.err_corrupted: "Déchiffrement échoué.\nLe fichier est corrompu ou mal formé.",
            Msg.err_cancelled: "L'opération a été annulée.",
            Msg.err_code: "Erreur lors de l'opération (Code ",
            Msg.err_asymmetric: "Le fichier nécessite une clé privée, pas un mot de passe.",
            Msg.err_unknown_gpg: "Fichier non pris en charge ou mal formé.",
            Msg.title_encrypt_file: "Chiffrer le Fichier",
            Msg.title_decrypt_file: "Déchiffrer le Fichier",
            Msg.btn_install: "Installer le fichier Desktop",
            Msg.btn_about: "À propos",
            Msg.btn_issues: "Signaler un problème",
            Msg.btn_website: "Site Web",
            Msg.toast_install_success: "Fichier desktop installé !",
            Msg.toast_install_fail: "Échec de l'installation : "
        ],
        "es": [
            Msg.app_title: "Hideout",
            Msg.select_page_title: "Cifrar o Descifrar",
            Msg.select_page_desc: "Seleccione o arrastre un archivo aquí.",
            Msg.select_file_btn: "Seleccionar Archivo",
            Msg.action_label: "Acción:",
            Msg.op_encrypt: "Cifrado",
            Msg.op_decrypt: "Descifrado",
            Msg.dest_label: "Destino:",
            Msg.dest_placeholder: "Nombre del archivo de salida",
            Msg.pwd_label: "Contraseña de seguridad:",
            Msg.cancel_btn: "Cancelar",
            Msg.start_btn: "Empezar",
            Msg.btn_encrypt: "Cifrar",
            Msg.btn_decrypt: "Descifrar",
            Msg.btn_open: "Abrir",
            Msg.btn_show_folder: "Mostrar",
            Msg.confirm_title: "Archivo Existente",
            Msg.confirm_desc: "El archivo de destino ya existe.\n¿Sobrescribirlo?",
            Msg.confirm_yes: "Sobrescribir",
            Msg.progress_title_generic: "Procesando...",
            Msg.progress_desc: "Iniciando operación...",
            Msg.progress_pct: "%.1f%% completado",
            Msg.done_title: "Operación Completada",
            Msg.done_success: "Completado",
            Msg.done_saved: "Guardado en:\n",
            Msg.restart_btn: "Reiniciar",
            Msg.btn_retry: "Reintentar",
            Msg.err_title: "Error",
            Msg.err_generic: "La operación falló o fue cancelada.",
            Msg.err_bad_password: "Contraseña incorrecta",
            Msg.err_corrupted: "Descifrado fallido.\nEl archivo está dañado o malformado.",
            Msg.err_cancelled: "La operación fue cancelada.",
            Msg.err_code: "Error durante la operación (Código ",
            Msg.err_asymmetric: "El archivo requiere una clave privada, no una contraseña.",
            Msg.err_unknown_gpg: "Archivo no soportado o malformado.",
            Msg.title_encrypt_file: "Cifrar Archivo",
            Msg.title_decrypt_file: "Descifrar Archivo",
            Msg.btn_install: "Instalar archivo Desktop",
            Msg.btn_about: "Acerca de",
            Msg.btn_issues: "Informar error",
            Msg.btn_website: "Sitio Web",
            Msg.toast_install_success: "¡Archivo desktop instalado!",
            Msg.toast_install_fail: "La instalación falló: "
        ],
        "de": [
            Msg.app_title: "Hideout",
            Msg.select_page_title: "Verschlüsseln oder Entschlüsseln",
            Msg.select_page_desc: "Wählen Sie eine Datei aus oder ziehen Sie sie hierher.",
            Msg.select_file_btn: "Datei Auswählen",
            Msg.action_label: "Aktion:",
            Msg.op_encrypt: "Verschlüsselung",
            Msg.op_decrypt: "Entschlüsselung",
            Msg.dest_label: "Ziel:",
            Msg.dest_placeholder: "Ausgabedateiname",
            Msg.pwd_label: "Sicherheitspasswort:",
            Msg.cancel_btn: "Abbrechen",
            Msg.start_btn: "Starten",
            Msg.btn_encrypt: "Verschlüsseln",
            Msg.btn_decrypt: "Entschlüsseln",
            Msg.btn_open: "Öffnen",
            Msg.btn_show_folder: "Anzeigen",
            Msg.confirm_title: "Vorhandene Datei",
            Msg.confirm_desc: "Die Zieldatei existiert bereits.\nÜberschreiben?",
            Msg.confirm_yes: "Überschreiben",
            Msg.progress_title_generic: "Wird bearbeitet...",
            Msg.progress_desc: "Operation wird gestartet...",
            Msg.progress_pct: "%.1f%% abgeschlossen",
            Msg.done_title: "Operation Abgeschlossen",
            Msg.done_success: "Abgeschlossen",
            Msg.done_saved: "Gespeichert in:\n",
            Msg.restart_btn: "Neustart",
            Msg.btn_retry: "Wiederholen",
            Msg.err_title: "Fehler",
            Msg.err_generic: "Operation fehlgeschlagen oder abgebrochen.",
            Msg.err_bad_password: "Falsches Passwort",
            Msg.err_corrupted: "Entschlüsselung fehlgeschlagen.\nDie Datei ist beschädigt oder fehlerhaft.",
            Msg.err_cancelled: "Die Operation wurde abgebrochen.",
            Msg.err_code: "Fehler während der Operation (Code ",
            Msg.err_asymmetric: "Die Datei erfordert einen privaten Schlüssel, kein Passwort.",
            Msg.err_unknown_gpg: "Datei nicht unterstützt oder fehlerhaft.",
            Msg.title_encrypt_file: "Datei Verschlüsseln",
            Msg.title_decrypt_file: "Datei Entschlüsseln",
            Msg.btn_install: "Desktop-Datei installieren",
            Msg.btn_about: "Über",
            Msg.btn_issues: "Problem melden",
            Msg.btn_website: "Webseite",
            Msg.toast_install_success: "Desktop-Eintrag installiert!",
            Msg.toast_install_fail: "Installation fehlgeschlagen: "
        ],
        "pt": [
            Msg.app_title: "Hideout",
            Msg.select_page_title: "Criptografar ou Descriptografar",
            Msg.select_page_desc: "Selecione ou arraste um arquivo aqui.",
            Msg.select_file_btn: "Selecionar Arquivo",
            Msg.action_label: "Ação:",
            Msg.op_encrypt: "Criptografia",
            Msg.op_decrypt: "Descriptografia",
            Msg.dest_label: "Destino:",
            Msg.dest_placeholder: "Nome do arquivo de saída",
            Msg.pwd_label: "Senha de segurança:",
            Msg.cancel_btn: "Cancelar",
            Msg.start_btn: "Iniciar",
            Msg.btn_encrypt: "Criptografar",
            Msg.btn_decrypt: "Descriptografar",
            Msg.btn_open: "Abrir",
            Msg.btn_show_folder: "Mostrar",
            Msg.confirm_title: "Arquivo Existente",
            Msg.confirm_desc: "O arquivo de destino já existe.\nSobrescrever?",
            Msg.confirm_yes: "Sobrescrever",
            Msg.progress_title_generic: "Processando...",
            Msg.progress_desc: "Iniciando operação...",
            Msg.progress_pct: "%.1f%% concluído",
            Msg.done_title: "Operação Concluída",
            Msg.done_success: "Concluído",
            Msg.done_saved: "Salvo em:\n",
            Msg.restart_btn: "Reiniciar",
            Msg.btn_retry: "Tentar novamente",
            Msg.err_title: "Erro",
            Msg.err_generic: "Operação falhou ou foi cancelada.",
            Msg.err_bad_password: "Senha incorreta",
            Msg.err_corrupted: "Descriptografia falhou.\nO arquivo está corrompido ou malformado.",
            Msg.err_cancelled: "A operação foi cancelada.",
            Msg.err_code: "Erro durante a operação (Código ",
            Msg.err_asymmetric: "O arquivo requer uma chave privada, não uma senha.",
            Msg.err_unknown_gpg: "Arquivo não suportado ou malformado.",
            Msg.title_encrypt_file: "Criptografar Arquivo",
            Msg.title_decrypt_file: "Descriptografar Arquivo",
            Msg.btn_install: "Instalar arquivo Desktop",
            Msg.btn_about: "Sobre",
            Msg.btn_issues: "Relatar problema",
            Msg.btn_website: "Site",
            Msg.toast_install_success: "Entrada desktop instalada!",
            Msg.toast_install_fail: "A instalação falhou: "
        ]
    ];

    // Strict check that all languages implement ALL keys!
    import std.traits : EnumMembers;
    import std.conv : to;
    foreach (ll, dict; allTranslations) {
        foreach (msg; EnumMembers!Msg) {
            assert(msg in dict, "Missing string in language '" ~ ll ~ "' for key: " ~ to!string(msg));
        }
    }
}

string _(Msg key) {
    if (auto langMap = currentLang in allTranslations) {
        return (*langMap)[key];
    }
    
    // English is the default language
    return allTranslations["en"][key];
}
