(define row-count 50)
(define col-count 9)

(defmacro number (val state)
  `(vector ,val ,state))

(defmacro defnumaccessor (name position)
  (let ((mname (string->symbol (format #f "number-~a" name))))
    `(defmacro ,mname (obj)
       `(vector-ref ,obj ,,position))))

(defnumaccessor val 0)
(defnumaccessor state 1)

(define make-number-row
  (lambda ()
    (let* ((curr-col -1)
	   (row (make-vector col-count #f)))

      (define all-numbers-disabled?
	(lambda (col)
	  (if (> col curr-col)
	      #t
	      (if (or (not (vector-ref row col))
		      (not (eq? (number-state (vector-ref row col)) 'disabled)))
		  #f
		  (all-numbers-disabled? (+ col 1))))))

      (define add-number
	(lambda (number)
	  (if (full?)
	      (raise "Row is full")
	      (begin
		(set! curr-col (+ curr-col 1))
		(set! (vector-ref row curr-col) number)))))

      (define full?
	(lambda ()
	  (= curr-col (- col-count 1))))

      (define get-number
	(lambda (column)
	  (if (or (< column 0) (>= column col-count))
	      (raise "Out of bounds")
	      (vector-ref row column))))

      (lambda args
	(if (null? args)
	    row
	    (let ((fn (car args)))
	      (cond
	       ((eq? fn 'all-numbers-disabled?:)
		(all-numbers-disabled? 0))

	       ((eq? fn 'add-number:)
		(add-number (cadr args)))

	       ((eq? fn 'full?:)
		(full?))

	       ((eq? fn 'get-number:)
		(get-number (cadr args)))

	       (else (raise (format #f "Unknown function: ~a" fn))))))))))

(define number-row->string
  (lambda (row)
    (if row
	(format #f "~a" (row))
	"#f")))

(define number-array->string
  (lambda (arr)
    (format #f "~{~a~%~}" 
	    (map (lambda (row)
		   (number-row->string row))
		 (arr)))))

(define make-number-array 
  (lambda ()
    (let* ((curr-row #f)
	   (curr-row-idx -1)
	   (arr (make-vector row-count #f)))

      (define can-add-number?
	(lambda ()
	  (not (and curr-row (curr-row 'full?:) (>= (+ curr-row-idx 1) row-count)))))
    
      (define add-number
	(lambda (number)
	  (if (can-add-number?)
	      (begin
		(when (or (not curr-row) (curr-row 'full?:))
		      (set! curr-row (make-number-row))
		      (set! curr-row-idx (+ curr-row-idx 1))
		      (set! (arr curr-row-idx) curr-row))
		(curr-row add-number: number)
		#t)
	      #f)))

      (define get-number
	(lambda (row col)
	  (if (or (< row 0) (>= row row-count))
	      (raise "Out of bounds")
	      (if (vector-ref arr row)
		  ((vector-ref arr row) get-number: col)
		  #f))))

      (define disable-numbers
	(lambda (numbers)
	  (for-each (lambda (number)
		      (set! (number-state (get-number (car number) (cdr number))) 'disabled))
		    numbers)
	  (letrec ((next-row (lambda (n)
			       (if (= n row-count)
				   #f
				   (let ((row (vector-ref arr n)))
				     (if (and row (or (not (row 'all-numbers-disabled?:)) (not (row 'full?:))))
					 n
					 (next-row (+ n 1))))))))
	    (do ((i 0 (+ i 1)))
		((>= i row-count))
	      (let ((row (vector-ref arr i)))
		(if row
		    (when (and (row 'full?:) (row 'all-numbers-disabled?:))
			  (let ((next-row (next-row (+ i 1))))
			    (if next-row
				(begin
				  (set! (vector-ref arr i) (vector-ref arr next-row))
				  (set! (vector-ref arr next-row) #f))
				(set! (vector-ref arr i) #f))))
		    (let ((next-row (next-row (+ i 1))))
		      (when next-row
			    (set! (vector-ref arr i) (vector-ref arr next-row))
			    (set! (vector-ref arr next-row) #f))))))

	    (let set-curr ((i 0))
	      (if (or (>= i row-count) (not (arr i)))
		  (begin
		    (set! curr-row-idx (- i 1))
		    (set! curr-row (if (= curr-row-idx -1)
				       #f
				       (arr curr-row-idx))))
		  (set-curr (+ i 1))))

	    (when (and (= curr-row-idx 0) (curr-row 'all-numbers-disabled?:))
		  (set! (arr curr-row-idx) #f)
		  (set! curr-row-idx -1)
		  (set! curr-row #f)))))

      (define empty?
	(lambda ()
	  (and (= curr-row-idx -1) (not curr-row))))

      (define full?
	(lambda ()
	  (not (can-add-number?))))

      (lambda args
	(if (null? args)
	    arr
	    (let ((fn (car args)))
	      (cond
	       ((eq? fn 'add-number:)
		(add-number (cadr args)))

	       ((eq? fn 'get-number:)
		(get-number (cadr args)(caddr args)))

	       ((eq? fn 'disable-numbers:)
		(disable-numbers (cdr args)))

	       ((eq? fn 'empty?:)
		(empty?))

	       ((eq? fn 'full?:)
		(full?))

	       (else (raise (format #f "Unknown command: ~a" fn))))))))))
