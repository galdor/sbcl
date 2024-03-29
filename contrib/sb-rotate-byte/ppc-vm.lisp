(in-package "SB-ROTATE-BYTE")

(define-vop (%32bit-rotate-byte/c)
  (:policy :fast-safe)
  (:translate %unsigned-32-rotate-byte)
  (:note "inline 32-bit constant rotation")
  (:info count)
  (:args (integer :scs (sb-vm::unsigned-reg) :target res))
  (:arg-types (:constant (integer -31 31)) sb-vm::unsigned-byte-32)
  (:results (res :scs (sb-vm::unsigned-reg)))
  (:result-types sb-vm::unsigned-byte-32)
  (:generator 5
    ;; the 0 case is an identity operation and should be
    ;; DEFTRANSFORMed away.
    (aver (not (= count 0)))
    (if (> count 0)
        (inst rotlwi res integer count)
        (inst rotrwi res integer (- count)))))

(define-vop (%32bit-rotate-byte-fixnum/c)
  (:policy :fast-safe)
  (:translate %unsigned-32-rotate-byte)
  (:note "inline 32-bit constant rotation")
  (:info count)
  (:args (integer :scs (sb-vm::any-reg) :target res))
  (:arg-types (:constant (integer -31 31)) sb-vm::positive-fixnum)
  (:results (res :scs (sb-vm::unsigned-reg)))
  (:result-types sb-vm::unsigned-byte-32)
  (:generator 5
    (aver (not (= count 0)))
    (cond
      ;; FIXME: all these 2s should be n-fixnum-tag-bits.
      ((= count 2))
      ((> count 2) (inst rotlwi res integer (- count 2)))
      (t (inst rotrwi res integer (- 2 count))))))

(macrolet ((def (name arg-type)
             `(define-vop (,name)
               (:policy :fast-safe)
               (:translate %unsigned-32-rotate-byte)
               (:note "inline 32-bit rotation")
               (:args (count :scs (sb-vm::signed-reg))
                      (integer :scs (sb-vm::unsigned-reg) :target res))
               (:arg-types sb-vm::tagged-num ,arg-type)
               (:temporary (:scs (sb-vm::unsigned-reg) :from (:argument 0))
                           realcount)
               (:results (res :scs (sb-vm::unsigned-reg)))
               (:result-types sb-vm::unsigned-byte-32)
               (:generator 10
                  (inst cmpwi count 0)
                  (inst bge label)
                  (inst addi realcount count 32)
                  (inst rotlw res integer realcount)
                  (inst b end)
                  LABEL
                  (inst rotlw res integer count)
                  END))))
  (def %32bit-rotate-byte sb-vm::unsigned-byte-32)
  ;; FIXME: see x86-vm.lisp
  (def %32bit-rotate-byte-fixnum sb-vm::positive-fixnum))
