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

import std;
import i18n;
import gpgwrap;
import gid.global;
import adw.application;
import adw.application_window;
import adw.about_window;
import adw.header_bar;
import adw.status_page;
import adw.window;
import gio.application;
import gio.file;
import gio.types;
import adw.toast;
import adw.toast_overlay;
import gtk.application;
import gtk.application_window;
import gtk.box;
import gtk.button;
import gtk.combo_box_text;
import gtk.entry;
import gtk.file_dialog;
import gtk.file_launcher;
import gtk.label;
import gtk.password_entry;
import gtk.progress_bar;
import gtk.stack;
import gtk.image;
import gtk.types : Orientation, Align, Justification;
import glib.global;
import glib.types;
import glib.bytes;
import core.thread;

enum APP_VERSION = import("VERSION").strip();

int main(string[] args)
{

    import gio.global;
    import gio.resource;
    import glib.bytes;
    
    auto resData = cast(ubyte[]) import("resources.gresource");
    auto bytes = new glib.bytes.Bytes(resData);
    auto gres = gio.resource.Resource.newFromData(bytes);
    gio.global.resourcesRegister(gres);

    auto app = new adw.application.Application("it.andreafontana.hideout", cast(gio.types.ApplicationFlags)0);
    
    app.connectActivate((gio.application.Application application) {
        auto win = new adw.application_window.ApplicationWindow(cast(adw.application.Application)application);
        win.setTitle(_(Msg.app_title));
        win.setDefaultSize(360, 500);
        
        auto toastOverlay = new adw.toast_overlay.ToastOverlay();
        win.setContent(toastOverlay);

        // Verifica GPG
        auto gpgCheck = new GPG();
        string gpgVersion = gpgCheck.getVersion();
        
        auto vbox = new gtk.box.Box(Orientation.Vertical, 0);
        toastOverlay.setChild(vbox);

        if (gpgVersion.length == 0) {
            auto errorPage = new adw.status_page.StatusPage();
            errorPage.setTitle(_(Msg.err_title));
            errorPage.setDescription("GnuPG (gpg) is not installed or not in PATH. Please install it to use Hideout.");
            errorPage.setIconName("dialog-error-symbolic");
            vbox.append(errorPage);
            win.show();
            return;
        }
        
        auto header = new adw.header_bar.HeaderBar();
        vbox.append(header);
        
        auto btnAbout = new gtk.button.Button();
        btnAbout.setIconName("help-about-symbolic");
        btnAbout.setTooltipText(_(Msg.btn_about));
        header.packEnd(btnAbout);

        btnAbout.connectClicked((gtk.button.Button btn) {
            auto infoWin = new adw.window.Window();
            infoWin.setTitle(_(Msg.btn_about));
            infoWin.setTransientFor(win);
            infoWin.setModal(true);
            infoWin.setDefaultSize(300, -1);
            infoWin.setResizable(false);

            auto mainVBox = new gtk.box.Box(Orientation.Vertical, 0);
            infoWin.setContent(mainVBox);

            auto infoHeader = new adw.header_bar.HeaderBar();
            mainVBox.append(infoHeader);

            auto infoToastOverlay = new adw.toast_overlay.ToastOverlay();
            mainVBox.append(infoToastOverlay);

            auto infoVBox = new gtk.box.Box(Orientation.Vertical, 18);
            infoVBox.setMarginStart(24);
            infoVBox.setMarginEnd(24);
            infoVBox.setMarginTop(24);
            infoVBox.setMarginBottom(24);
            infoToastOverlay.setChild(infoVBox);

            auto imgIcon = new gtk.image.Image();
            imgIcon.iconName = "it.andreafontana.hideout";
            imgIcon.setPixelSize(96);
            infoVBox.append(imgIcon);

            auto lblTitle = new gtk.label.Label("Hideout");
            lblTitle.addCssClass("title-1");
            infoVBox.append(lblTitle);

            auto lblDetails = new gtk.label.Label("v" ~ APP_VERSION ~ "\nAndrea Fontana");
            lblDetails.setJustify(Justification.Center);
            lblDetails.addCssClass("dim-label");
            infoVBox.append(lblDetails);

            auto buttonsGrid = new gtk.box.Box(Orientation.Vertical, 8);
            infoVBox.append(buttonsGrid);

            auto btnWeb = new gtk.button.Button();
            btnWeb.setLabel(_(Msg.btn_website));
            btnWeb.addCssClass("flat");
            buttonsGrid.append(btnWeb);

            auto btnIssue = new gtk.button.Button();
            btnIssue.setLabel(_(Msg.btn_issues));
            btnIssue.addCssClass("flat");
            buttonsGrid.append(btnIssue);

            version (Flatpak) {} else {
                auto btnInstall = new gtk.button.Button();
                btnInstall.setLabel(_(Msg.btn_install));
                btnInstall.addCssClass("suggested-action");
                buttonsGrid.append(btnInstall);
            }

            btnWeb.connectClicked((gtk.button.Button b) {
                import gtk.file_launcher : FileLauncher;
                import gio.file : File;
                auto launcher = new FileLauncher(File.newForUri("https://github.com/trikko/hideout"));
                launcher.launch(infoWin, null, null);
            });

            btnIssue.connectClicked((gtk.button.Button b) {
                import gtk.file_launcher : FileLauncher;
                import gio.file : File;
                auto launcher = new FileLauncher(File.newForUri("https://github.com/trikko/hideout/issues"));
                launcher.launch(infoWin, null, null);
            });

            version (Flatpak) {} else {
                btnInstall.connectClicked((gtk.button.Button b) {
                    try {
                        import std.process : environment;
                        import std.file : copy, write, mkdirRecurse, exists;
                        import std.path : buildPath, expandTilde;

                        string home = environment.get("HOME");
                        string appsPath = buildPath(home, ".local/share/applications");
                        string iconsPath = buildPath(home, ".local/share/icons/hicolor/scalable/apps");

                        if (!exists(appsPath)) mkdirRecurse(appsPath);
                        if (!exists(iconsPath)) mkdirRecurse(iconsPath);

                        // Copio l'icona
                        string iconSource = buildPath(environment.get("PWD"), "hideout_icon.svg");
                        string iconDest = buildPath(iconsPath, "it.andreafontana.hideout.svg");
                        if (exists(iconSource)) copy(iconSource, iconDest);

                        // Creo il file desktop
                        string desktopPath = buildPath(appsPath, "it.andreafontana.hideout.desktop");
                        string exePath = buildPath(environment.get("PWD"), "hideout");
                        
                        string desktopContent = 
                            "[Desktop Entry]\n" ~
                            "Name=Hideout\n" ~
                            "Comment=Secure file encryption and decryption\n" ~
                            "Exec=" ~ exePath ~ " %f\n" ~
                            "Icon=it.andreafontana.hideout\n" ~
                            "Terminal=false\n" ~
                            "Type=Application\n" ~
                            "Categories=Utility;Security;\n" ~
                            "MimeType=application/pgp-encrypted;\n" ~
                            "StartupNotify=true\n";

                        write(desktopPath, desktopContent);
                        
                        auto toast = new adw.toast.Toast(_(Msg.toast_install_success));
                        infoToastOverlay.addToast(toast);
                        b.setLabel("Installed!");
                        b.setSensitive(false);
                    } catch (Exception ex) {
                        auto toast = new adw.toast.Toast(_(Msg.toast_install_fail) ~ ex.msg);
                        infoToastOverlay.addToast(toast);
                    }
                });
            }

            infoWin.present();
        });
        
        auto stack = new gtk.stack.Stack();
        stack.setVexpand(true);
        stack.setMarginStart(24);
        stack.setMarginEnd(24);
        stack.setMarginTop(24);
        stack.setMarginBottom(24);
        vbox.append(stack);
        
        // --- Page 1: Select File ---
        auto pageSelect = new adw.status_page.StatusPage();
        pageSelect.setTitle(_(Msg.select_page_title));
        pageSelect.setDescription(_(Msg.select_page_desc));
        pageSelect.setIconName("document-send-symbolic");
        
        auto btnSelect = new gtk.button.Button();
        btnSelect.setLabel(_(Msg.select_file_btn));
        btnSelect.setHalign(Align.Center);
        btnSelect.addCssClass("suggested-action");
        
        auto selectBox = new gtk.box.Box(Orientation.Vertical, 12);
        selectBox.setVexpand(true);
        selectBox.append(pageSelect);
        selectBox.append(btnSelect);
        selectBox.setValign(Align.Center);
        
        stack.addNamed(selectBox, "select");

        // --- Variabili di stato per l'operazione ---
        string currentInputFile = "";
        string currentOutputFile = "";
        string currentOutputDir = "";
        bool currentIsDecrypt = false;
        string currentActionFile = "";
        bool currentActionIsDecrypt = false;
        GPG currentGpg = null;

        // --- Page 2: Config / Password ---
        auto configBox = new gtk.box.Box(Orientation.Vertical, 12);
        configBox.setValign(Align.Center);
        
        auto lblConfigTitle = new gtk.label.Label(""); // Impostato dinamicamente sotto
        lblConfigTitle.addCssClass("title-1");
        lblConfigTitle.setMarginBottom(12);

        auto lblOp = new gtk.label.Label(_(Msg.action_label));
        lblOp.setHalign(Align.Start);
        lblOp.addCssClass("dim-label");

        auto opCombo = new gtk.combo_box_text.ComboBoxText();
        opCombo.append("encrypt", _(Msg.op_encrypt));
        opCombo.append("decrypt", _(Msg.op_decrypt));
        opCombo.setHalign(Align.Fill);

        auto lblOut = new gtk.label.Label(_(Msg.dest_label));
        lblOut.setHalign(Align.Start);
        lblOut.addCssClass("dim-label");
        
        auto entryOutputFile = new gtk.entry.Entry();
        entryOutputFile.setPlaceholderText(_(Msg.dest_placeholder));
        entryOutputFile.setHexpand(true);
        
        auto btnSelectOut = new gtk.button.Button();
        btnSelectOut.setIconName("document-save-symbolic");

        auto outBox = new gtk.box.Box(Orientation.Horizontal, 6);
        outBox.setHalign(Align.Fill);
        outBox.append(entryOutputFile);
        outBox.append(btnSelectOut);

        auto lblPwd = new gtk.label.Label(_(Msg.pwd_label));
        lblPwd.setHalign(Align.Start);
        lblPwd.addCssClass("dim-label");
        
        auto pwdEntry = new gtk.password_entry.PasswordEntry();
        pwdEntry.setHalign(Align.Fill);
        pwdEntry.setMarginBottom(12);
        
        auto btnConfigBox = new gtk.box.Box(Orientation.Horizontal, 12);
        btnConfigBox.setHomogeneous(true);
        btnConfigBox.setHalign(Align.Center);
        
        auto btnCancelConfig = new gtk.button.Button();
        btnCancelConfig.setLabel(_(Msg.cancel_btn));
        btnCancelConfig.setSizeRequest(140, -1);

        auto btnStart = new gtk.button.Button();
        btnStart.setLabel(_(Msg.start_btn));
        btnStart.setSizeRequest(140, -1);
        btnStart.setSensitive(false);
        

        timeoutAdd(0, 100, cast(SourceFunc) delegate bool() {
            string outName = entryOutputFile.getText();
            bool isValid = false;
            
            if (outName.length > 0) {
                if (isAbsolute(outName)) {
                    string dn = dirName(outName);
                    isValid = exists(dn) && isDir(dn) && (!exists(outName) || !isDir(outName));
                    
                } else {
                    // It's a filename, it must not contain slashes
                    bool isJustFilename = (baseName(outName) == outName);
                    isValid = isJustFilename && exists(currentOutputDir) && isDir(currentOutputDir);
                    

                    // The combined path must not be an existing directory
                    if (isValid) {
                        string combined = buildPath(currentOutputDir, outName);
                        if (exists(combined) && isDir(combined)) isValid = false;
                    }
                }
            }

            bool v = pwdEntry.getText().length > 0 && outName.length > 0 && isValid;
            btnStart.setSensitive(v);
            if (v) btnStart.addCssClass("suggested-action");
            else btnStart.removeCssClass("suggested-action");
            return true;
        });

        btnConfigBox.append(btnCancelConfig);
        btnConfigBox.append(btnStart);

        configBox.append(lblConfigTitle);
        configBox.append(lblOp);
        configBox.append(opCombo);
        configBox.append(lblOut);
        configBox.append(outBox);
        configBox.append(lblPwd);
        configBox.append(pwdEntry);
        configBox.append(btnConfigBox);

        stack.addNamed(configBox, "config");
        
        // --- Page: Confirm Overwrite ---
        auto pageConfirm = new adw.status_page.StatusPage();
        pageConfirm.setTitle(_(Msg.confirm_title));
        pageConfirm.setDescription(_(Msg.confirm_desc));
        pageConfirm.setIconName("dialog-warning-symbolic");
        
        auto btnConfirmYes = new gtk.button.Button();
        btnConfirmYes.setLabel(_(Msg.confirm_yes));
        btnConfirmYes.setSizeRequest(140, -1);
        btnConfirmYes.addCssClass("destructive-action");
        
        auto btnConfirmNo = new gtk.button.Button();
        btnConfirmNo.setLabel(_(Msg.cancel_btn));
        btnConfirmNo.setSizeRequest(140, -1);
        
        auto confirmBtns = new gtk.box.Box(Orientation.Horizontal, 12);
        confirmBtns.setHomogeneous(true);
        confirmBtns.setHalign(Align.Center);
        confirmBtns.append(btnConfirmNo);
        confirmBtns.append(btnConfirmYes);
        
        auto confirmBox = new gtk.box.Box(Orientation.Vertical, 12);
        confirmBox.append(pageConfirm);
        confirmBox.append(confirmBtns);
        confirmBox.setValign(Align.Center);
        
        stack.addNamed(confirmBox, "confirm");

        // --- Page 3: Progress ---
        auto pageProgress = new adw.status_page.StatusPage();
        pageProgress.setTitle(_(Msg.progress_title_generic));
        pageProgress.setIconName("view-refresh-symbolic");
        
        auto progressBar = new gtk.progress_bar.ProgressBar();
        progressBar.setHalign(Align.Fill);
        
        auto btnCancelProgress = new gtk.button.Button();
        btnCancelProgress.setLabel(_(Msg.cancel_btn));
        btnCancelProgress.setSizeRequest(140, -1);
        btnCancelProgress.setHalign(Align.Center);
        btnCancelProgress.setMarginTop(24);
        btnCancelProgress.addCssClass("destructive-action");

        auto progressBox = new gtk.box.Box(Orientation.Vertical, 12);
        progressBox.append(pageProgress);
        progressBox.append(progressBar);
        progressBox.append(btnCancelProgress);
        progressBox.setValign(Align.Center);
        
        stack.addNamed(progressBox, "progress");

        // --- Page 4: Done ---
        auto pageDone = new adw.status_page.StatusPage();
        pageDone.setTitle(_(Msg.done_title));
        pageDone.setIconName("object-select-symbolic"); 
        
        auto btnAction = new gtk.button.Button();
        btnAction.addCssClass("suggested-action");
        btnAction.setSizeRequest(140, -1);
        
        btnAction.connectClicked((gtk.button.Button btn) {
            import gtk.file_launcher;
            import gio.file;
            auto launcher = new gtk.file_launcher.FileLauncher(gio.file.File.newForPath(currentActionFile));
            if (currentActionIsDecrypt) {
                launcher.launch(win, null, null);
            } else {
                launcher.openContainingFolder(win, null, null);
            }
        });
        
        auto btnRestart = new gtk.button.Button();
        btnRestart.setLabel(_(Msg.restart_btn));
        btnRestart.setSizeRequest(140, -1);
        
        auto doneButtons = new gtk.box.Box(Orientation.Horizontal, 12);
        doneButtons.setHalign(Align.Center);
        doneButtons.append(btnAction);
        doneButtons.append(btnRestart);
        
        auto doneBox = new gtk.box.Box(Orientation.Vertical, 12);
        doneBox.append(pageDone);
        doneBox.append(doneButtons);
        doneBox.setValign(Align.Center);

        stack.addNamed(doneBox, "done");

        // --- Logic: Handle File ---
        void handleFile(string filepath) {
            currentInputFile = filepath;
            
            import std.string : indexOf;
            // If the file comes from the Document Portal, we shouldn't use its dir as output default
            // because portal directories are usually read-only/ephemeral for new files.
            if (filepath.indexOf("/run/user/") >= 0 && filepath.indexOf("/doc/") >= 0) {
                import std.process : environment;
                currentOutputDir = environment.get("HOME", "/tmp");
            } else {
                currentOutputDir = dirName(filepath);
            }
            
            pwdEntry.setText("");
            
            if (extension(filepath) == ".gpg") {
                opCombo.setActiveId("decrypt");
                entryOutputFile.setText(baseName(stripExtension(filepath)));
                lblConfigTitle.setLabel(_(Msg.title_decrypt_file));
            } else {
                opCombo.setActiveId("encrypt");
                entryOutputFile.setText(baseName(filepath) ~ ".gpg");
                lblConfigTitle.setLabel(_(Msg.title_encrypt_file));
            }
            
            stack.setVisibleChildName("config");
        }

        // --- Logic: Drop Target ---
        import gtk.drop_target;
        import gobject.value;
        import gdk.types;
        import gdk.file_list;
        
        auto dropTarget = new gtk.drop_target.DropTarget(gdk.file_list.FileList._getGType(), gdk.types.DragAction.Copy);
        dropTarget.connectDrop((gobject.value.Value value, double x, double y, gtk.drop_target.DropTarget dt) {
            import std.typecons : No;
            void* boxedData = value.getBoxed();
            if (boxedData) {
                auto fl = new gdk.file_list.FileList(boxedData, No.Take);
                if (fl) {
                    auto files = fl.getFiles();
                    if (files.length > 0) {
                        handleFile(files[0].getPath());
                        return true;
                    }
                }
            }
            return false;
        });
        win.addController(dropTarget);


        // --- Logic: Connect Signals ---

        opCombo.connectChanged((gtk.combo_box_text.ComboBoxText combo) {
            if (currentInputFile.length == 0) return;
            string op = combo.getActiveId();
            if (op == "decrypt") {
                if (extension(currentInputFile) == ".gpg") {
                    entryOutputFile.setText(baseName(stripExtension(currentInputFile)));
                } else {
                    entryOutputFile.setText(baseName(currentInputFile) ~ ".decrypted");
                }
                btnStart.setLabel(_(Msg.btn_decrypt));
                lblConfigTitle.setLabel(_(Msg.title_decrypt_file));
            } else {
                entryOutputFile.setText(baseName(currentInputFile) ~ ".gpg");
                btnStart.setLabel(_(Msg.btn_encrypt));
                lblConfigTitle.setLabel(_(Msg.title_encrypt_file));
            }
        });

        void checkPathSplit() {
            string text = entryOutputFile.getText();
            if (text.length > 1 && isAbsolute(text) && text != "/") {
                string dir = dirName(text);
                string base = baseName(text);
                if (exists(dir) && isDir(dir)) {
                    currentOutputDir = dir;
                    entryOutputFile.setText(base);
                }
            }
        }

        entryOutputFile.connectActivate((gtk.entry.Entry entry) => checkPathSplit());

        import gtk.event_controller_focus;
        auto focusController = new gtk.event_controller_focus.EventControllerFocus();
        focusController.connectLeave((gtk.event_controller_focus.EventControllerFocus ec) => checkPathSplit());
        entryOutputFile.addController(focusController);

        btnSelect.connectClicked((gtk.button.Button btn) {
            import gobject.object;
            import gio.async_result;
            auto dialog = new gtk.file_dialog.FileDialog();
            dialog.open(win, null, (gobject.object.ObjectWrap src, gio.async_result.AsyncResult res) {
                try {
                    auto file = dialog.openFinish(res);
                    if (file) handleFile(file.getPath());
                } catch (Exception e) {}
            });
        });

        btnSelectOut.connectClicked((gtk.button.Button btn) {
            import gobject.object;
            import gio.async_result;
            auto dialog = new gtk.file_dialog.FileDialog();
            checkPathSplit();
            if (currentOutputDir.length > 0 && exists(currentOutputDir)) {
                dialog.setInitialFolder(gio.file.File.newForPath(currentOutputDir));
            }
            dialog.setInitialName(entryOutputFile.getText());
            dialog.save(win, null, (gobject.object.ObjectWrap src, gio.async_result.AsyncResult res) {
                try {
                    auto file = dialog.saveFinish(res);
                    if (file) {
                        currentOutputDir = dirName(file.getPath());
                        entryOutputFile.setText(baseName(file.getPath()));
                    }
                } catch (Exception e) {}
            });
        });

        btnCancelConfig.connectClicked((gtk.button.Button btn) {
            stack.setVisibleChildName("select");
            currentInputFile = "";
        });
        
        btnConfirmNo.connectClicked((gtk.button.Button btn) {
            stack.setVisibleChildName("config");
        });

        void startGpgProcess(string pwd, string outputFile, bool decrypt) {
            stack.setVisibleChildName("progress");
            progressBar.setFraction(0.0);
            pageProgress.setTitle(decrypt ? _(Msg.op_decrypt) : _(Msg.op_encrypt));
            pageProgress.setDescription(_(Msg.progress_desc));
            
            currentGpg = new GPG();
            
            new Thread({
                try {
                    currentGpg.passphrase(pwd);
                    currentGpg.inputFrom(currentInputFile);
                    currentGpg.outputTo(outputFile);
                    if (decrypt) currentGpg.decrypt();
                    else currentGpg.encrypt();
                    
                    currentGpg.wait((GPGProgress p) {
                        import std.format : format;
                        double fraction = p.totalInput > 0 ? cast(double)p.bytesWritten / p.totalInput : 0.0;
                        string pct = format(_(Msg.progress_pct), p.percent());
                        
                        idleAdd(0, cast(SourceFunc) delegate bool() {
                            progressBar.setFraction(fraction);
                            pageProgress.setDescription(pct);
                            return false; 
                        });
                    });
                    
                    currentGpg = null;

                    idleAdd(0, cast(SourceFunc) delegate bool() {
                        pageDone.setDescription(_(Msg.done_saved) ~ baseName(outputFile));
                        pageDone.setTitle(_(Msg.done_success));
                        pageDone.setIconName("object-select-symbolic");
                        
                        btnAction.setVisible(true);
                        if (decrypt) {
                            btnAction.setLabel(_(Msg.btn_open));
                        } else {
                            btnAction.setLabel(_(Msg.btn_show_folder));
                        }
                        currentActionFile = outputFile;
                        currentActionIsDecrypt = decrypt;
                        
                        stack.setVisibleChildName("done");
                        return false;
                    });
                    
                } catch (Exception ex) {
                    currentGpg = null;
                    string friendlyMsg = _(Msg.err_generic);
                    
                    if (auto gpgEx = cast(GPGException)ex) {
                        if (gpgEx.returnCode == 2) {
                            friendlyMsg = _(Msg.err_bad_password);
                        } else if (decrypt && gpgEx.stderr.indexOf("decryption failed") >= 0) {
                            friendlyMsg = _(Msg.err_corrupted);
                        } else if (gpgEx.returnCode < 0 || gpgEx.stderr.indexOf("cancelled") >= 0) {
                            friendlyMsg = _(Msg.err_cancelled);
                        } else {
                            friendlyMsg = _(Msg.err_code) ~ to!string(gpgEx.returnCode) ~ ").";
                        }
                    } else {
                        friendlyMsg = ex.msg; // Fallback
                    }

                    string m = friendlyMsg; // Capture alias for delegate
                    idleAdd(0, cast(SourceFunc) delegate bool() {
                        pageDone.setTitle(_(Msg.err_title));
                        pageDone.setDescription(m);
                        pageDone.setIconName("dialog-error-symbolic");
                        btnAction.setVisible(false);
                        stack.setVisibleChildName("done");
                        return false;
                    });
                }
            }).start();
        }
        
        btnConfirmYes.connectClicked((gtk.button.Button btn) {
            bool decrypt = (opCombo.getActiveId() == "decrypt");
            startGpgProcess(pwdEntry.getText(), currentOutputFile, decrypt);
        });

        btnCancelProgress.connectClicked((gtk.button.Button btn) {
            if (currentGpg !is null) {
                currentGpg.cancel();
            }
        });

        btnRestart.connectClicked((gtk.button.Button btn) {
            stack.setVisibleChildName("select");
            pwdEntry.setText("");
            currentInputFile = "";
        });

        btnStart.connectClicked((gtk.button.Button btn) {
            string pwd = pwdEntry.getText();
            string outName = entryOutputFile.getText();

            if (pwd.length == 0 || outName.length == 0) return;
            
            string outPath = buildPath(currentOutputDir, outName);
            currentOutputFile = outPath;

            if (exists(outPath)) {
                stack.setVisibleChildName("confirm");
            } else {
                bool decrypt = (opCombo.getActiveId() == "decrypt");
                startGpgProcess(pwd, outPath, decrypt);
            }
        });

        win.show();
        
        // Handle CLI arguments
        if (args.length > 1) {
            import std.file : exists;
            string inputPath = args[1];
            if (exists(inputPath)) {
                handleFile(inputPath);
            }
        }
    });
    
    return app.run([]);
}
