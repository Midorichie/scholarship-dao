(define-data-var admin principal tx-sender)
(define-map proposals (tuple (id uint)) (tuple (description (string-ascii 100)) (amount uint) (recipient principal) (votes uint) (approved bool)))
(define-data-var proposal-counter uint u0)

(define-constant err-not-admin (err u100))
(define-constant err-invalid-id (err u101))
(define-constant err-already-approved (err u102))

;; Submit a new proposal
(define-public (submit-proposal (desc (string-ascii 100)) (amount uint) (recipient principal))
  (begin
    (let ((id (var-get proposal-counter)))
      (map-set proposals (tuple (id id))
        (tuple (description desc) (amount amount) (recipient recipient) (votes u0) (approved false)))
      (var-set proposal-counter (+ id u1))
      (ok id)
    )
  )
)

;; Vote on a proposal
(define-public (vote (id uint))
  (match (map-get proposals (tuple (id id)))
    proposal =>
      (if (get approved proposal)
          err-already-approved
          (begin
            (map-set proposals (tuple (id id))
              (tuple 
                (description (get description proposal))
                (amount (get amount proposal))
                (recipient (get recipient proposal))
                (votes (+ (get votes proposal) u1))
                (approved false)))
            (ok true)
          )
      )
    err-invalid-id
  )
)

;; Admin approves and disburses funds if vote threshold met
(define-public (approve-and-disburse (id uint))
  (begin
    (if (is-eq tx-sender (var-get admin))
        (match (map-get proposals (tuple (id id)))
          proposal =>
            (if (>= (get votes proposal) u3)
                (begin
                  (map-set proposals (tuple (id id))
                    (tuple 
                      (description (get description proposal))
                      (amount (get amount proposal))
                      (recipient (get recipient proposal))
                      (votes (get votes proposal))
                      (approved true)))
                  (stx-transfer? (get amount proposal) tx-sender (get recipient proposal))
                )
                (err u200) ;; Not enough votes
            )
          err-invalid-id
        )
        err-not-admin
    )
  )
)
