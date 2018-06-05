
(require 'url)
(require 'json)

(defun meteo-pl--get-row-col ()
  "Parses buffer and gets values of row=%d col=%d"
  (save-excursion
    (beginning-of-buffer)
    (when (re-search-forward "row=\\([0-9]+\\).*col=\\([0-9]+\\)")
      (list (string-to-number (match-string 1))
            (string-to-number (match-string 2))))
  ))

;; (meteo-pl--get-row-col)
;; {row=511,col=77}



(defun meteo-pl--remove-http-headers ()
  (delete-region (point-min) (1+ url-http-end-of-headers))
  )



(defun meteo-pl--search-mgram-pos ()
  "Converts lat, lon -> row, col"
  (with-current-buffer
      (url-retrieve-synchronously
       (format "https://nowe.meteo.pl/search_mgram_pos?lat=%f&lon=%f&model=0"
               calendar-latitude
               calendar-longitude
               ))
    (prog1
        (meteo-pl--get-row-col)
      (kill-buffer)
      )))

;; (meteo-pl--search-mgram-pos)


(defun meteo-pl--search-mgram-near (row col)
  "Converts row, col -> row_near, col_near (whatever it means)"
  (with-current-buffer
      (url-retrieve-synchronously
       (format "https://nowe.meteo.pl/search_mgram_near?row=%d&col=%d&model=0"
               row
               col
               ))
    (beginning-of-buffer)
    (prog1
        (meteo-pl--get-row-col)
      (kill-buffer)
      )))

;; (meteo-pl--search-mgram-near 511 77)



;; (defun meteo-pl--time-str ()
;;   (let* ((time (current-time))
;;          (dtime (decode-time time "UTC0"))
;;          (ymd-str (format-time-string "%Y%m%d" time "UTC0"))
;;          (hour (nth 2 dtime))
;;          (res 6)                          ; in hours
;;          (hour_round (* (/ hour res) res))
;;        )
;;     (format "%s%d" ymd-str hour_round)
;;     ))

;; (meteo-pl--time-str)






(defun meteo-pl--model-conf ()
  "Get parameters of the current model as json"
  (with-current-buffer
      (url-retrieve-synchronously "https://nowe.meteo.pl/models/conf/models_conf.php")
    (meteo-pl--remove-http-headers)
    (beginning-of-buffer)
    (prog1
        (json-read-object)
      (kill-buffer))
    ))

;; (meteo-pl--model-conf)





(defun meteo-pl-show-meteogram ()
  (interactive)
  (let* ((row-col (meteo-pl--search-mgram-pos))
         (rown-coln (apply 'meteo-pl--search-mgram-near row-col))
         (conf (meteo-pl--model-conf))
         (url (format "https://nowe.meteo.pl/um4/mgram/mgram_pict.php?ntype=0u&date=%s&row=%d&col=%d&lang=en"
                      (alist-get 'fulldate conf)
                      (nth 0 rown-coln)
                      (nth 1 rown-coln)))
         )
    (with-current-buffer
        (url-retrieve-synchronously url)
      (rename-buffer "*meteo-pl: meteogram*" t)
      (meteo-pl--remove-http-headers)
      (switch-to-buffer (current-buffer))
      (goto-char (point-min))
      (image-mode)
      )))

;; (meteo-pl-show-meteogram)




(provide 'meteo-pl)
