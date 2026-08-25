;;; init.el --- ORG-MCP config -*- lexical-binding: t; -*-

;;; Commentary:
;;; Code:

;; Don't bind C-i to tab
(define-key input-decode-map [?\C-i] [C-i])
;; Performance Hacks
;; Emacs is an Elisp interpreter, and when running programs or packages,
;; it can occasionally experience pauses due to garbage collection.
;; By increasing the garbage collection threshold, we reduce these pauses
;; during heavy operations, leading to smoother performance.
(setq gc-cons-threshold #x40000000)

;; Set the maximum output size for reading process output, allowing for larger data transfers.
(setq read-process-output-max (* 1024 1024 4))

;; Do I really need a speedy startup?
;; Well, this config launches Emacs in about ~0.3 seconds,
;; which, in modern terms, is a miracle considering how fast it starts
;; with external packages.
;; It wasn’t until the recent introduction of tools for lazy loading
;; that a startup time of less than 20 seconds was even possible.
;; Other fast startup methods were introduced over time.
;; You may have heard of people running Emacs as a server,
;; where you start it once and open multiple clients instantly connected to that server.
;; Some even run Emacs as a systemd or sysV service, starting when the machine boots.
;; While this is a great way of using Emacs, we WON’T be doing that here.
;; I think 0.3 seconds is fast enough to avoid issues that could arise from
;; running Emacs as a server, such as 'What version of Node is my LSP using?'.
;; Again, this setup configures Emacs much like how a Vimmer would configure Neovim.


;; Emacs comes with a built-in package manager (`package.el'), and we'll use it
;; when it makes sense. However, `straight.el' is a bit more user-friendly and
;; reproducible, especially for newcomers and shareable configs like emacs-kick.
;; So we bootstrap it here.
(setq package-enable-at-startup nil) ;; Disables the default package manager.

;; Bootstraps `straight.el'
(setq straight-check-for-modifications nil)
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))
(straight-use-package '(project :type built-in))
(straight-use-package 'use-package)


;; In Emacs, a package is a collection of Elisp code that extends the editor's functionality,
;; much like plugins do in Neovim. We need to import this package to add package archives.
(require 'package)

;; Add MELPA (Milkypostman's Emacs Lisp Package Archive) to the list of package archives.
;; This allows you to install packages from this widely-used repository, similar to how
;; pip works for Python or npm for Node.js. While Emacs comes with ELPA (Emacs Lisp
;; Package Archive) configured by default, which contains packages that meet specific
;; licensing criteria, MELPA offers a broader range of packages and is considered the
;; standard for Emacs users. You can also add more package archives later as needed.
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

;; From now on, you'll see configurations using the `use-package` macro, which
;; allows us to organize our Emacs setup in a modular way. These configurations
;; look like this:
;;
;; (use-package some-package
;;   :ensure t     ;; Ensure the package is installed (used with package.el).
;;   :straight t   ;; Use straight.el to install and manage this package.
;;   :config       ;; Configuration settings for the package.
;;   ;; Additional settings can go here.
;; )
;;
;; This approach simplifies package management, enabling us to easily control
;; both built-in (first-party) and external (third-party) packages. While Emacs
;; is a vast and powerful editor, using `use-package`—especially in combination
;; with `straight.el`—helps streamline our configuration for better organization,
;; reproducibility, and customization. As we proceed, you'll see smaller
;; `use-package` declarations for specific packages, which will help us enable
;; the desired features and improve our workflow.

;;; EMACS
;;  This is biggest one. Keep going, plugins (oops, I mean packages) will be shorter :)
(use-package emacs
  :ensure nil
  :custom                                         ;; Set custom variables to configure Emacs behavior.
  (confirm-kill-emacs 'yes-or-no-p)               ;; Ask before quitting Emacs
  (column-number-mode t)                          ;; Display the column number in the mode line.
  (auto-save-default nil)                         ;; Disable automatic saving of buffers.
  (create-lockfiles nil)                          ;; Prevent the creation of lock files when editing.
  (delete-by-moving-to-trash t)                   ;; Move deleted files to the trash instead of permanently deleting them.
  (delete-selection-mode 1)                       ;; Enable replacing selected text with typed text.
  (display-line-numbers-type 'relative)           ;; Use relative line numbering in programming modes.
  (global-auto-revert-non-file-buffers t)         ;; Automatically refresh non-file buffers.
  (history-length 100)                            ;; Set the length of the command history.
  (inhibit-startup-message t)                     ;; Disable the startup message when Emacs launches.
  (initial-scratch-message "")                    ;; Clear the initial message in the *scratch* buffer.
  (ispell-dictionary "en_US")                     ;; Set the default dictionary for spell checking.
  (make-backup-files nil)                         ;; Disable creation of backup files.
  (ring-bell-function 'ignore)                    ;; Disable the audible bell.
  (split-width-threshold 300)                     ;; Prevent automatic window splitting if the window width exceeds 300 pixels.
  (switch-to-buffer-obey-display-actions t)       ;; Make buffer switching respect display actions.
  (tab-always-indent 'complete)                   ;; Make the TAB key complete text instead of just indenting.
  (tab-width 4)                                   ;; Set the tab width to 4 spaces.
  (truncate-lines t)                              ;; Enable line truncation to avoid wrapping long lines.
  (use-dialog-box nil)                            ;; Disable dialog boxes in favor of minibuffer prompts.
  (use-short-answers t)                           ;; Use short answers in prompts for quicker responses (y instead of yes)
  (sentence-end-double-space nil)                 ;; It's no longer the 1980s, Emacs
  ;; (warning-minimum-level :emergency)              ;; Set the minimum level of warnings to display.
  :config
  ;; By default emacs gives you access to a lot of *special* buffers, while navigating with [b and ]b,
  ;; this might be confusing for newcomers. This settings make sure ]b and [b will always load a
  ;; file buffer. To see all buffers use <leader> SPC, <leader> b l, or <leader> b i.
  (defun skip-these-buffers (_window buffer _bury-or-kill)
    "Function for `switch-to-prev-buffer-skip'."
    (string-match "\\*[^*]+\\*" (buffer-name buffer)))
  (setq switch-to-prev-buffer-skip 'skip-these-buffers)


  ;; Save manual customizations to a separate file instead of cluttering `init.el'.
  ;; You can M-x customize, M-x customize-group, or M-x customize-themes, etc.
  ;; The saves you do manually using the Emacs interface would overwrite this file.
  ;; The following makes sure those customizations are in a separate file.
  (setq custom-file (locate-user-emacs-file "custom-vars.el")) ;; Specify the custom file path.
  (load custom-file 'noerror 'nomessage)                       ;; Load the custom file quietly, ignoring errors.

  ;; Makes Emacs vertical divisor the symbol │ instead of |.
  (set-display-table-slot standard-display-table 'vertical-border (make-glyph-code ?│))

  ;; Add a load-path entry for the user directory:
  (add-to-list 'load-path (locate-user-emacs-file "lisp") t)

  :init                        ;; Initialization settings that apply before the package is loaded.
  (tool-bar-mode -1)           ;; Disable the tool bar for a cleaner interface.
  (menu-bar-mode -1)           ;; Disable the menu bar for a more streamlined look.

  (global-display-line-numbers-mode +1) ;; Display line numbers everywhere
  (global-hl-line-mode 1)               ;; Enable highlight of the current line
  (global-auto-revert-mode 1)           ;; Enable global auto-revert mode to keep buffers up to date with their corresponding files.
  (indent-tabs-mode nil)                ;; Disable the use of tabs for indentation (use spaces instead).
  (recentf-mode 1)                      ;; Enable tracking of recently opened files.
  (savehist-mode 1)                     ;; Enable saving of command history.
  (save-place-mode 1)                   ;; Enable saving the place in files for easier return.
  (winner-mode 1)                       ;; Enable winner mode to easily undo window configuration changes.
  (xterm-mouse-mode 1)                  ;; Enable mouse support in terminal mode.
  (file-name-shadow-mode 1)             ;; Enable shadowing of filenames for clarity.

  ;; Set the default coding system for files to UTF-8.
  (modify-coding-system-alist 'file "" 'utf-8))


;;; DIRED
;; In Emacs, the `dired' package provides a powerful and built-in file manager
;; that allows you to navigate and manipulate files and directories directly
;; within the editor. If you're familiar with `oil.nvim', you'll find that
;; `dired' offers similar functionality natively in Emacs, making file
;; management seamless without needing external plugins.
;;
;; This configuration customizes `dired' to enhance its usability. The settings
;; below specify how file listings are displayed, the target for file operations,
;; and associations for opening various file types with their respective applications.
;; For example, image files will open with `feh', while audio and video files
;; will utilize `mpv'.
(use-package dired
  :ensure nil                                                ;; This is built-in, no need to fetch it.
  :custom
  (dired-listing-switches "-lah --group-directories-first")  ;; Display files in a human-readable format and group directories first.
  (dired-dwim-target t)                                      ;; Enable "do what I mean" for target directories.
  (dired-guess-shell-alist-user
   '(("\\.\\(png\\|jpe?g\\|tiff\\)" "feh" "xdg-open" "open") ;; Open image files with `feh' or the default viewer.
     ("\\.\\(mp[34]\\|m4a\\|ogg\\|flac\\|webm\\|mkv\\)" "mpv" "xdg-open" "open") ;; Open audio and video files with `mpv'.
     (".*" "open" "xdg-open")))                              ;; Default opening command for other files.
  (dired-kill-when-opening-new-dired-buffer t)               ;; Close the previous buffer when opening a new `dired' instance.
  :config
  (when (eq system-type 'darwin)
    (let ((gls (executable-find "gls")))                     ;; Use GNU ls on macOS if available.
      (when gls
        (setq insert-directory-program gls)))))


(use-package repeat
  :ensure nil
  :config
  (repeat-mode 1))


(use-package holidays
  :ensure nil
  :init
  ;; Disable unused holidays:
  (setq
   holiday-hebrew-holidays nil
   holiday-bahai-holidays nil
   holiday-islamic-holidays nil
   holiday-oriental-holidays nil)
  ;; Attach our custom holiday lists:
  (setq holiday-other-holidays
        '((holiday-float 11 4 3 "Thanksgiving Break")
          (holiday-float 11 4 5 "Thanksgiving Break")))
  ;; This gets overwritten somehow:
  (setq calendar-holidays (append holiday-general-holidays holiday-local-holidays
                                  holiday-other-holidays holiday-christian-holidays
                                  holiday-hebrew-holidays holiday-islamic-holidays
                                  holiday-bahai-holidays holiday-oriental-holidays
                                  holiday-solar-holidays))
  :config
  (with-eval-after-load 'org
    (setq org-agenda-include-diary t)))


;;; ISEARCH
;; In this configuration, we're setting up isearch, Emacs's incremental search feature.
;; Since we're utilizing Vim bindings, keep in mind that classic Vim search commands
;; (like `/' and `?') are not bound in the same way. Instead, you'll need to use
;; the standard Emacs shortcuts:
;; - `C-s' to initiate a forward search
;; - `C-r' to initiate a backward search
;; The following settings enhance the isearch experience:
(use-package isearch
  :ensure nil                                  ;; This is built-in, no need to fetch it.
  :config
  (setq isearch-lazy-count t)                  ;; Enable lazy counting to show current match information.
  (setq lazy-count-prefix-format "(%s/%s) ")   ;; Format for displaying current match count.
  (setq lazy-count-suffix-format nil)          ;; Disable suffix formatting for match count.
  (setq search-whitespace-regexp ".*?")        ;; Allow searching across whitespace.
  :bind (("C-s" . isearch-forward)             ;; Bind C-s to forward isearch.
         ("C-r" . isearch-backward)))          ;; Bind C-r to backward isearch.


;;; ==================== EXTERNAL PACKAGES ====================
;;
;; From this point onward, all configurations will be for third-party packages
;; that enhance Emacs' functionality and extend its capabilities.


;;; ORG MODE
;; A GNU Emacs major mode for keeping notes, authoring documents,
;; computational notebooks, literate programming, maintaining to-do
;; lists, planning projects, and more — in a fast and effective plain
;; text system.
(use-package org
  :straight (org :type git :host github :repo "emacs-straight/org-mode")
  :defer t
  :mode ("\\.org\\'" . org-mode)
  :commands (org-mode org-agenda org-capture)
  :hook ((org-mode . (lambda () (electric-indent-local-mode -1)))
         (org-mode  . turn-on-visual-line-mode)
         (org-agenda-mode . hl-line-mode)
         (org-agenda-mode . (lambda () (add-hook 'window-configuration-change-hook 'org-agenda-align-tags nil t)))
         (org-agenda-after-show . org-show-entry))
  :custom
  (org-beamer-mode t) ;; Export to beamer
  (org-catch-invisible-edits 'show)
  (org-complete-tags-always-offer-all-agenda-tags t) ;; Always use all tags from Agenda files in capture
  (org-edit-timestamp-down-means-later nil)
  (org-export-coding-system 'utf-8)
  (org-export-kill-product-buffer-when-displayed t)
  (org-fast-tag-selection-single-key 'expert)
  (org-hide-leading-stars nil)
  (org-html-validation-link nil)
  (org-imenu-depth 2)
  (org-indent-mode "noindent")
  (org-log-done t)
  (org-startup-indented nil)
  (org-support-shift-select t)
  (org-tags-column 50)
  (org-directory "~/org")
  (org-default-notes-file "~/org/inbox.org")
  ;; org-agenda:
  (org-agenda-files (list
                     "~/org/todo.org"
                     "~/org/inbox.org"))
  (org-agenda-compact-blocks t)
  (org-agenda-start-on-weekday 1)
  (org-agenda-span 7)
  (org-agenda-start-day nil)
  (org-agenda-include-diary t)
  (org-agenda-sorting-strategy
   '((agenda habit-down time-up effort-up category-keep)
     (todo category-up effort-up)
     (tags category-up effort-up)
     (search category-up)))
  (org-agenda-window-setup 'current-window)
  (org-agenda-custom-commands
   `(("N" "Notes" tags "NOTE"
      ((org-agenda-overriding-header "Notes")
       (org-tags-match-list-sublevels t)))))
  (setq-default org-agenda-clockreport-parameter-plist '(:link t :maxlevel 3))
  ;; org-archive:
  (org-archive-mark-done nil)
  (org-archive-location "%s_archive::* Archive")
  ;; org-capture:
  (org-capture-templates
   `(("t" "todo" entry (file+headline "" "Inbox") ; "" => `org-default-notes-file'
      "* TODO %?\n%t\n%i\n")))
  ;; org-refile:
  (org-refile-use-cache nil)
  (org-refile-targets '((nil :maxlevel . 5) (org-agenda-files :maxlevel . 5)))
  ;; Targets start with the file name - allows creating level 1 tasks
  (org-refile-use-outline-path t)
  (org-outline-path-complete-in-steps nil)
  ;; Allow refile to create parent tasks with confirmation
  (org-refile-allow-creating-parent-nodes 'confirm)
  ;; org-todo:
  (org-todo-keywords
   (quote ((sequence "TODO(t)" "|" "DONE(d!/!)")
           )))
  (org-todo-repeat-to-state "TODO")
  (org-todo-keyword-faces
   (quote (("NEXT" :inherit warning)
           ("PROJECT" :inherit font-lock-string-face))))
  (org-use-property-inheritance t) ;; Inherit properties from parents
  ;; org-cite:
  (org-cite-export-processors '((t csl)))
  (org-cite-csl-styles-dir "~/.csl")
  :config
  ;; Open file links in the same frame:
  (setf (alist-get 'file org-link-frame-setup) #'find-file)
  ;; Open .docx files using macOS/XDG open:
  (add-to-list 'org-file-apps `("\\.docx\\'" . ,(if (eq system-type 'darwin) "open %s" "xdg-open %s"))))


;;; ORG ROAM
;; Org-roam is a plain-text knowledge management system. It brings
;; some of Roam's more powerful features into the Org-mode ecosystem.
;;
;; Org-roam borrows principles from the Zettelkasten method, providing
;; a solution for non-hierarchical note-taking. It should also work as
;; a plug-and-play solution for anyone already using Org-mode for
;; their personal wiki.
(use-package org-roam
  :defer t
  :straight t
  :custom
  (org-roam-capture-templates
   '(("d" "default" plain
	  "%?"
	  :target
	  (file+head
	   "%<%Y%m%d%H%M%S>-${slug}.org"
	   "#+title: ${title}\n")
	  :unnarrowed t)))
  (org-roam-directory "~/org/org-roam")
  :config
  ;; If you're using a vertical completion framework, you might want a more informative completion interface
  (setq org-roam-node-display-template (concat "${title:*} " (propertize "${tags:10}" 'face 'org-tag)))
  (org-roam-db-autosync-mode))


(use-package org-mcp
             :straight t
             :defer nil
             :custom
             (org-mcp-allowed-files org-agenda-files)
             :hook
             (after-init . mcp-server-lib-start))


(provide 'init)
;;; init.el ends here
