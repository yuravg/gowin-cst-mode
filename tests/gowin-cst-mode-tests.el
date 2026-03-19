;;; gowin-cst-mode-tests.el --- Tests for gowin-cst-mode -*- lexical-binding: t; -*-

;;; Commentary:
;; ERT tests for gowin-cst-mode.

;;; Code:

(require 'ert)
(require 'imenu)
(require 'gowin-cst-mode)

;;; Helpers

(defmacro gowin-cst-test-with-buffer (content &rest body)
  "Execute BODY in a temp buffer with CONTENT in `gowin-cst-mode'."
  (declare (indent 1))
  `(with-temp-buffer
     (insert ,content)
     (gowin-cst-mode)
     (font-lock-ensure)
     (goto-char (point-min))
     ,@body))

(defun gowin-cst-test-face-at (pos)
  "Return the face at POS after font-lock."
  (get-text-property pos 'face))

;;; Mode activation

(ert-deftest gowin-cst-mode-activates ()
  "Mode activates and sets correct major mode."
  (gowin-cst-test-with-buffer ""
                              (should (eq major-mode 'gowin-cst-mode))))

(ert-deftest gowin-cst-auto-mode-alist ()
  "The .cst extension is registered in auto-mode-alist."
  (should (assoc "\\.cst\\'" auto-mode-alist)))

;;; Comments

(ert-deftest gowin-cst-comment-start ()
  "Comment start is set to // ."
  (gowin-cst-test-with-buffer ""
                              (should (equal comment-start "// "))))

(ert-deftest gowin-cst-comment-syntax ()
  "// comments are recognized by the syntax table."
  (gowin-cst-test-with-buffer "// this is a comment\n"
                              (should (nth 4 (syntax-ppss 5)))))

(ert-deftest gowin-cst-block-comment-inline ()
  "/* */ inline block comments are recognized by the syntax table."
  (gowin-cst-test-with-buffer "IO_LOC /* comment */ \"led\" M11;\n"
                              (search-forward "/* ")
                              (should (nth 4 (syntax-ppss (point))))))

(ert-deftest gowin-cst-block-comment-multiline ()
  "Multi-line /* */ block comments are recognized by the syntax table."
  (gowin-cst-test-with-buffer "/*\ncommented text\n*/\n"
                              (search-forward "commented")
                              (should (nth 4 (syntax-ppss (point))))))

(ert-deftest gowin-cst-block-comment-inline-code-around ()
  "Code before and after /* */ block comment is not treated as comment."
  (gowin-cst-test-with-buffer "IO_LOC /* comment */ \"led\" M11;\n"
                              ;; 'IO_LOC' at position 1 should not be in a comment
                              (should-not (nth 4 (syntax-ppss 1)))
                              ;; text after */ should not be in a comment
                              (search-forward "*/")
                              (let ((pos-after (point)))
                                (should-not (nth 4 (syntax-ppss pos-after))))))

;;; Font-lock: keywords

(ert-deftest gowin-cst-fontify-keyword-io-loc ()
  "IO_LOC is highlighted as keyword."
  (gowin-cst-test-with-buffer "IO_LOC \"led\" M11;\n"
                              (should (eq (gowin-cst-test-face-at 1) 'font-lock-keyword-face))))

(ert-deftest gowin-cst-fontify-keyword-io-port ()
  "IO_PORT is highlighted as keyword."
  (gowin-cst-test-with-buffer "IO_PORT \"led\" IO_TYPE=LVCMOS33;\n"
                              (should (eq (gowin-cst-test-face-at 1) 'font-lock-keyword-face))))

;;; Font-lock: attributes

(ert-deftest gowin-cst-fontify-attribute ()
  "IO_TYPE is highlighted as type face."
  (gowin-cst-test-with-buffer "IO_PORT \"led\" IO_TYPE=LVCMOS33;\n"
                              (search-forward "IO_TYPE")
                              (should (eq (gowin-cst-test-face-at (match-beginning 0)) 'font-lock-type-face))))

;;; Font-lock: values

(ert-deftest gowin-cst-fontify-value ()
  "LVCMOS33 is highlighted as constant."
  (gowin-cst-test-with-buffer "IO_PORT \"led\" IO_TYPE=LVCMOS33;\n"
                              (search-forward "LVCMOS33")
                              (should (eq (gowin-cst-test-face-at (match-beginning 0)) 'font-lock-constant-face))))

;;; Font-lock: numbers

(ert-deftest gowin-cst-fontify-integer ()
  "Integer numbers are highlighted."
  (gowin-cst-test-with-buffer "DRIVE=8;\n"
                              (search-forward "8")
                              (should (eq (gowin-cst-test-face-at (match-beginning 0)) 'font-lock-number-face))))

(ert-deftest gowin-cst-fontify-decimal ()
  "Decimal numbers like 3.5 are highlighted."
  (gowin-cst-test-with-buffer "DRIVE=3.5;\n"
                              (search-forward "3.5")
                              (should (eq (gowin-cst-test-face-at (match-beginning 0)) 'font-lock-number-face))))

;;; Font-lock: strings

(ert-deftest gowin-cst-fontify-string ()
  "Quoted strings are highlighted via syntax table."
  (gowin-cst-test-with-buffer "IO_LOC \"led[0]\" M11;\n"
                              (search-forward "\"led")
                              (should (eq (gowin-cst-test-face-at (match-beginning 0)) 'font-lock-string-face))))

;;; Font-lock: pin locations

(ert-deftest gowin-cst-fontify-pin-location ()
  "Pin location after IO_LOC is highlighted."
  (gowin-cst-test-with-buffer "IO_LOC \"led\" M11;\n"
                              (search-forward "M11")
                              (should (eq (gowin-cst-test-face-at (match-beginning 0)) 'font-lock-builtin-face))))

(ert-deftest gowin-cst-fontify-pin-location-multi ()
  "Multiple comma-separated pin locations after IO_LOC are all highlighted."
  (gowin-cst-test-with-buffer "IO_LOC \"clk\" P13,N13;\n"
                              (search-forward "P13")
                              (should (eq (gowin-cst-test-face-at (match-beginning 0)) 'font-lock-builtin-face))
                              (search-forward "N13")
                              (should (eq (gowin-cst-test-face-at (match-beginning 0)) 'font-lock-builtin-face))))

(ert-deftest gowin-cst-fontify-pin-after-inline-comment ()
  "Pin location after inline /* comment */ is highlighted."
  (gowin-cst-test-with-buffer
   "IO_LOC  \"signal_name1\"  /* It's comment */   F14;\n"
   (search-forward "F14")
   (should (eq (gowin-cst-test-face-at (match-beginning 0)) 'font-lock-builtin-face))))

(ert-deftest gowin-cst-fontify-pin-after-inline-comment-with-trailing ()
  "Pin after inline comment with trailing comment is highlighted."
  (gowin-cst-test-with-buffer
   "IO_LOC  \"signal_name1\"  /* It's comment */   F14; /* It's comment */\n"
   (search-forward "F14")
   (should (eq (gowin-cst-test-face-at (match-beginning 0)) 'font-lock-builtin-face))))

(ert-deftest gowin-cst-fontify-multi-pin-after-inline-comment ()
  "Comma-separated pins after inline comment with trailing comment."
  (gowin-cst-test-with-buffer
   "IO_LOC \"tx_refclk_p\" /* It's comment */ A13,B13; /* It's comment */\n"
   (search-forward "A13")
   (should (eq (gowin-cst-test-face-at (match-beginning 0)) 'font-lock-builtin-face))
   (search-forward "B13")
   (should (eq (gowin-cst-test-face-at (match-beginning 0)) 'font-lock-builtin-face))))

(ert-deftest gowin-cst-fontify-pin-with-comment-between-keyword-and-signal ()
  "Pin highlighted when /* comment */ appears between IO_LOC and signal name."
  (gowin-cst-test-with-buffer
   "IO_LOC /* comm */ \"signal_name1\" F14;\n"
   (search-forward "F14")
   (should (eq (gowin-cst-test-face-at (match-beginning 0)) 'font-lock-builtin-face))))

(ert-deftest gowin-cst-fontify-pin-with-comments-everywhere ()
  "Pin highlighted with /* comments */ before IO_LOC, between keyword and signal, and after signal."
  (gowin-cst-test-with-buffer
   "/* It's comment */ IO_LOC /* It's comment */ \"signal_name1\" /* It's comment */ F14;\n"
   (search-forward "F14")
   (should (eq (gowin-cst-test-face-at (match-beginning 0)) 'font-lock-builtin-face))))

;;; Font-lock: IO_PORT with comments

(ert-deftest gowin-cst-fontify-io-port-keyword-with-inline-comment ()
  "IO_PORT keyword is highlighted even when inline comment follows."
  (gowin-cst-test-with-buffer
   "IO_PORT \"signal_name2[2]\" /* It's comment */ IO_TYPE=LVCMOS25 PULL_MODE=UP DRIVE=8 BANK_VCCIO=2.5;\n"
   (should (eq (gowin-cst-test-face-at 1) 'font-lock-keyword-face))))

(ert-deftest gowin-cst-fontify-attribute-after-inline-comment ()
  "IO_TYPE attribute after /* comment */ is still highlighted."
  (gowin-cst-test-with-buffer
   "IO_PORT \"signal_name2[2]\" /* It's comment */ IO_TYPE=LVCMOS25 PULL_MODE=UP DRIVE=8 BANK_VCCIO=2.5;\n"
   (search-forward "IO_TYPE")
   (should (eq (gowin-cst-test-face-at (match-beginning 0)) 'font-lock-type-face))))

(ert-deftest gowin-cst-fontify-attribute-before-trailing-comment ()
  "Attributes are highlighted when line has a trailing /* comment */."
  (gowin-cst-test-with-buffer
   "IO_PORT \"signal_name2[3]\" IO_TYPE=LVCMOS25 PULL_MODE=UP DRIVE=8 BANK_VCCIO=2.5; /* It's comment */\n"
   (search-forward "IO_TYPE")
   (should (eq (gowin-cst-test-face-at (match-beginning 0)) 'font-lock-type-face))
   (search-forward "PULL_MODE")
   (should (eq (gowin-cst-test-face-at (match-beginning 0)) 'font-lock-type-face))))

(ert-deftest gowin-cst-fontify-inline-comment-text-is-comment ()
  "Text inside /* */ in IO_PORT is recognized as comment."
  (gowin-cst-test-with-buffer
   "IO_PORT \"sig\" /* a comment */ IO_TYPE=LVCMOS25;\n"
   (search-forward "a comment")
   (should (nth 4 (syntax-ppss (match-beginning 0))))))

;;; Font-lock: block comment suppresses keywords

(ert-deftest gowin-cst-block-comment-suppresses-keyword ()
  "IO_LOC inside a /* */ block comment is not highlighted as keyword."
  (gowin-cst-test-with-buffer "/*\nIO_LOC  \"signal_name\"    F100;\n*/\n"
                              (search-forward "IO_LOC")
                              (should (eq (gowin-cst-test-face-at (match-beginning 0)) 'font-lock-comment-face))))

;;; Font-lock: string with bus index

(ert-deftest gowin-cst-fontify-string-with-bus-index ()
  "Quoted string with bus index like \"signal[0]\" is highlighted as string."
  (gowin-cst-test-with-buffer "IO_PORT \"signal_name2[0]\" IO_TYPE=LVCMOS25;\n"
                              (search-forward "\"signal_name2[0]\"")
                              (should (eq (gowin-cst-test-face-at (1+ (match-beginning 0))) 'font-lock-string-face))))

;;; Font-lock: BANK_VCCIO decimal value

(ert-deftest gowin-cst-fontify-bank-vccio-decimal ()
  "Decimal value 2.5 in BANK_VCCIO=2.5 is highlighted as number."
  (gowin-cst-test-with-buffer "IO_PORT \"sig\" BANK_VCCIO=2.5;\n"
                              (search-forward "2.5")
                              (should (eq (gowin-cst-test-face-at (match-beginning 0)) 'font-lock-number-face))))

;;; Completion

(ert-deftest gowin-cst-completion-at-point-works ()
  "Completion returns candidates for a partial keyword."
  (gowin-cst-test-with-buffer "IO"
                              (goto-char (point-max))
                              (let ((result (gowin-cst-mode-completion-at-point)))
                                (should result)
                                (should (= (nth 0 result) 1))
                                (should (= (nth 1 result) 3))
                                (should (member "IO_LOC" (nth 2 result)))
                                (should (member "IO_TYPE" (nth 2 result))))))

(ert-deftest gowin-cst-completion-nil-on-empty ()
  "Completion returns nil when point is not on a symbol."
  (gowin-cst-test-with-buffer " "
                              (goto-char (point-max))
                              (should-not (gowin-cst-mode-completion-at-point))))

;;; Imenu

(ert-deftest gowin-cst-imenu-io-loc ()
  "Imenu indexes IO_LOC entries."
  (gowin-cst-test-with-buffer "IO_LOC \"clk\" G16;\nIO_LOC \"led\" M11;\n"
                              (let ((index (imenu--make-index-alist t)))
                                (should (assoc "IO_LOC" index))
                                (let ((entries (cdr (assoc "IO_LOC" index))))
                                  (should (= (length entries) 2))
                                  (should (assoc "clk" entries))
                                  (should (assoc "led" entries))))))

(ert-deftest gowin-cst-imenu-io-port ()
  "Imenu indexes IO_PORT entries."
  (gowin-cst-test-with-buffer "IO_PORT \"led\" IO_TYPE=LVCMOS33;\n"
                              (let ((index (imenu--make-index-alist t)))
                                (should (assoc "IO_PORT" index))
                                (let ((entries (cdr (assoc "IO_PORT" index))))
                                  (should (assoc "led" entries))))))

;;; Indentation

(ert-deftest gowin-cst-indent-to-zero ()
  "Lines are indented to column 0."
  (gowin-cst-test-with-buffer "   IO_LOC \"led\" M11;\n"
                              (goto-char (point-min))
                              (gowin-cst-mode-indent-line)
                              (should (= (current-indentation) 0))))

;;; Customization group

(ert-deftest gowin-cst-custom-group-exists ()
  "The gowin-cst customization group exists."
  (should (get 'gowin-cst 'custom-group)))

(provide 'gowin-cst-mode-tests)

;;; gowin-cst-mode-tests.el ends here
