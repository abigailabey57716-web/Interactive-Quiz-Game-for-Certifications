(define-constant err-unauthorized u100)
(define-constant err-exists u101)
(define-constant err-not-found u102)
(define-constant err-bad-arg u103)
(define-constant err-active u104)
(define-constant err-inactive u105)
(define-constant err-incomplete u106)
(define-constant err-done u107)
(define-constant err-already-badged u108)

(define-map questions {id: uint} {prompt: (string-ascii 256), answers: uint, correct: uint, a0: (string-ascii 128), a1: (string-ascii 128), a2: (string-ascii 128), a3: (string-ascii 128), a4: (string-ascii 128), a5: (string-ascii 128), a6: (string-ascii 128), a7: (string-ascii 128), a8: (string-ascii 128), a9: (string-ascii 128)})
(define-map quizzes {id: uint} {count: uint, pass: uint})
(define-map quizq {qid: uint, pos: uint} {question: uint})
(define-map attempts {qid: uint, user: principal} {seed: uint, progress: uint, score: uint, done: bool, total: uint, pass: uint})
(define-map user-nonce {user: principal} {n: uint})
(define-map badges {qid: uint, user: principal} {ok: bool})

(define-data-var owner (optional principal) none)
(define-read-only (get-owner) (ok (var-get owner)))

(define-private (ensure-owner)
  (let ((o (var-get owner)))
    (if (is-some o)
      (begin (asserts! (is-eq tx-sender (unwrap-panic o)) (err err-unauthorized)) (ok true))
      (begin (var-set owner (some tx-sender)) (ok true))
    )
  )
)

(define-read-only (get-question (id uint))
  (match (map-get? questions {id: id}) q (ok q) (err err-not-found)))

(define-read-only (get-answer (qid uint) (index uint))
  (let ((q (unwrap! (map-get? questions {id: qid}) (err err-not-found))))
    (asserts! (< index (get answers q)) (err err-bad-arg))
    (ok
      (if (is-eq index u0) (get a0 q)
      (if (is-eq index u1) (get a1 q)
      (if (is-eq index u2) (get a2 q)
      (if (is-eq index u3) (get a3 q)
      (if (is-eq index u4) (get a4 q)
      (if (is-eq index u5) (get a5 q)
      (if (is-eq index u6) (get a6 q)
      (if (is-eq index u7) (get a7 q)
      (if (is-eq index u8) (get a8 q)
                           (get a9 q))))))))))
    )
  )
)

(define-read-only (get-quiz (id uint))
  (match (map-get? quizzes {id: id}) q (ok q) (err err-not-found)))

(define-read-only (get-quiz-question (quiz-id uint) (pos uint))
  (match (map-get? quizq {qid: quiz-id, pos: pos}) q (ok q) (err err-not-found)))

(define-read-only (get-attempt (quiz-id uint) (user principal))
  (match (map-get? attempts {qid: quiz-id, user: user}) a (ok a) (err err-not-found)))

(define-read-only (has-badge (quiz-id uint) (user principal))
  (ok (is-some (map-get? badges {qid: quiz-id, user: user}))))

(define-private (nonce-of (user principal))
  (default-to u0 (get n (map-get? user-nonce {user: user}))))

(define-private (set-nonce (user principal) (n uint))
  (begin (map-set user-nonce {user: user} {n: n}) true))

(define-private (make-seed (user principal))
  (nonce-of user))

(define-private (rand-index (seed uint) (k uint) (n uint))
  (mod (+ seed (* k u9973) u8923) (if (> n u0) n u1)))

(define-private (quiz-count (quiz-id uint))
  (let ((q (unwrap-panic (map-get? quizzes {id: quiz-id})))) (get count q)))

(define-private (quiz-pass (quiz-id uint))
  (let ((q (unwrap-panic (map-get? quizzes {id: quiz-id})))) (get pass q)))

(define-private (question-id-at (quiz-id uint) (pos uint))
  (let ((r (unwrap-panic (map-get? quizq {qid: quiz-id, pos: pos})))) (get question r)))

(define-private (random-question-id (quiz-id uint) (seed uint) (pos uint))
  (let ((n (quiz-count quiz-id)) (i (rand-index seed pos (quiz-count quiz-id)))) (question-id-at quiz-id i)))

(define-private (min (a uint) (b uint)) (if (< a b) a b))

(define-public (add-question (id uint) (prompt (string-ascii 256)) (answers-list (list 10 (string-ascii 128))) (correct-index uint))
(begin
    (try! (ensure-owner))
    (asserts! (is-none (map-get? questions {id: id})) (err err-exists))
    (let ((count (len answers-list)))
      (asserts! (> count u0) (err err-bad-arg))
      (asserts! (< correct-index count) (err err-bad-arg))
(map-set questions {id: id} {prompt: prompt, answers: count, correct: correct-index,
a0: (if (> count u0) (unwrap-panic (element-at answers-list u0)) ""),
a1: (if (> count u1) (unwrap-panic (element-at answers-list u1)) ""),
a2: (if (> count u2) (unwrap-panic (element-at answers-list u2)) ""),
a3: (if (> count u3) (unwrap-panic (element-at answers-list u3)) ""),
a4: (if (> count u4) (unwrap-panic (element-at answers-list u4)) ""),
a5: (if (> count u5) (unwrap-panic (element-at answers-list u5)) ""),
a6: (if (> count u6) (unwrap-panic (element-at answers-list u6)) ""),
a7: (if (> count u7) (unwrap-panic (element-at answers-list u7)) ""),
a8: (if (> count u8) (unwrap-panic (element-at answers-list u8)) ""),
a9: (if (> count u9) (unwrap-panic (element-at answers-list u9)) "")})
      (ok true)
    )
  )
)

