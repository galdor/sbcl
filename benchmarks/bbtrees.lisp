(setq *evaluator-mode* :compile)
(load "src/code/redblack.lisp")
(with-compilation-unit () (load "tests/test-util.lisp"))

(in-package "SB-RBTREE.WORD")
(defun height (tree)
  (sb-int:named-let recurse ((tree tree))
    (if (not tree)
        0
        (1+ (max (recurse (left tree)) (recurse (right tree)))))))
(compile 'height)

(in-package "SB-BROTHERTREE")
(defmacro binary-node-parts (node)
  `(let ((n ,node))
     (if (fringe-binary-node-p n)
         (values nil (binary-node-key n) nil) ; has only one data slot
         ;; has left + right
         (values (binary-node-%left n) (binary-node-key n) (binary-node-%right n)))))
(defun height (tree &aux (n 0))
  (loop
     (unless tree (return n))
     (incf n)
     ;; We're assuming that the brothertree invariant holds-
     ;; the left and right heights are the same.
     (typecase tree
       (binary-node (setq tree (values (binary-node-parts tree))))
       (unary-node  (setq tree (child tree))))))
(compile 'height)

(in-package "CL-USER")
(defvar *brothertree* nil)
(defvar *rbtree* nil)
(defvar *solist* nil)

(defvar *lotta-strings*
  (mapcar (lambda (x)
            (sb-kernel:%make-lisp-obj
             (logandc2 (sb-kernel:get-lisp-obj-address x)
                       sb-vm:lowtag-mask)))
          (sb-vm:list-allocated-objects
           :read-only
           :type sb-vm:simple-base-string-widetag)))

(defun insert-all-brothertree ()
  (let ((tree nil))
    (dolist (str *lotta-strings*)
      (setq tree (sb-brothertree:insert str tree)))
    (setq *brothertree* tree)))

(defun insert-all-redblack ()
  (let ((tree nil))
    (dolist (str *lotta-strings*)
      ;; because OF COURSE the arg orders are opposite
      (setq tree (sb-rbtree.word:insert tree str)))
    (setq *rbtree* tree)))

(defun insert-all-solist ()
  (let ((set (let ((sb-lockless::*desired-elts-per-bin* 1))
               (sb-lockless:make-so-set/addr))))
    (dolist (str *lotta-strings*)
      (sb-lockless:so-insert set str))
    (setq *solist* set)))

(gc)
(time (insert-all-redblack))
(gc)
(time (insert-all-brothertree))
(gc)
(time (insert-all-solist))
(let ((n (length *lotta-strings*)))
  (format t "~&Memory:~:{~%  ~8a=~8D ~3,1f~}~%"
          (loop for (name . val) in `(("brother" . ,*brothertree*)
                                      ("redblack" . ,*rbtree*)
                                      ("solist" . ,*solist*))
                collect
                (let ((mem (test-util:deep-size val)))
                  (list name mem (/ mem n))))))

(format t "~&Tree heights: redblack=~D brother=~D~2%"
        (sb-rbtree.word::height *rbtree*)
        (sb-brothertree::height *brothertree*))

(defun find-all-in-brothertree (&aux (tree *brothertree*))
  (loop for str in *lotta-strings*
        count (sb-brothertree:find= str tree)))
(defun find-all-in-redblack-tree (&aux (tree *rbtree*))
  (loop for str in *lotta-strings*
        count (sb-rbtree.word:find= str tree)))
(defun find-all-in-solist (&aux (set *solist*))
  (loop for str in *lotta-strings*
        count (sb-lockless:so-find set str)))

(find-all-in-brothertree)
(find-all-in-redblack-tree)
(find-all-in-solist)
(time (find-all-in-brothertree))
(time (find-all-in-redblack-tree))
(time (find-all-in-solist))

#|
* (load"benchmarks/bbtrees")
Evaluation took:
  0.012 seconds of real time
  0.012138 seconds of total run time (0.012086 user, 0.000052 system)
  100.00% CPU
  29,126,552 processor cycles
  21,916,768 bytes consed

Evaluation took:
  0.007 seconds of real time
  0.007634 seconds of total run time (0.007550 user, 0.000084 system)
  114.29% CPU
  18,334,338 processor cycles
  18,640,080 bytes consed

Tree heights: redblack=25 brother=16
|#
