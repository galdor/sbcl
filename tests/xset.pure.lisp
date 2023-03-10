(defstruct foo)

(with-test (:name :xset-hash-equal)
  (let ((list `(sym ,(make-foo) 1 -12d0 4/3 #\z ,(ash 1 70)))
        (a (sb-int:alloc-xset)))
    (dolist (elt list)
      (sb-int:add-to-xset elt a))
    (dotimes (i 10)
      (let ((b (sb-int:alloc-xset)))
        (dolist (elt (shuffle list))
          (sb-int:add-to-xset elt b))
        (assert (sb-int:xset= a b))
        (assert (= (sb-int:xset-elts-hash a)
                   (sb-int:xset-elts-hash b)))))))

(with-test (:name :xset-fast-union)
  (let ((s1 (sb-int:alloc-xset))
        (s2 (sb-int:alloc-xset)))
    (sb-int:add-to-xset #\a s1)
    (sb-int:add-to-xset #\b s1)
    (sb-int:add-to-xset #\c s1)
    (assert (eq (sb-int:xset-union s1 s2) s1))
    (assert (eq (sb-int:xset-union s2 s1) s1))
    (sb-int:add-to-xset #\b s2)
    (assert (eq (sb-int:xset-union s1 s2) s1))
    (assert (eq (sb-int:xset-union s2 s1) s1)))
  (let ((s1 (sb-int:alloc-xset))
        (s2 (sb-int:alloc-xset)))
    (loop for i from (char-code #\a) to (char-code #\z)
          do (sb-int:add-to-xset (code-char i) s1))
    (sb-int:add-to-xset #\x s2)
    (loop for i from 1 to 10
          do (sb-int:add-to-xset (code-char i) s1))
    (assert (listp (sb-kernel::xset-data s2)))
    (let ((union1 (sb-int:xset-union s1 s2)))
      (assert (= (sb-int:xset-count union1) (+ 26 10)))
      (let ((union2 (sb-int:xset-union s2 s1))) ; had better commute
        (assert (sb-int:xset= union1 union2))))))
