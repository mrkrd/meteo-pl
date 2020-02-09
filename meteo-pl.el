;;; meteo-pl.el --- Show meteograms from meteo.pl


;;; Commentary:

;; This package shows meteograms from https://www.meteo.pl/ in GNU
;; Emacs.

;; Your coordinages can be specified by setting `calendar-latitude'
;; and `calendar-longitude' variables.  After that you can just call
;; `meteo-pl-show-meteogram'.

;;; Code:

(require 'url)
(require 'json)


(defun meteo-pl--get-xyt ()
  "Parse buffer and gets values of x, y, and time."
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward "act_x = \\([0-9]+\\).*act_y = \\([0-9]+\\).*fcstdate = \"\\([0-9]+\\)\"")
      (list (string-to-number (match-string 1))
            (string-to-number (match-string 2))
            (string-to-number (match-string 3))
            ))
  ))

;; (meteo-pl--get-xyt)
;; {act_x = 80; act_y = 511; fcstdate = "2020020912" }


(defun meteo-pl--remove-http-headers ()
  (delete-region (point-min) (1+ url-http-end-of-headers))
  )


(defun meteo-pl--mgram-search ()
  "Converts lat, lon -> x, y, and time"
  (with-current-buffer
      (url-retrieve-synchronously
       (format "https://www.meteo.pl/um/php/mgram_search.php?NALL=%f&EALL=%f"
               calendar-latitude
               calendar-longitude
               ))
    (prog1
        (meteo-pl--get-xyt)
      (kill-buffer)
      )))

;; (meteo-pl--mgram-search)


(defun meteo-pl--retrive-meteogram ()
  "Retrive and return a buffer with image data."
  (let* ((xyt (meteo-pl--mgram-search))
         (url (format "https://www.meteo.pl/um/metco/mgram_pict.php?ntype=0u&col=%d&row=%d&fdate=%s&lang=en"
                      (nth 0 xyt)
                      (nth 1 xyt)
                      (nth 2 xyt)
                      ))
         )
    (with-current-buffer
        (url-retrieve-synchronously url)
      (meteo-pl--remove-http-headers)
      (current-buffer)
      )))

;; (switch-to-buffer (meteo-pl--retrive-meteogram))


(defun meteo-pl-show-meteogram ()
  (interactive)
  (let ((meteogram-buf (meteo-pl--retrive-meteogram))
        )
    (with-current-buffer
        (get-buffer-create "*meteo-pl: meteogram*")
      (fundamental-mode)
      (erase-buffer)
      (replace-buffer-contents meteogram-buf)
      (kill-buffer meteogram-buf)
      (switch-to-buffer (current-buffer))
      (goto-char (point-min))
      (image-mode)
      )))

;; (meteo-pl-show-meteogram)


(provide 'meteo-pl)

;;; meteo-pl.el ends here
