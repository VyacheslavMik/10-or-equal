(require 'android-defs)

(define-constant data
  (string-append
   "Your aim is to find pairs of adjacent numbers that equal or it sum equal ten. "
   "When you select number it's adjacents highlight. For each disabled pair your "
   "gain 10 scores. When all numbers in row are disabled then whole row disappear. "
   "You win when no one number be on table. If row count exceeds 50 you lose game."))

(activity rules
	  (on-create-view
	   (define text
	     (TextView BackgroundColor: (as int #0xFFFAFFE3) TextColor: #0xFF000000
		       text: data))
	   text))
