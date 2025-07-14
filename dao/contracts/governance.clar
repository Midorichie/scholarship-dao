;; Governance Contract - Additional functionality for the DAO
;; Allows voting on system parameters and admin changes

(define-data-var current-admin principal tx-sender)
(define-data-var pending-admin (optional principal) none)
(define-data-var admin-change-votes uint u0)
(define-data-var admin-change-threshold uint u5)
(define-data-var governance-proposal-counter uint u0)

;; Maps for governance proposals
(define-map governance-proposals 
  uint 
  {
    proposal-type: (string-ascii 20),
    target: principal,
    description: (string-ascii 200),
    votes: uint,
    executed: bool,
    created-at: uint,
    deadline: uint
  }
)

(define-map governance-votes 
  {proposal-id: uint, voter: principal} 
  bool
)

(define-map authorized-voters principal bool)

;; Constants
(define-constant err-not-admin (err u200))
(define-constant err-not-authorized (err u201))
(define-constant err-invalid-proposal (err u202))
(define-constant err-already-voted (err u203))
(define-constant err-proposal-expired (err u204))
(define-constant err-already-executed (err u205))
(define-constant err-insufficient-votes (err u206))
(define-constant err-invalid-principal (err u207))
(define-constant err-empty-description (err u208))
(define-constant err-invalid-proposal-id (err u209))

;; Initialize admin as authorized voter
(map-set authorized-voters tx-sender true)

;; Admin functions
(define-public (add-authorized-voter (voter principal))
  (begin
    (asserts! (is-eq tx-sender (var-get current-admin)) err-not-admin)
    ;; Validate voter is not the zero/null principal
    (asserts! (not (is-eq voter 'SP000000000000000000002Q6VF78)) err-invalid-principal)
    (map-set authorized-voters voter true)
    (ok true)
  )
)

(define-public (remove-authorized-voter (voter principal))
  (begin
    (asserts! (is-eq tx-sender (var-get current-admin)) err-not-admin)
    (asserts! (not (is-eq voter (var-get current-admin))) err-not-admin)
    ;; Validate voter is not the zero/null principal
    (asserts! (not (is-eq voter 'SP000000000000000000002Q6VF78)) err-invalid-principal)
    (map-set authorized-voters voter false)
    (ok true)
  )
)

;; Propose admin change (enhanced validation)
(define-public (propose-admin-change (new-admin principal) (description (string-ascii 200)))
  (begin
    (asserts! (default-to false (map-get? authorized-voters tx-sender)) err-not-authorized)
    ;; Validate new admin is not the zero/null principal
    (asserts! (not (is-eq new-admin 'SP000000000000000000002Q6VF78)) err-invalid-principal)
    ;; Validate new admin is different from current admin
    (asserts! (not (is-eq new-admin (var-get current-admin))) err-invalid-principal)
    ;; Validate description is not empty
    (asserts! (> (len description) u0) err-empty-description)
    
    (let ((id (var-get governance-proposal-counter)))
      (map-set governance-proposals id
        {
          proposal-type: "admin-change",
          target: new-admin,
          description: description,
          votes: u0,
          executed: false,
          created-at: block-height,
          deadline: (+ block-height u1440) ;; ~10 days
        })
      (var-set governance-proposal-counter (+ id u1))
      (ok id)
    )
  )
)

;; Vote on governance proposal (enhanced validation)
(define-public (vote-governance (proposal-id uint))
  (begin
    (asserts! (default-to false (map-get? authorized-voters tx-sender)) err-not-authorized)
    (asserts! (is-none (map-get? governance-votes {proposal-id: proposal-id, voter: tx-sender})) err-already-voted)
    ;; Validate proposal ID exists
    (asserts! (< proposal-id (var-get governance-proposal-counter)) err-invalid-proposal-id)
    
    (match (map-get? governance-proposals proposal-id)
      proposal
        (begin
          (asserts! (not (get executed proposal)) err-already-executed)
          (asserts! (<= block-height (get deadline proposal)) err-proposal-expired)
          
          ;; Record vote
          (map-set governance-votes {proposal-id: proposal-id, voter: tx-sender} true)
          
          ;; Update vote count
          (map-set governance-proposals proposal-id
            (merge proposal {votes: (+ (get votes proposal) u1)}))
          (ok true)
        )
      err-invalid-proposal
    )
  )
)

;; Execute governance proposal (enhanced validation)
(define-public (execute-governance-proposal (proposal-id uint))
  (begin
    ;; Validate proposal ID exists
    (asserts! (< proposal-id (var-get governance-proposal-counter)) err-invalid-proposal-id)
    
    (match (map-get? governance-proposals proposal-id)
      proposal
        (begin
          (asserts! (not (get executed proposal)) err-already-executed)
          (asserts! (>= (get votes proposal) (var-get admin-change-threshold)) err-insufficient-votes)
          
          ;; Execute based on proposal type
          (if (is-eq (get proposal-type proposal) "admin-change")
              (begin
                ;; Additional validation for admin change
                (asserts! (not (is-eq (get target proposal) 'SP000000000000000000002Q6VF78)) err-invalid-principal)
                (var-set current-admin (get target proposal))
                (map-set governance-proposals proposal-id
                  (merge proposal {executed: true}))
                (ok true)
              )
              (ok false) ;; Other proposal types can be added here
          )
        )
      err-invalid-proposal
    )
  )
)

;; Read-only functions
(define-read-only (get-governance-proposal (id uint))
  (map-get? governance-proposals id)
)

(define-read-only (get-governance-vote-status (id uint) (voter principal))
  (default-to false (map-get? governance-votes {proposal-id: id, voter: voter}))
)

(define-read-only (is-authorized-voter (user principal))
  (default-to false (map-get? authorized-voters user))
)

(define-read-only (get-current-admin)
  (var-get current-admin)
)

(define-read-only (get-admin-change-threshold)
  (var-get admin-change-threshold)
)

(define-read-only (get-governance-proposal-count)
  (var-get governance-proposal-counter)
)
