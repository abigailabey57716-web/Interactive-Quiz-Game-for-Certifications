# Interactive Quiz Game for Certifications

On-chain interactive quizzes with randomized question order. Passing scores mint a badge recorded on-chain for the user.

## Features ✨
- Randomized question order per attempt using a deterministic seed
- Owner-managed questions and quizzes
- Attempts with progress and scoring
- Badge minting upon passing

## Contract
- Path: contracts/Interactive-Quiz-Game-for-Certification.clar

## Key Public/Read-Only Functions 🧩
- add-question (id, prompt, answers-list, correct-index) -> add a question
- set-quiz-meta (quiz-id, count, pass) -> configure quiz size and passing score
- set-quiz-question (quiz-id, pos, question-id) -> assign a question to a quiz position
- start-attempt (quiz-id) -> begin a new attempt for the caller
- next-question (quiz-id, user) -> read-only: returns the next randomized question id and position
- answer-next (quiz-id, answer-index) -> submit an answer for the next question
- finalize-attempt (quiz-id) -> finalize and mint a badge if passed
- attempt-stats (quiz-id, user) -> read-only: returns progress, total, score, pass, done
- has-badge (quiz-id, user) -> read-only: returns whether the user has a badge

## Usage with Clarinet ▶️
1) Install and open a console
```
clarinet console
```

2) Set the contract identifier for convenience
```
(define-constant c .Interactive-Quiz-Game-for-Certification)
```

3) Add questions (owner only)
```
(contract-call? c add-question u1 "What is 2+2?" (list "3" "4" "5") u1)
(contract-call? c add-question u2 "Color of the sky?" (list "Blue" "Green" "Red") u0)
(contract-call? c add-question u3 "Stacking token?" (list "BTC" "STX" "ETH") u1)
```

4) Configure a quiz (owner only)
```
(contract-call? c set-quiz-meta u10 u3 u2)
(contract-call? c set-quiz-question u10 u0 u1)
(contract-call? c set-quiz-question u10 u1 u2)
(contract-call? c set-quiz-question u10 u2 u3)
```

5) Start an attempt
```
(contract-call? c start-attempt u10)
```

6) Read the next question
```
(read-only-call? c next-question u10 tx-sender)
```

7) Answer the next question by index (0-based)
```
(contract-call? c answer-next u10 u1)
```

8) Repeat step 6-7 until done, then finalize
```
(contract-call? c finalize-attempt u10)
```

9) Check badge and attempt stats
```
(read-only-call? c has-badge u10 tx-sender)
(read-only-call? c attempt-stats u10 tx-sender)
```

## Line Endings 🧰
Ensure files use LF only. On Windows PowerShell, normalize like this (run for each file):
```
(Get-Content "contracts/Interactive-Quiz-Game-for-Certification.clar" -Raw).Replace("`r`n", "`n") | Set-Content "contracts/Interactive-Quiz-Game-for-Certification.clar" -NoNewline
(Get-Content "README.md" -Raw).Replace("`r`n", "`n") | Set-Content "README.md" -NoNewline
```

## Compile ✅
```
clarinet check
```

