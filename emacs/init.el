;; ================================
;; Enable MELPA
;; ================================
(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)


;; ================================
;; Appearance
;; ================================
;; Syntax highlighting
(setq modus-themes-common-palette-overrides
      '((builtin green-cooler)
        (comment yellow-faint)
        (constant magenta-cooler)
        (fnname cyan-cooler)
        (keyword blue-warmer)
        (preprocessor red-warmer)
        (docstring cyan-faint)
        (string blue-cooler)
        (type magenta-cooler)
        (variable cyan)))

(load-theme 'vscode-dark-plus t)


;; ================================
;; PDF 
;; ================================
;; Higher-resolution PDF rendering
(setq doc-view-resolution 200)

;; Re-render PDF when zooming instead of scaling the existing bitmap
(setq doc-view-scale-internally nil)


;; ================================
;; Avoid automatically splitting the current view for new buffers.
;; ================================
(setq pop-up-windows nil)
(with-eval-after-load 'dired
  (define-key dired-mode-map [mouse-2] #'dired-mouse-find-file))
  

;; ================================
;; Move the cursor/focus between split windows
;; ================================ 
;; C-x 0    delete current window
;; C-x 1    keep only current window
;; C-x 2    split top/bottom
;; C-x 3    split left/right
(global-set-key (kbd "M-<left>")  #'windmove-left)
(global-set-key (kbd "M-<right>") #'windmove-right)
(global-set-key (kbd "M-<up>")    #'windmove-up)
(global-set-key (kbd "M-<down>")  #'windmove-down)



;; ================================
;; Welcome Dashboard
;; ================================

;; Load dashboard FIRST.
(require 'dashboard)
(require 'dashboard-widgets)


;; ================================
;; Recent Dired Directories
;; ================================

(require 'savehist)

(defvar my-recent-dired-directories nil)

(add-to-list 'savehist-additional-variables
             'my-recent-dired-directories)

(savehist-mode 1)

(defun my-remember-dired-directory ()
  (let ((dir (file-name-as-directory
              (expand-file-name default-directory))))
    ;; Move the current directory to the front.
    (setq my-recent-dired-directories
          (cons dir
                (delete dir my-recent-dired-directories)))

    ;; Keep at most 20 directories.
    (when (> (length my-recent-dired-directories) 20)
      (setcdr (nthcdr 19 my-recent-dired-directories) nil))))

(add-hook 'dired-mode-hook #'my-remember-dired-directory)


;; Dashboard widget for recent Dired directories.
(defun dashboard-insert-recent-dirs (list-size)
  (dashboard-insert-section
   "Recent Directories:"
   my-recent-dired-directories
   list-size
   'recent-dirs
   nil
   `(lambda (&rest _)
      (dired ,el))
   (propertize (abbreviate-file-name el)
               'dashboard-path el)))

;; Register our custom dashboard section.
(add-to-list 'dashboard-item-generators
             '(recent-dirs . dashboard-insert-recent-dirs))


;; ================================
;; Dashboard Appearance
;; ================================

(setq dashboard-banner-logo-title "Welcome to Emacs")
(setq dashboard-startup-banner 'official)

(setq dashboard-center-content t)
(setq dashboard-vertically-center-content t)

(setq dashboard-items
      '((recent-dirs . 8)))

(setq dashboard-show-shortcuts nil)


;; Remove footer sentence.
(setq dashboard-startupify-list
      '(dashboard-insert-banner
        dashboard-insert-newline
        dashboard-insert-banner-title
        dashboard-insert-newline
        dashboard-insert-init-info
        dashboard-insert-items))


;; Enable dashboard at startup.
(dashboard-setup-startup-hook)

;; Add a hotkey "C-c d" for returning to the welcome page.
(global-set-key (kbd "C-c d") #'dashboard-open)

;; Bind a key "<backspace>" to return to the parent folder.
(with-eval-after-load 'dired
  (define-key dired-mode-map (kbd "<backspace>") #'dired-up-directory))



 
  
;; ================================
;; Open Videos Externally in Dired
;; ================================

(defun my-video-file-p (file)
  "Return non-nil if FILE looks like a video."
  (let ((ext (downcase (or (file-name-extension file) ""))))
    (member ext
            '("mp4" "mkv" "avi" "mov" "webm"
              "m4v" "mpg" "mpeg" "wmv" "flv"
              "ts" "mts" "m2ts"))))

(defun my-dired-open-file ()
  (interactive)
  (let ((file (dired-get-file-for-visit)))
    (cond
     ;; Directory -> enter normally
     ((file-directory-p file)
      (dired-find-file))

     ;; Video
     ((my-video-file-p file)
      (my-play-video file))

     ;; Everything else -> Emacs
     (t
      (dired-find-file)))))

(with-eval-after-load 'dired
  (define-key dired-mode-map (kbd "RET") #'my-dired-open-file))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages '(corfu dashboard vscode-dark-plus-theme vterm)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
 
 
 
;; ================================
;; Conda Environment Management
;; ================================

(require 'conda)

(conda-env-initialize-interactive-shells)


(defun my-conda-select-environment ()
  "Select or deactivate a Conda environment."
  (interactive)
  (let* ((envs (conda-env-candidates))
         (choices (append envs '("[Deactivate]")))
         (choice
          (completing-read
           "Conda environment: "
           choices nil t nil nil
           conda-env-current-name)))

    (if (string= choice "[Deactivate]")
        (conda-env-deactivate)
      (conda-env-activate choice))

    (force-mode-line-update t)))

;; Use one command for both local and TRAMP buffers.
;; The remote selector is defined later in this file; that is fine because
;; this function is only called interactively after init.el finishes loading.
(defun my-conda-select-environment-smart ()
  "Select the Conda environment for the current context.
Use the remote host's Conda environments in a TRAMP buffer; otherwise use
the local Conda environments managed by conda.el."
  (interactive)
  (if (file-remote-p default-directory)
      (my-tramp-select-conda-environment)
    (my-conda-select-environment)))

(global-set-key (kbd "C-c e") #'my-conda-select-environment-smart)


;; Clickable mode-line entry.
(defvar my-conda-mode-line-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mode-line mouse-1]
                #'my-conda-select-environment-smart)
    map))


(defun my-conda-prefix-display-name (prefix)
  "Return a short display name for a Conda PREFIX."
  (cond
   ((not prefix) "none")
   ((string-match "/envs/\\([^/]+\\)/?\\'" prefix)
    (match-string 1 prefix))
   (t "base")))

(defun my-conda-mode-line-text ()
  (let ((name
         (if (file-remote-p default-directory)
             ;; my-tramp-conda-prefix is defined later in this file.
             (if (fboundp 'my-tramp-conda-prefix)
                 (my-conda-prefix-display-name
                  (my-tramp-conda-prefix))
               "none")
           (or conda-env-current-name "none"))))
    (propertize
     (format " Conda:%s " name)
     'help-echo
     (if (file-remote-p default-directory)
         "Click to select Conda environment on this remote host"
       "Click to select local Conda environment")
     'mouse-face 'mode-line-highlight
     'local-map my-conda-mode-line-map)))


;; Always display the Conda selector in the mode line.
(add-to-list
 'global-mode-string
 '(:eval (my-conda-mode-line-text))
 t)
 
 
 
;; ================================
;; Python Autocompletion
;; ================================

(require 'eglot)
(require 'corfu)

;; Popup completion UI
(setq corfu-auto t
      corfu-auto-delay 0.15
      corfu-auto-prefix 2)

(global-corfu-mode 1)

;; Start Eglot automatically for Python files.
(add-hook 'python-mode-hook #'eglot-ensure)
(add-hook 'python-ts-mode-hook #'eglot-ensure)


(defun my-conda-restart-eglot ()
  "Restart Python Eglot servers after changing Conda environment."
  (let (python-buffers servers)

    ;; Find Python buffers currently managed by Eglot.
    (dolist (buf (buffer-list))
      (with-current-buffer buf
        (when (and (derived-mode-p 'python-mode 'python-ts-mode)
                   (eglot-current-server))
          (push buf python-buffers)
          (push (eglot-current-server) servers))))

    ;; A single Eglot server can manage multiple buffers,
    ;; so only shut down each server once.
    (setq servers (delete-dups servers))

    ;; Completely shut down the old language servers.
    (dolist (server servers)
      (eglot-shutdown server))

    ;; Start Eglot again using the newly activated Conda environment.
    (dolist (buf python-buffers)
      (when (buffer-live-p buf)
        (with-current-buffer buf
          (eglot-ensure))))))


(add-hook 'conda-postactivate-hook #'my-conda-restart-eglot)
(add-hook 'conda-postdeactivate-hook #'my-conda-restart-eglot)



;; ================================
;; Always create new windows rather than replicate.
;; ================================
(defun my-split-window-below ()
  "Split below and show a different buffer in the new window."
  (interactive)
  (split-window-below)
  (other-window 1)
  (switch-to-buffer (other-buffer)))

(defun my-split-window-right ()
  "Split right and show a different buffer in the new window."
  (interactive)
  (split-window-right)
  (other-window 1)
  (switch-to-buffer (other-buffer)))

(global-set-key (kbd "C-x 2") #'my-split-window-below)
(global-set-key (kbd "C-x 3") #'my-split-window-right)




;; ================================
;; VTerm + Conda
;; ================================

(require 'vterm)

;; Automatically activate the currently selected Conda environment
;; in newly created vterm buffers.
(conda-env-initialize-vterm)


;; ================================
;; Codex
;; ================================

(defun my-open-codex ()
  "Open Codex in an independent vterm window on the right."
  (interactive)

  (let* ((dir default-directory)
         (buffer-name
          (generate-new-buffer-name "*codex*")))

    ;; Create an independent window on the right.
    (select-window (split-window-right))

    ;; Start vterm in the directory of the current buffer.
    (let ((default-directory dir))
      (vterm buffer-name))

    ;; Give vterm/Conda a moment to initialize,
    ;; then start Codex.
    (run-with-timer
     0.3 nil
     (lambda (buf)
       (when (buffer-live-p buf)
         (with-current-buffer buf
           (vterm-send-string "codex")
           (vterm-send-return))))
     (current-buffer))))


(global-set-key (kbd "C-c x") #'my-open-codex)



;; ================================
;; Open vterm with current Conda env
;; ================================

(require 'vterm)

;; Let new vterm buffers inherit the selected Conda environment.
(conda-env-initialize-vterm)

(defun my-open-terminal ()
  "Open an independent vterm on the right with the current Conda environment."
  (interactive)
  (let ((dir default-directory)
        (buffer-name
         (generate-new-buffer-name
          (format "*vterm:%s*"
                  (or conda-env-current-name "none")))))

    ;; Create an independent right-side window.
    (select-window (split-window-right))

    ;; Start vterm in the same working directory.
    (let ((default-directory dir))
      (vterm buffer-name))))

(global-set-key (kbd "C-c t") #'my-open-terminal)



;; ================================
;; Mouse window resizing
;; ================================

(setq window-divider-default-places t
      window-divider-default-right-width 4
      window-divider-default-bottom-width 4)

(window-divider-mode 1)



;; ================================
;; Python syntax highlighting
;; ================================
(add-to-list 'treesit-language-source-alist
             '(python
               "https://github.com/tree-sitter/tree-sitter-python"
               "v0.23.6"))
(add-to-list 'major-mode-remap-alist
             '(python-mode . python-ts-mode))
(setq treesit-font-lock-level 4)



;; ================================
;; TRAMP remote videos -> local mpv
;; ================================

(require 'tramp)

(defun my-video-file-p (file)
  "Return non-nil if FILE looks like a video."
  (let ((ext (downcase (or (file-name-extension file) ""))))
    (member ext
            '("mp4" "mkv" "avi" "mov" "webm"
              "m4v" "mpg" "mpeg" "wmv" "flv"
              "ts" "mts" "m2ts"))))


(defun my-tramp-to-sftp-url (file)
  "Convert TRAMP FILE into an SFTP URL."
  (let* ((vec  (tramp-dissect-file-name file))
         (user (tramp-file-name-user vec))
         (host (tramp-file-name-host vec))
         (port (tramp-file-name-port vec))
         (path (tramp-file-name-localname vec)))
    (format "sftp://%s%s%s%s"
            (if user (concat user "@") "")
            host
            (if port (format ":%s" port) "")
            path)))


(defun my-play-video (file)
  "Play FILE with local mpv."
  (let ((target
         (if (file-remote-p file)
             (my-tramp-to-sftp-url file)
           file)))

    ;; Force mpv to launch locally.
    (let ((default-directory temporary-file-directory))
      (start-process "mpv" nil "mpv" target))))


(defun my-dired-open-file ()
  "Open Dired entry, sending videos to mpv."
  (interactive)

  (let ((file (dired-get-file-for-visit)))
    (cond

     ;; Directory
     ((file-directory-p file)
      (dired-find-file))

     ;; Video
     ((my-video-file-p file)
      (my-play-video file))

     ;; Everything else
     (t
      (dired-find-file)))))


(with-eval-after-load 'dired
  (define-key dired-mode-map (kbd "RET")
              #'my-dired-open-file))
              
              
              
;; ================================
;; TRAMP + Remote Conda + Eglot
;; ================================

(require 'tramp)
(require 'json)
(require 'eglot)

;; Remember one selected Conda environment for each remote connection.
(defvar my-tramp-conda-envs nil)


(defun my-tramp-command-output (program &rest args)
  "Run PROGRAM remotely and return its output."
  (let ((dir default-directory))
    (with-temp-buffer
      (let ((default-directory dir))
        (let ((status
               (apply #'process-file program nil t nil args)))
          (unless (zerop status)
            (error "Remote command failed: %s" program))
          (string-trim (buffer-string)))))))


(defun my-tramp-find-conda ()
  "Find Conda executable on the current remote machine."
  (unless (file-remote-p default-directory)
    (user-error "Current buffer is not remote"))

  (let ((conda
         (my-tramp-command-output
          "sh" "-lc"
          (concat
           "command -v conda 2>/dev/null || "
           "for p in "
           "\"$HOME/miniconda3/bin/conda\" "
           "\"$HOME/anaconda3/bin/conda\" "
           "\"$HOME/miniforge3/bin/conda\" "
           "\"$HOME/mambaforge/bin/conda\"; "
           "do "
           "[ -x \"$p\" ] && echo \"$p\" && break; "
           "done"))))
    (if (string-empty-p conda)
        (user-error "Cannot find Conda on remote server")
      conda)))


(defun my-tramp-conda-prefix ()
  "Return selected Conda prefix for current remote server."
  (cdr (assoc (file-remote-p default-directory)
              my-tramp-conda-envs)))


(defun my-tramp-select-conda-environment ()
  "Select a Conda environment on the current TRAMP host."
  (interactive)

  (unless (file-remote-p default-directory)
    (user-error "Current buffer is not remote"))

  (let* ((key (file-remote-p default-directory))
         (conda (my-tramp-find-conda))
         (json-object-type 'alist)
         (json-array-type 'list)

         (data
          (json-read-from-string
           (my-tramp-command-output
            conda "env" "list" "--json")))

         (envs (alist-get 'envs data))

         (choices
          (mapcar
           (lambda (env)
             (cons
              (format "%s  [%s]"
                      (my-conda-prefix-display-name env)
                      env)
              env))
           envs))

         (choice
          (completing-read
           "Remote Conda environment: "
           choices nil t))

         (prefix (cdr (assoc choice choices))))

    ;; Remember selection for this remote host.
    (setq my-tramp-conda-envs
          (cons
           (cons key prefix)
           (assoc-delete-all key my-tramp-conda-envs)))

    (message "Remote Conda: %s" prefix)
    (force-mode-line-update t)

    ;; If Eglot is already running, completely restart it.
    (when-let ((server (eglot-current-server)))
      (eglot-shutdown server)
      (eglot-ensure))))


(defun my-python-eglot-server (&rest _)
  "Return the correct pylsp command for local or remote Python."
  (if (file-remote-p default-directory)

      ;; Remote Python
      (let ((prefix (my-tramp-conda-prefix))
            (conda (my-tramp-find-conda)))

        ;; Ask for an environment the first time.
        (unless prefix
          (call-interactively #'my-tramp-select-conda-environment)
          (setq prefix (my-tramp-conda-prefix)))

        ;; Run pylsp inside the selected remote Conda environment.
        (list conda
              "run"
              "--no-capture-output"
              "-p" prefix
              "pylsp"))

    ;; Local Python
    '("pylsp")))


;; Tell Eglot how to start Python.
(with-eval-after-load 'eglot
  (add-to-list
   'eglot-server-programs
   `((python-mode python-ts-mode)
     . ,#'my-python-eglot-server)))


;; Start Eglot automatically.
(add-hook 'python-mode-hook #'eglot-ensure)
(add-hook 'python-ts-mode-hook #'eglot-ensure)
