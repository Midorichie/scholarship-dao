;; Enhanced Scholarship DAO Contract
;; Phase 2: Bug fixes, security enhancements, and new functionality

(define-data-var admin principal tx-sender)
(define-data-var proposal-counter uint u0)
(define-data-var vote-threshold uint u3)
(define-data-var contract-balance uint u0)

;; Maps
(define-map proposals 
  uint 
  {
    description: (string-ascii 100),
    amount: uint,
    recipient: principal,
    votes: uint,
    approved: bool,
    created-at: uint,
    deadline: uint
  }
)

(define-map votes 
  {proposal-id: uint, voter: principal} 
  bool
)

(define-map members principal bool)

;; Constants
(define-constant err-not-admin (err u100))
(define-constant err-invalid-id (err u101))
(define-constant err-already-approved (err u102))
(define-constant err-not-member (err u103))
(define-constant err-already-voted (err u104))
(define-constant err-insufficient-funds (err u105))
(define-constant err-proposal-expired (err u106))
(define-constant err-invalid-amount (err u107))
(define-constant err-invalid-threshold (err u108))
(define-constant err-invalid-principal (err u109))
(define-constant err-invalid-duration (err u110))
(define-constant err-empty-description (err u111))

;; Initialize admin as first member
(map-set members tx-sender true)

;; Admin functions
(define-public (add-member (member principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) err-not-admin)
    ;; Validate that member is not the zero/null principal
    (asserts! (not (is-eq member 'SP000000000000000000002Q6VF78)) err-invalid-principal)
    (map-set members member true)
    (ok true)
  )
)

(define-public (remove-member (member principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) err-not-admin)
    (asserts! (not (is-eq member (var-get admin))) err-not-admin) ;; Can't remove admin
    ;; Validate that member is not the zero/null principal
    (asserts! (not (is-eq member 'SP000000000000000000002Q6VF78)) err-invalid-principal)
    (map-set members member false)
    (ok true)
  )
)

(define-public (set-vote-threshold (threshold uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) err-not-admin)
    (asserts! (> threshold u0) err-invalid-threshold)
    (asserts! (<= threshold u100) err-invalid-threshold) ;; Reasonable upper limit
    (var-set vote-threshold threshold)
    (ok true)
  )
)

(define-public (deposit-funds (amount uint))
  (begin
    ;; Validate amount is reasonable (not zero, not excessively large)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (<= amount u1000000000000) err-invalid-amount) ;; 1M STX max per deposit
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set contract-balance (+ (var-get contract-balance) amount))
    (ok true)
  )
)

;; Submit a new proposal (enhanced validation)
(define-public (submit-proposal (desc (string-ascii 100)) (amount uint) (recipient principal) (duration uint))
  (begin
    (asserts! (default-to false (map-get? members tx-sender)) err-not-member)
    ;; Validate amount
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (<= amount u100000000000) err-invalid-amount) ;; 100K STX max per proposal
    ;; Validate duration
    (asserts! (> duration u0) err-invalid-duration)
    (asserts! (<= duration u10080) err-invalid-duration) ;; Max 1 week (10080 blocks)
    ;; Validate recipient
    (asserts! (not (is-eq recipient 'SP000000000000000000002Q6VF78)) err-invalid-principal)
    ;; Validate description is not empty
    (asserts! (> (len desc) u0) err-empty-description)
    
    (let ((id (var-get proposal-counter))
          (current-height block-height))
      (map-set proposals id
        {
          description: desc,
          amount: amount,
          recipient: recipient,
          votes: u0,
          approved: false,
          created-at: current-height,
          deadline: (+ current-height duration)
        })
      (var-set proposal-counter (+ id u1))
      (ok id)
    )
  )
)

;; Vote on a proposal (enhanced validation)
(define-public (vote (id uint))
  (begin
    (asserts! (default-to false (map-get? members tx-sender)) err-not-member)
    (asserts! (is-none (map-get? votes {proposal-id: id, voter: tx-sender})) err-already-voted)
    ;; Validate proposal ID exists
    (asserts! (< id (var-get proposal-counter)) err-invalid-id)
    
    (match (map-get? proposals id)
      proposal
        (begin
          (asserts! (not (get approved proposal)) err-already-approved)
          (asserts! (<= block-height (get deadline proposal)) err-proposal-expired)
          
          ;; Record the vote
          (map-set votes {proposal-id: id, voter: tx-sender} true)
          
          ;; Update proposal vote count
          (map-set proposals id
            (merge proposal {votes: (+ (get votes proposal) u1)}))
          (ok true)
        )
      err-invalid-id
    )
  )
)

;; Admin approves and disburses funds (enhanced security)
(define-public (approve-and-disburse (id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) err-not-admin)
    ;; Validate proposal ID exists
    (asserts! (< id (var-get proposal-counter)) err-invalid-id)
    
    (match (map-get? proposals id)
      proposal
        (begin
          (asserts! (not (get approved proposal)) err-already-approved)
          (asserts! (>= (get votes proposal) (var-get vote-threshold)) (err u200)) ;; Not enough votes
          (asserts! (>= (var-get contract-balance) (get amount proposal)) err-insufficient-funds)
          
          ;; Update proposal status
          (map-set proposals id (merge proposal {approved: true}))
          
          ;; Transfer funds and update balance
          (try! (as-contract (stx-transfer? (get amount proposal) tx-sender (get recipient proposal))))
          (var-set contract-balance (- (var-get contract-balance) (get amount proposal)))
          
          (ok true)
        )
      err-invalid-id
    )
  )
)

;; Read-only functions
(define-read-only (get-proposal (id uint))
  (map-get? proposals id)
)

(define-read-only (get-vote-status (id uint) (voter principal))
  (default-to false (map-get? votes {proposal-id: id, voter: voter}))
)

(define-read-only (is-member (user principal))
  (default-to false (map-get? members user))
)

(define-read-only (get-contract-balance)
  (var-get contract-balance)
)

(define-read-only (get-vote-threshold)
  (var-get vote-threshold)
)

(define-read-only (get-admin)
  (var-get admin)
)

(define-read-only (get-proposal-count)
  (var-get proposal-counter)
)
