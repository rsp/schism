;; Copyright 2019 Google LLC
;;
;; Licensed under the Apache License, Version 2.0 (the License);
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at
;;
;;     http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an AS IS BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.

(library (rnrs)
  (export > append assp assq boolean? caaar caadar caaddr caadr caar cadadr
          cadar caddar cadddr caddr cadr car cdaddr cdadr cdar cddar cdddr cddr
          cdr char->integer char-ci<? char-numeric? char-whitespace? display
          equal? fold-left fold-right integer->char length list->string list-ref
          list-tail map max newline null? peek-char read read-char string->list
          string->symbol string=? symbol->string symbol? write write-char zero?)
  (import (schism))

  (define (display x)
    (cond
     ((pair? x)
      (%log-char #\()
      (display (car x))
      (%display-pair-tail (cdr x)))
     ((null? x) (%log-char #\() (%log-char #\)))
     ((symbol? x)
      (if (%gensym? x)
          (%display-gensym x)
          (%display-symbol x)))
     ((boolean? x) (%log-char #\#) (%log-char (if x #\t #\f)))
     ((number? x) (%display-number x))
     ((char? x) (%log-char #\#) (%log-char #\\) (%log-char x))
     ((string? x) (%log-char #\") (%display-raw-string x) (%log-char #\"))
     ((procedure? x)
      (%display-raw-string "#<procedure>"))
     (else (%display-raw-string "<!display unknown unimplemented!>"))))

  (define (%display-number n)
    (cond ((< n 0) (%log-char #\-) (%display-leading-digits (- 0 n)))
          ((eq? n 0) (%log-char #\0))
          (else (%display-leading-digits n))))
  (define (%display-leading-digits n)
    (unless (zero? n)
            (%display-leading-digits (div0 n 10))
            (%display-least-significant-digit n)))
  (define (%display-least-significant-digit n)
    (%log-char (integer->char (+ (char->integer #\0) (mod0 n 10)))))
  (define (%display-pair-tail x)
    (cond
     ((null? x) (%log-char #\)))
     ((pair? x)
      (%log-char #\space)
      (display (car x))
      (%display-pair-tail (cdr x)))
     (else
      (%log-char #\space) (%log-char #\.) (%log-char #\space)
      (display x)
      (%log-char #\)))))
  (define (%display-raw-string s)
    (unless (string? s)
            (error '%display-raw-string "not a string"))
    (%display-chars-as-string (%string->list s)))
  (define (%display-chars-as-string chars)
    (unless (null? chars)
            (unless (pair? chars)
                    (error '%display-chars-as-string "not a list of chars"))
            (%log-char (%char-value (car chars)))
            (%display-chars-as-string (cdr chars))))
  (define (%display-gensym sym)
    (%log-char #\#) (%log-char #\<)
    (%log-char #\g) (%log-char #\e) (%log-char #\n)
    (%log-char #\s) (%log-char #\y) (%log-char #\m)
    (%log-char #\space)
    (%display-raw-string (%symbol->string sym))
    (%log-char #\>))
  (define (%display-symbol sym)
    (%display-raw-string (%symbol->string sym)))

  (define (write x)
    (if (string? x)
        (%display-raw-string x)
        (display x)))
  
  (define (newline)
    (%flush-log))

  (define (car p)
    (if (pair? p)
        (%car p)
        (error 'car "car: not a pair")))
  (define (cdr p)
    (if (pair? p)
        (%cdr p)
        (error 'cdr "cdr: not a pair")))
  (define (caar p) (car (car p)))
  (define (cadr p) (car (cdr p)))
  (define (cdar p) (cdr (car p)))
  (define (cddr p) (cdr (cdr p)))
  (define (caaar p) (car (caar p)))
  (define (caadr p) (car (cadr p)))
  (define (cadar p) (car (cdar p)))
  (define (cddar p) (cdr (cdar p)))
  (define (caddr p) (car (cddr p)))
  (define (cdadr p) (cdr (cadr p)))
  (define (cdddr p) (cdr (cddr p)))
  (define (caadar p) (car (cadar p)))
  (define (caaddr p) (car (caddr p)))
  (define (caddar p) (car (cddar p)))
  (define (cadadr p) (car (cdadr p)))
  (define (cadddr p) (car (cdddr p)))
  (define (cdaddr p) (cdr (caddr p)))
  (define (assp p ls)
    (if (pair? ls)
        (if (p (caar ls))
            (car ls)
            (assp p (cdr ls)))
        (if (null? ls)
            #f
            (begin (display ls) (newline) (error 'assp "not a list")))))
  (define (assq x ls)
    (if (pair? ls)
        (if (eq? x (caar ls))
            (car ls)
            (assq x (cdr ls)))
        (if (null? ls)
            #f
            (begin (display x) (newline) (error 'assq "not a list")))))
  (define (length ls)
    (cond
     ((null? ls) 0)
     ((pair? ls) (+ 1 (length (cdr ls))))
     (else (error 'length "argument is not a proper list"))))
  (define (list-tail list n)
    (if (zero? n)
        list
        (list-tail (cdr list) (- n 1))))
  (define (list-ref list n)
    (car (list-tail list n)))
  (define (append a b)
    (if (null? a) b (cons (car a) (append (cdr a) b))))
  (define (char->integer c)
    (if (char? c)
        (%char-value c)
        (error 'char->integer "not a char")))
  (define (integer->char c)
    (if (number? c)
        (%make-char c)
        (error 'char->integer "not a char")))
  (define (char-between c c1 c2) ;; inclusive
    (if (char-ci<? c c1)
        #f
        (if (char-ci<? c c2)
            #t
            (if (eq? c c2) #t #f))))
  (define (char-numeric? c)
    (char-between c #\0 #\9))
  (define (char-whitespace? c)
    (or (eq? c #\space) (eq? c #\tab) (eq? c #\newline)))
  (define (char-hex? c)
    (or (char-numeric? c) (char-between c #\a #\f)))
  (define (char-ci<? c1 c2)
    (< (char->integer c1) (char->integer c2)))
  (define (list->string ls)
    (unless (pair? ls) (error 'list->string "list->string: not a pair"))
    ;; For now we represent strings as lists of characters.
    (%list->string ls))
  (define (string->list s)
    (unless (string? s)
            ;; Calling error here can lead to an infinite loop, so we
            ;; generate an unreachable instead.
            (%unreachable))
    (%string->list s))
  (define (string=? s1 s2)
    (list-all-eq? (string->list s1) (string->list s2)))
  (define (string->symbol s)
    (if (string? s)
        (%string->symbol s)
        ;; calling error here can lead to an infinite loop, so we
        ;; generate an unreachable instead.
        (%unreachable)))
  (define (equal? x y)
    (cond ((pair? x)
           (and (pair? y)
                (equal? (car x) (car y))
                (equal? (cdr x) (cdr y))))
          ((string? x)
           (and (string? y)
                (equal? (string->list x) (string->list y))))
          (else (eq? x y))))
  (define (symbol->string x)
    (unless (symbol? x) (error 'symbol->string "not a symbol"))
    (%symbol->string x))
  (define (string->symbol str)
    (unless (string? str) (error 'string->symbol "not a string"))
    (%string->symbol str))
  (define (> a b)
    (< b a))
  (define (max a b)
    (if (< a b) b a))
  (define (peek-char)
    (let ((i (%peek-char)))
      (if (< i 0)
          (eof-object)
          (integer->char i))))
  (define (read-char)
    (let ((i (%read-char)))
      (if (< i 0)
          (eof-object)
          (integer->char i))))
  (define (write-char c)
    (%write-char (char->integer c)))
  (define (read)
    (read-skip-whitespace-and-comments)
    (start-read (read-char)))
  (define (start-read c)
    (cond
     ((char-numeric? c)
      (read-number (- (char->integer c) (char->integer #\0))))
     ((and (eq? c #\-) (char-numeric? (peek-char)))
      (- 0 (read-number 0)))
     ((eq? c #\#)
      (read-hash (read-char)))
     ((eq? c #\()
      (read-list))
     ((eq? c #\')
      (cons 'quote (cons (read) '())))
     ((eq? c #\`)
      (cons 'quasiquote (cons (read) '())))
     ((eq? c #\,)
      (cons 'unquote (cons (read) '())))
     ((eq? c #\")
      (list->string (read-string)))
     ((char-symbolic? c)
      (string->symbol (list->string (cons c (read-symbol)))))
     (else
      (error 'start-read "malformed datum"))))
  (define (read-string)
    (let ((c (read-char)))
      (if (eq? c #\")
          '()
          (cons c (read-string)))))
  (define (char-symbolic? c)
    (not (or (char-whitespace? c) (eq? c #\() (eq? c #\)) (eq? c #\;))))
  (define (read-symbol)
    (if (char-symbolic? (peek-char))
        (cons (read-char) (read-symbol))
        '()))
  (define (read-list)
    (read-skip-whitespace-and-comments)
    (cond
     ((eq? (peek-char) #\))
      (read-char)
      '())
     ((eq? (peek-char) #\.)
      (read-char)
      (let ((d (read)))
        (read-skip-whitespace-and-comments)
        (unless (eq? (read-char) #\))
                (error 'read-list "invalid improper list"))
        d))
     (else
      (let ((a (read)))
        (let ((d (read-list)))
          (cons a d))))))
  (define (read-skip-whitespace-and-comments)
    (cond
     ((char-whitespace? (peek-char))
      (read-char)
      (read-skip-whitespace-and-comments))
     ((eq? (peek-char) #\;)
      (read-skip-line))
     (else #f)))
  (define (read-skip-line)
    (cond
     ((eq? (peek-char) #\newline)
      (read-skip-whitespace-and-comments))
     (else
      (read-char)
      (read-skip-line))))
  (define (read-number acc)
    (if (char-numeric? (peek-char))
        (read-number (+ (* acc 10) (- (char->integer (read-char))
                                      (char->integer #\0))))
        acc))
  (define (hex-digit c)
    (if (char-numeric? c)
        (- (char->integer c)
           (char->integer #\0))
        (+ 10 (- (char->integer c)
                 (char->integer #\a)))))
  (define (read-hex acc)
    (if (char-hex? (peek-char))
        (read-hex (+ (* acc 16) (hex-digit (read-char))))
        acc))
  (define (read-hash c)
    (cond
     ((eq? c #\f)
      #f)
     ((eq? c #\t)
      #t)
     ((eq? c #\\)
      (let ((c (read-char)))
        (cond
         ((and (eq? c #\s) (eq? (peek-char) #\p)) ;; check if this is a space
          (let ((p (read-char)) (a (read-char)) (c (read-char)) (e (read-char)))
            #\space))
         ((and (eq? c #\t) (eq? (peek-char) #\a)) ;; check if this is a tab
          (let ((a (read-char)) (b (read-char)))
            #\tab))
         ((and (eq? c #\n) (eq? (peek-char) #\e)) ;; check if this is a newline
          (let ((e (read-char)) (w (read-char)) (l (read-char)) (i (read-char))
                (n (read-char)) (e^ (read-char)))
            #\newline))
         (else c))))
     ((eq? c #\x)
      (read-hex 0))
     (else #f)))
  (define (zero? n)
    (eq? n 0))
  (define (null? x)
    (eq? x '()))
  (define (boolean? p)
    (or (eq? p #t) (eq? p #f)))
  (define (symbol? p)
    (or (%symbol? p) (%gensym? p)))
  (define (map p ls)
    (if (null? ls)
        '()
        (cons (p (car ls)) (map p (cdr ls)))))
  (define (fold-left p init ls)
    (if (null? ls)
        init
        (fold-left p (p init (car ls)) (cdr ls))))

  (define (fold-right p init ls)
    (if (null? ls)
        init
        (p (car ls) (fold-right p init (cdr ls))))))