;; (import (class android.content Context))
;; (import (class com.google.android.gms.ads AdListener AdRequest InterstitialAd))
;; (import (class android.os Handler))
;; (import (class java.lang System Runnable))

;; ;; (define show-delay 300)
;; (define show-delay 30)
;; (define handler ::Handler #!null)
;; (define runnable ::Runnable #!null)
;; (define ad-showing-time 0)
;; (define interstitial-ad ::InterstitialAd #!null)
;; (define is-init? #f)

;; (define init-ad
;;   (lambda ((context ::Context))
;;     (unless is-init?
;; 	    (set! is-init? #t)
;; 	    (set! handler (Handler))
;; 	    (set! interstitial-ad (InterstitialAd context))
;; 	    (interstitial-ad:setAdUnitId "ca-app-pub-3551700581852685/8610756454")
;; 	    (interstitial-ad:setAdListener (object (AdListener)
;; 						   ((onAdClosed)
;; 						    (load-ad))))
;; 	    (load-ad))))

;; (define show-ad
;;   (lambda ()
;;     (let ((delay (/ (- (System:nanoTime) ad-showing-time) 1000000000)))
;;       (when (> delay show-delay)
;; 	    (if interstitial-ad:isLoaded
;; 		(begin
;; 		  (interstitial-ad:show)
;; 		  (set! ad-showing-time (System:nanoTime)))
;; 		(request-new-interstitial))))))

;; (define load-ad
;;   (lambda ()
;;     (when (eq? runnable #!null)
;; 	  (set! runnable (object (Runnable)
;; 				 ((run)
;; 				  (request-new-interstitial)
;; 				  (set! runnable #!null))))
;; 	  (handler:post runnable))))

;; (define request-new-interstitial
;;   (lambda ()
;;     (let ((ad-request (((AdRequest:Builder):addTestDevice AdRequest:DEVICE_ID_EMULATOR):build)))
;;       (interstitial-ad:loadAd ad-request))))
