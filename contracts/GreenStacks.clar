;; title: GreenStacks Carbon Offset Token Contract
;; version: 1.0.0
;; summary: Tokenized carbon offsets with verification and retirement
;; description: A comprehensive smart contract for minting, trading, and retiring verified carbon offset tokens with transparent audit trails and anti-greenwashing measures

;; traits
(use-trait sip-010-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

;; token definitions
(define-fungible-token carbon-token)

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-INVALID-AMOUNT (err u400))
(define-constant ERR-INSUFFICIENT-BALANCE (err u402))
(define-constant ERR-PROJECT-NOT-FOUND (err u404))
(define-constant ERR-ALREADY-RETIRED (err u409))
(define-constant ERR-INVALID-PRICE (err u403))
(define-constant ERR-LISTING-NOT-FOUND (err u405))
(define-constant ERR-NOT-LISTING-OWNER (err u406))
(define-constant ERR-CANNOT-BUY-OWN-LISTING (err u407))
(define-constant ERR-INVALID-PROJECT-ID (err u408))

(define-constant TREASURY-FEE u250) ;; 2.5% fee (250 basis points)
(define-constant BASIS-POINTS u10000)

;; data vars
(define-data-var next-project-id uint u1)
(define-data-var next-listing-id uint u1)
(define-data-var treasury-address principal CONTRACT-OWNER)
(define-data-var total-retired uint u0)

;; data maps
(define-map carbon-projects
  uint
  {
    name: (string-ascii 64),
    location: (string-ascii 64),
    methodology: (string-ascii 32),
    vintage-year: uint,
    verifier: (string-ascii 32),
    total-credits: uint,
    issued-credits: uint,
    project-owner: principal,
    verified: bool,
    metadata-uri: (string-ascii 256)
  }
)

(define-map project-audits
  { project-id: uint, audit-id: uint }
  {
    auditor: principal,
    audit-date: uint,
    audit-hash: (buff 32),
    status: (string-ascii 16)
  }
)

(define-map marketplace-listings
  uint
  {
    seller: principal,
    amount: uint,
    price-per-token: uint,
    project-id: uint,
    created-at: uint,
    active: bool
  }
)

(define-map retirement-records
  { user: principal, retirement-id: uint }
  {
    amount: uint,
    project-id: uint,
    retired-at: uint,
    reason: (string-ascii 128),
    proof-hash: (buff 32)
  }
)

(define-map user-retirement-counter principal uint)
(define-map project-audit-counter uint uint)
(define-map authorized-verifiers principal bool)
(define-map user-balances-by-project { user: principal, project-id: uint } uint)


;; public functions

;; Initialize authorized verifiers
(define-public (add-authorized-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-verifiers verifier true))
  )
)

;; Create a new carbon offset project
(define-public (create-project 
  (name (string-ascii 64))
  (location (string-ascii 64)) 
  (methodology (string-ascii 32))
  (vintage-year uint)
  (verifier (string-ascii 32))
  (total-credits uint)
  (metadata-uri (string-ascii 256)))
  (let ((project-id (var-get next-project-id)))
    (asserts! (> total-credits u0) ERR-INVALID-AMOUNT)
    (map-set carbon-projects project-id {
      name: name,
      location: location,
      methodology: methodology,
      vintage-year: vintage-year,
      verifier: verifier,
      total-credits: total-credits,
      issued-credits: u0,
      project-owner: tx-sender,
      verified: false,
      metadata-uri: metadata-uri
    })
    (var-set next-project-id (+ project-id u1))
    (ok project-id)
  )
)

;; Verify a project (only authorized verifiers)
(define-public (verify-project (project-id uint))
  (let ((project (unwrap! (map-get? carbon-projects project-id) ERR-PROJECT-NOT-FOUND)))
    (asserts! (default-to false (map-get? authorized-verifiers tx-sender)) ERR-NOT-AUTHORIZED)
    (map-set carbon-projects project-id (merge project { verified: true }))
    (ok true)
  )
)

;; Mint carbon tokens for verified projects
(define-public (mint-tokens (project-id uint) (amount uint) (recipient principal))
  (let ((project (unwrap! (map-get? carbon-projects project-id) ERR-PROJECT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get project-owner project)) ERR-NOT-AUTHORIZED)
    (asserts! (get verified project) ERR-NOT-AUTHORIZED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (<= (+ (get issued-credits project) amount) (get total-credits project)) ERR-INVALID-AMOUNT)
    
    ;; Update project issued credits
    (map-set carbon-projects project-id 
      (merge project { issued-credits: (+ (get issued-credits project) amount) }))
    
    ;; Update user balance by project
    (map-set user-balances-by-project 
      { user: recipient, project-id: project-id }
      (+ amount (default-to u0 (map-get? user-balances-by-project { user: recipient, project-id: project-id }))))
    
    ;; Mint tokens
    (ft-mint? carbon-token amount recipient)
  )
)