(define-public (set-quiz-meta (quiz-id uint) (count uint) (pass uint))
(begin
    (try! (ensure-owner))
    (asserts! (> count u0) (err err-bad-arg))
    (asserts! (<= pass count) (err err-bad-arg))
    (map-set quizzes {id: quiz-id} {count: count, pass: pass})
    (ok true)
  )
)

(define-public (set-quiz-question (quiz-id uint) (pos uint) (question-id uint))
(begin
    (try! (ensure-owner))
    (let ((cnt (quiz-count quiz-id)))
      (asserts! (> cnt u0) (err err-not-found))
      (asserts! (< pos cnt) (err err-bad-arg))
      (asserts! (is-some (map-get? questions {id: question-id})) (err err-not-found))
      (map-set quizq {qid: quiz-id, pos: pos} {question: question-id})
      (ok true)
    )
  )
)

(define-public (start-attempt (quiz-id uint))
  (begin
    (asserts! (is-some (map-get? quizzes {id: quiz-id})) (err err-not-found))
    (let ((existing (map-get? attempts {qid: quiz-id, user: tx-sender})))
      (if (is-some existing)
        (let ((a (unwrap-panic existing)))
          (asserts! (get done a) (err err-active))
          (let ((newn (+ (nonce-of tx-sender) u1)) (total (quiz-count quiz-id)) (pass (quiz-pass quiz-id)))
            (set-nonce tx-sender newn)
(map-set attempts {qid: quiz-id, user: tx-sender} {seed: newn, progress: u0, score: u0, done: false, total: total, pass: pass})
            (ok true)
          )
        )
        (let ((newn (+ (nonce-of tx-sender) u1)) (total (quiz-count quiz-id)) (pass (quiz-pass quiz-id)))
          (set-nonce tx-sender newn)
(map-set attempts {qid: quiz-id, user: tx-sender} {seed: newn, progress: u0, score: u0, done: false, total: total, pass: pass})
          (ok true)
        )
      )
    )
  )
)

(define-read-only (next-question (quiz-id uint) (user principal))
  (let ((a (unwrap-panic (map-get? attempts {qid: quiz-id, user: user}))))
    (if (or (get done a) (>= (get progress a) (get total a)))
      (err err-inactive)
      (let ((pos (get progress a)) (seed (get seed a)) (qid (random-question-id quiz-id seed (get progress a))))
        (ok {qid: qid, pos: pos})
      )
    )
  )
)

(define-public (answer-next (quiz-id uint) (answer-index uint))
  (begin
    (let ((a (unwrap! (map-get? attempts {qid: quiz-id, user: tx-sender}) (err err-not-found))))
      (asserts! (not (get done a)) (err err-done))
      (asserts! (< (get progress a) (get total a)) (err err-incomplete))
      (let ((seed (get seed a)) (pos (get progress a)) (score (get score a)) (total (get total a)))
        (let ((qid (random-question-id quiz-id seed pos)))
          (let ((q (unwrap! (map-get? questions {id: qid}) (err err-not-found))))
            (asserts! (< answer-index (get answers q)) (err err-bad-arg))
            (let ((correct (is-eq answer-index (get correct q))) (new-score (+ score (if (is-eq answer-index (get correct q)) u1 u0))) (new-prog (+ pos u1)))
              (map-set attempts {qid: quiz-id, user: tx-sender} {seed: seed, progress: new-prog, score: new-score, done: (>= new-prog total), total: total, pass: (get pass a)})
              (ok {correct: correct, progress: new-prog, total: total, done: (>= new-prog total)})
            )
          )
        )
      )
    )
  )
)

(define-public (finalize-attempt (quiz-id uint))
  (begin
    (let ((a (unwrap! (map-get? attempts {qid: quiz-id, user: tx-sender}) (err err-not-found))))
      (asserts! (get done a) (err err-incomplete))
      (let ((okpass (>= (get score a) (get pass a))))
        (if okpass
          (begin
            (asserts! (is-none (map-get? badges {qid: quiz-id, user: tx-sender})) (err err-already-badged))
            (map-set badges {qid: quiz-id, user: tx-sender} {ok: true})
            (ok true)
          )
          (ok false)
        )
      )
    )
  )
)

(define-read-only (attempt-stats (quiz-id uint) (user principal))
  (let ((a (unwrap! (map-get? attempts {qid: quiz-id, user: user}) (err err-not-found))))
    (ok {progress: (get progress a), total: (get total a), score: (get score a), pass: (get pass a), done: (get done a)})
  )
)

(define-read-only (quiz-size (quiz-id uint)) (ok (quiz-count quiz-id)))

(define-read-only (question-summary (id uint))
  (let ((q (unwrap! (map-get? questions {id: id}) (err err-not-found))))
    (ok {answers: (get answers q), correct: (get correct q)})
  )
)


