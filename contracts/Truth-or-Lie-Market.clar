;; Truth-or-Lie Market Contract
;; Users submit claims and stake tokens on true/false outcomes

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u404))
(define-constant err-already-resolved (err u400))
(define-constant err-insufficient-funds (err u401))
(define-constant err-unauthorized (err u403))
(define-constant err-invalid-outcome (err u405))

;; Data Variables
(define-data-var next-claim-id uint u1)

;; Data Maps
(define-map claims
  { claim-id: uint }
  {
    submitter: principal,
    description: (string-ascii 500),
    total-true-stakes: uint,
    total-false-stakes: uint,
    resolved: bool,
    outcome: (optional bool),
    created-at: uint
  }
)

(define-map stakes
  { claim-id: uint, staker: principal }
  {
    true-amount: uint,
    false-amount: uint,
    claimed: bool
  }
)

;; Read-only functions
(define-read-only (get-claim (claim-id uint))
  (map-get? claims { claim-id: claim-id })
)

(define-read-only (get-stake (claim-id uint) (staker principal))
  (map-get? stakes { claim-id: claim-id, staker: staker })
)

(define-read-only (get-next-claim-id)
  (var-get next-claim-id)
)

(define-read-only (calculate-payout (claim-id uint) (staker principal))
  (let (
    (claim-data (unwrap! (get-claim claim-id) err-not-found))
    (stake-data (unwrap! (get-stake claim-id staker) err-not-found))
  )
    (ok (if (get resolved claim-data)
      (match (get outcome claim-data)
        outcome-value (if outcome-value
                       (if (> (get true-amount stake-data) u0)
                         (some (+ (get true-amount stake-data) 
                                 (/ (* (get true-amount stake-data) (get total-false-stakes claim-data))
                                    (get total-true-stakes claim-data))))
                         (some u0))
                       (if (> (get false-amount stake-data) u0)
                         (some (+ (get false-amount stake-data)
                                 (/ (* (get false-amount stake-data) (get total-true-stakes claim-data))
                                    (get total-false-stakes claim-data))))
                         (some u0)))
        (some u0))
      none))
  )
)

;; Public functions
(define-public (submit-claim (description (string-ascii 500)))
  (let (
    (claim-id (var-get next-claim-id))
  )
    (map-set claims
      { claim-id: claim-id }
      {
        submitter: tx-sender,
        description: description,
        total-true-stakes: u0,
        total-false-stakes: u0,
        resolved: false,
        outcome: none,
        created-at: block-height
      }
    )
    (var-set next-claim-id (+ claim-id u1))
    (ok claim-id)
  )
)

(define-public (stake-true (claim-id uint) (amount uint))
  (let (
    (claim-data (unwrap! (get-claim claim-id) err-not-found))
    (existing-stake (default-to { true-amount: u0, false-amount: u0, claimed: false }
                                (get-stake claim-id tx-sender)))
  )
    (asserts! (not (get resolved claim-data)) err-already-resolved)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

    (map-set stakes
      { claim-id: claim-id, staker: tx-sender }
      {
        true-amount: (+ (get true-amount existing-stake) amount),
        false-amount: (get false-amount existing-stake),
        claimed: false
      }
    )

    (map-set claims
      { claim-id: claim-id }
      (merge claim-data { total-true-stakes: (+ (get total-true-stakes claim-data) amount) })
    )

    (ok true)
  )
)

(define-public (stake-false (claim-id uint) (amount uint))
  (let (
    (claim-data (unwrap! (get-claim claim-id) err-not-found))
    (existing-stake (default-to { true-amount: u0, false-amount: u0, claimed: false }
                                (get-stake claim-id tx-sender)))
  )
    (asserts! (not (get resolved claim-data)) err-already-resolved)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

    (map-set stakes
      { claim-id: claim-id, staker: tx-sender }
      {
        true-amount: (get true-amount existing-stake),
        false-amount: (+ (get false-amount existing-stake) amount),
        claimed: false
      }
    )

    (map-set claims
      { claim-id: claim-id }
      (merge claim-data { total-false-stakes: (+ (get total-false-stakes claim-data) amount) })
    )

    (ok true)
  )
)

(define-public (resolve-claim (claim-id uint) (outcome bool))
  (let (
    (claim-data (unwrap! (get-claim claim-id) err-not-found))
  )
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (asserts! (not (get resolved claim-data)) err-already-resolved)

    (map-set claims
      { claim-id: claim-id }
      (merge claim-data { resolved: true, outcome: (some outcome) })
    )

    (ok true)
  )
)

(define-public (claim-payout (claim-id uint))
  (let (
    (claim-data (unwrap! (get-claim claim-id) err-not-found))
    (stake-data (unwrap! (get-stake claim-id tx-sender) err-not-found))
    (payout-amount (unwrap! (calculate-payout claim-id tx-sender) err-not-found))
  )
    (asserts! (get resolved claim-data) err-not-found)
    (asserts! (not (get claimed stake-data)) err-already-resolved)

    (map-set stakes
      { claim-id: claim-id, staker: tx-sender }
      (merge stake-data { claimed: true })
    )

    (match payout-amount
      amount (if (> amount u0)
               (as-contract (stx-transfer? amount tx-sender tx-sender))
               (ok true))
      (ok true)
    )
  )
)