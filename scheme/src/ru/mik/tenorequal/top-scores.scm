(require 'android-defs)
(import (srfi 95))

(define-simple-class top-scores-adapter (android.widget.ArrayAdapter)
  (context ::android.content.Context)
  
  ((*init* (context ::android.content.Context) (strings ::string[]))
   (invoke-special android.widget.ArrayAdapter (this) '*init* context -1 -1 strings)
   (set! (this):context context))

  ((getView (position ::int) (convert-view ::android.view.View) (parent ::android.view.ViewGroup)) ::android.view.View
   (parameterize ((current-activity context))
		 (let ((list-layout (android.widget.LinearLayout id: 100))
		       (list-text (android.widget.TextView TextColor: #0xFF000000)))
		   (list-layout:setLayoutParams (android.widget.AbsListView:LayoutParams
						 android.widget.AbsListView:LayoutParams:WRAP_CONTENT
						 android.widget.AbsListView:LayoutParams:WRAP_CONTENT))
		   (list-layout:addView list-text)
		   (list-text:setText (as string (invoke-special android.widget.ArrayAdapter (this) 'getItem position)))
		   list-layout))))

(activity topScores
	  (on-create
	   (let ((lst (android.widget.ListView (this) BackgroundColor: (as int #0xFFFAFFE3))))
	     (let ((top-scores '())
		   (array #!null))
	       (let ((top-scores-setting ((getIntent):getStringExtra "top-scores")))
		 (when top-scores-setting
		       (let ((p (open-input-string top-scores-setting)))
			 (do ((score (read p) (read p)))
			     ((eof-object? score))
			   (set! top-scores (cons score top-scores))))))
		 
	       (set! array (string[] length: (length top-scores)))

	       (let ((i 0))
		 (for-each (lambda (score)
			     (set! (array i) (format "~a: ~a - ~a" (+ i 1) (car score) (cdr score)))
			     (set! i (+ i 1)))
			   (sort top-scores (lambda (l r) (if (= (cdr l) (cdr r))
							      (string<? (car l) (car r))
							      (> (cdr l) (cdr r)))))))
	       (lst:setAdapter (top-scores-adapter (this) array)))
	     ((this):setContentView lst))))