;; Create marketplace listing
(define-public (create-listing (amount uint) (price-per-token uint) (project-id uint))
  (let ((listing-id (var-get next-listing-id))
        (user-balance (default-to u0 (map-get? user-balances-by-project { user: tx-sender, project-id: project-id }))))
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (> price-per-token u0) ERR-INVALID-PRICE)
    (asserts! (>= user-balance amount) ERR-INSUFFICIENT-BALANCE)
    (asserts! (is-some (map-get? carbon-projects project-id)) ERR-PROJECT-NOT-FOUND)
    
    (map-set marketplace-listings listing-id {
      seller: tx-sender,
      amount: amount,
      price-per-token: price-per-token,
      project-id: project-id,
      created-at: block-height,
      active: true
    })
    (var-set next-listing-id (+ listing-id u1))
    (ok listing-id)
  )
)

;; Buy from marketplace
(define-public (buy-listing (listing-id uint) (amount uint))
  (let ((listing (unwrap! (map-get? marketplace-listings listing-id) ERR-LISTING-NOT-FOUND))
        (total-price (* amount (get price-per-token listing)))
        (treasury-fee-amount (/ (* total-price TREASURY-FEE) BASIS-POINTS))
        (seller-amount (- total-price treasury-fee-amount)))
    
    (asserts! (get active listing) ERR-LISTING-NOT-FOUND)
    (asserts! (not (is-eq tx-sender (get seller listing))) ERR-CANNOT-BUY-OWN-LISTING)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (<= amount (get amount listing)) ERR-INVALID-AMOUNT)
    
    ;; Transfer STX to seller and treasury
    (try! (stx-transfer? seller-amount tx-sender (get seller listing)))
    (try! (stx-transfer? treasury-fee-amount tx-sender (var-get treasury-address)))
    
    ;; Update balances
    (map-set user-balances-by-project 
      { user: (get seller listing), project-id: (get project-id listing) }
      (- (default-to u0 (map-get? user-balances-by-project 
          { user: (get seller listing), project-id: (get project-id listing) })) amount))
    
    (map-set user-balances-by-project 
      { user: tx-sender, project-id: (get project-id listing) }
      (+ amount (default-to u0 (map-get? user-balances-by-project 
          { user: tx-sender, project-id: (get project-id listing) }))))
    
    ;; Transfer tokens
    (try! (ft-transfer? carbon-token amount (get seller listing) tx-sender))
    
    ;; Update or remove listing
    (if (is-eq amount (get amount listing))
      (map-set marketplace-listings listing-id (merge listing { active: false }))
      (map-set marketplace-listings listing-id (merge listing { amount: (- (get amount listing) amount) })))
    
    (ok true)
  )
)

;; Cancel marketplace listing
(define-public (cancel-listing (listing-id uint))
  (let ((listing (unwrap! (map-get? marketplace-listings listing-id) ERR-LISTING-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get seller listing)) ERR-NOT-LISTING-OWNER)
    (asserts! (get active listing) ERR-LISTING-NOT-FOUND)
    
    (map-set marketplace-listings listing-id (merge listing { active: false }))
    (ok true)
  )
)

;; Retire carbon tokens
(define-public (retire-tokens (amount uint) (project-id uint) (reason (string-ascii 128)) (proof-hash (buff 32)))
  (let ((user-balance (default-to u0 (map-get? user-balances-by-project { user: tx-sender, project-id: project-id })))
        (retirement-counter (default-to u0 (map-get? user-retirement-counter tx-sender))))
    
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (>= user-balance amount) ERR-INSUFFICIENT-BALANCE)
    (asserts! (is-some (map-get? carbon-projects project-id)) ERR-PROJECT-NOT-FOUND)
    
    ;; Update balances
    (map-set user-balances-by-project 
      { user: tx-sender, project-id: project-id } 
      (- user-balance amount))
    
    ;; Burn tokens
    (try! (ft-burn? carbon-token amount tx-sender))
    
    ;; Record retirement
    (map-set retirement-records 
      { user: tx-sender, retirement-id: retirement-counter }
      {
        amount: amount,
        project-id: project-id,
        retired-at: block-height,
        reason: reason,
        proof-hash: proof-hash
      })
    
    (map-set user-retirement-counter tx-sender (+ retirement-counter u1))
    (var-set total-retired (+ (var-get total-retired) amount))
    
    (ok retirement-counter)
  )
)

;; Add project audit
(define-public (add-project-audit (project-id uint) (audit-hash (buff 32)) (status (string-ascii 16)))
  (let ((audit-counter (default-to u0 (map-get? project-audit-counter project-id))))
    (asserts! (default-to false (map-get? authorized-verifiers tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? carbon-projects project-id)) ERR-PROJECT-NOT-FOUND)
    
    (map-set project-audits 
      { project-id: project-id, audit-id: audit-counter }
      {
        auditor: tx-sender,
        audit-date: block-height,
        audit-hash: audit-hash,
        status: status
      })
    
    (map-set project-audit-counter project-id (+ audit-counter u1))
    (ok audit-counter)
  )
)

;; Update treasury address
(define-public (set-treasury-address (new-treasury principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set treasury-address new-treasury)
    (ok true)
  )
)

;; Transfer tokens between users
(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
  (begin
    (asserts! (or (is-eq tx-sender from) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (ft-transfer? carbon-token amount from to)
  )
)