;; title: GreenStacks Carbon Offset Token Contract
;; version: 2.0.0
;; summary: Tokenized carbon offsets with verification and retirement
;; description: A comprehensive smart contract for minting, trading, and retiring verified carbon offset tokens with transparent audit trails and anti-greenwashing measures

;; traits
;; (use-trait sip-010-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

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
(define-constant ERR-CONTRACT-PAUSED (err u410))
(define-constant ERR-INVALID-INPUT (err u411))
(define-constant ERR-OVERFLOW (err u412))
(define-constant ERR-UNDERFLOW (err u413))
(define-constant ERR-INVALID-VINTAGE-YEAR (err u414))
(define-constant ERR-PRICE-TOO-HIGH (err u415))
(define-constant ERR-INVALID-REASON (err u416))
(define-constant ERR-DUPLICATE-AUDIT (err u417))
(define-constant ERR-INVALID-METHODOLOGY (err u418))
(define-constant ERR-INVALID-LOCATION (err u419))
(define-constant ERR-INVALID-NAME (err u420))
(define-constant ERR-RATE-LIMIT-EXCEEDED (err u421))
(define-constant ERR-DUPLICATE-PROJECT-NAME (err u422))
(define-constant ERR-INVALID-TIMESTAMP (err u423))

(define-constant TREASURY-FEE u250) ;; 2.5% fee (250 basis points)
(define-constant BASIS-POINTS u10000)
(define-constant MAX-PRICE u1000000000000) ;; Maximum price per token (1M STX)
(define-constant MIN-VINTAGE-YEAR u1990)
(define-constant MAX-VINTAGE-YEAR u2100)
(define-constant MAX-STRING-LENGTH u64)
(define-constant MAX-REASON-LENGTH u128)
(define-constant MAX-METADATA-LENGTH u256)
(define-constant RATE-LIMIT-BLOCKS u10) ;; Minimum blocks between operations
(define-constant MAX-OPERATIONS-PER-BLOCK u5)

;; data vars
(define-data-var next-project-id uint u1)
(define-data-var next-listing-id uint u1)
(define-data-var treasury-address principal CONTRACT-OWNER)
(define-data-var total-retired uint u0)
(define-data-var contract-paused bool false)
(define-data-var max-mint-per-transaction uint u1000000)
(define-data-var max-listing-amount uint u10000000)

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
(define-map audit-hashes (buff 32) bool) ;; Prevent duplicate audits
(define-map nonce-map principal uint) ;; Anti-replay protection
(define-map project-names (string-ascii 64) bool) ;; Track unique project names
(define-map last-operation-block principal uint) ;; Rate limiting
(define-map operations-per-block { user: principal, block: uint } uint) ;; Operations counter

;; Security helper functions
(define-private (check-not-paused)
  (if (var-get contract-paused)
    (err ERR-CONTRACT-PAUSED)
    (ok true)
  )
)

(define-private (safe-add (a uint) (b uint))
  (let ((result (+ a b)))
    (asserts! (>= result a) ERR-OVERFLOW)
    (ok result)
  )
)

(define-private (safe-sub (a uint) (b uint))
  (if (>= a b)
    (ok (- a b))
    (err ERR-UNDERFLOW)
  )
)

(define-private (safe-mul (a uint) (b uint))
  (let ((result (* a b)))
    (asserts! (or (is-eq b u0) (is-eq (/ result b) a)) ERR-OVERFLOW)
    (ok result)
  )
)

(define-private (validate-string-length (str (string-ascii 256)) (max-length uint))
  (if (<= (len str) max-length)
    (ok true)
    (err ERR-INVALID-INPUT)
  )
)

(define-private (validate-vintage-year (year uint))
  (if (and (>= year MIN-VINTAGE-YEAR) (<= year MAX-VINTAGE-YEAR))
    (ok true)
    (err ERR-INVALID-VINTAGE-YEAR)
  )
)

(define-private (validate-price (price uint))
  (if (and (> price u0) (<= price MAX-PRICE))
    (ok true)
    (err ERR-PRICE-TOO-HIGH)
  )
)

(define-private (validate-amount (amount uint))
  (if (and (> amount u0) (<= amount (var-get max-mint-per-transaction)))
    (ok true)
    (err ERR-INVALID-AMOUNT)
  )
)

(define-private (validate-listing-amount (amount uint))
  (if (and (> amount u0) (<= amount (var-get max-listing-amount)))
    (ok true)
    (err ERR-INVALID-AMOUNT)
  )
)

(define-private (validate-reason (reason (string-ascii 128)))
  (if (and (> (len reason) u0) (<= (len reason) MAX-REASON-LENGTH))
    (ok true)
    (err ERR-INVALID-REASON)
  )
)

(define-private (validate-name (name (string-ascii 64)))
  (if (and (> (len name) u0) (<= (len name) MAX-STRING-LENGTH))
    (ok true)
    (err ERR-INVALID-NAME)
  )
)

(define-private (validate-location (location (string-ascii 64)))
  (if (and (> (len location) u0) (<= (len location) MAX-STRING-LENGTH))
    (ok true)
    (err ERR-INVALID-LOCATION)
  )
)

(define-private (validate-methodology (methodology (string-ascii 32)))
  (if (and (> (len methodology) u0) (<= (len methodology) u32))
    (ok true)
    (err ERR-INVALID-METHODOLOGY)
  )
)

(define-private (validate-metadata (metadata (string-ascii 256)))
  (if (<= (len metadata) MAX-METADATA-LENGTH)
    (ok true)
    (err ERR-INVALID-INPUT)
  )
)

(define-private (check-duplicate-audit (audit-hash (buff 32)))
  (if (not (default-to false (map-get? audit-hashes audit-hash)))
    (ok true)
    (err ERR-DUPLICATE-AUDIT)
  )
)

(define-private (increment-nonce (user principal))
  (let ((current-nonce (default-to u0 (map-get? nonce-map user))))
    (map-set nonce-map user (+ current-nonce u1))
    (ok current-nonce)
  )
)

(define-private (check-rate-limit (user principal))
  (let (
    (current-block stacks-block-height)
    (last-block (default-to u0 (map-get? last-operation-block user)))
    (ops-count (default-to u0 (map-get? operations-per-block { user: user, block: current-block })))
  )
    ;; Check if enough blocks have passed OR if under per-block limit
    (asserts! 
      (or 
        (>= (- current-block last-block) RATE-LIMIT-BLOCKS)
        (< ops-count MAX-OPERATIONS-PER-BLOCK)
      )
      ERR-RATE-LIMIT-EXCEEDED
    )
    ;; Update counters
    (map-set last-operation-block user current-block)
    (map-set operations-per-block { user: user, block: current-block } (+ ops-count u1))
    (ok true)
  )
)

(define-private (check-unique-project-name (name (string-ascii 64)))
  (if (default-to false (map-get? project-names name))
    (err ERR-DUPLICATE-PROJECT-NAME)
    (ok true)
  )
)

;; public functions

;; Initialize authorized verifiers
(define-public (add-authorized-verifier (verifier principal))
  (begin
    (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq verifier tx-sender)) ERR-INVALID-INPUT)
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
    (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
    (try! (check-rate-limit tx-sender))
    (asserts! (and (> (len name) u0) (<= (len name) MAX-STRING-LENGTH)) ERR-INVALID-NAME)
    (asserts! (not (default-to false (map-get? project-names name))) ERR-DUPLICATE-PROJECT-NAME)
    (asserts! (and (> (len location) u0) (<= (len location) MAX-STRING-LENGTH)) ERR-INVALID-LOCATION)
    (asserts! (and (> (len methodology) u0) (<= (len methodology) u32)) ERR-INVALID-METHODOLOGY)
    (asserts! (and (>= vintage-year MIN-VINTAGE-YEAR) (<= vintage-year MAX-VINTAGE-YEAR)) ERR-INVALID-VINTAGE-YEAR)
    (asserts! (<= (len metadata-uri) MAX-METADATA-LENGTH) ERR-INVALID-INPUT)
    (asserts! (> total-credits u0) ERR-INVALID-AMOUNT)
    (asserts! (<= total-credits (var-get max-mint-per-transaction)) ERR-INVALID-AMOUNT)
    (asserts! (> (len verifier) u0) ERR-INVALID-INPUT)
    (asserts! (<= (len verifier) u32) ERR-INVALID-INPUT)
    
    ;; Register project name
    (map-set project-names name true)
    
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
    (try! (safe-add project-id u1))
    (var-set next-project-id (unwrap! (safe-add project-id u1) ERR-OVERFLOW))
    (ok project-id)
  )
)

;; Verify a project (only authorized verifiers)
(define-public (verify-project (project-id uint))
  (let ((project (unwrap! (map-get? carbon-projects project-id) ERR-PROJECT-NOT-FOUND)))
    (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
    (try! (check-rate-limit tx-sender))
    (asserts! (default-to false (map-get? authorized-verifiers tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (not (get verified project)) ERR-INVALID-INPUT) ;; Prevent re-verification
    (map-set carbon-projects project-id (merge project { verified: true }))
    (ok true)
  )
)

;; Mint carbon tokens for verified projects
(define-public (mint-tokens (project-id uint) (amount uint) (recipient principal))
  (let ((project (unwrap! (map-get? carbon-projects project-id) ERR-PROJECT-NOT-FOUND)))
    (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
    (try! (check-rate-limit tx-sender))
    (asserts! (is-eq tx-sender (get project-owner project)) ERR-NOT-AUTHORIZED)
    (asserts! (get verified project) ERR-NOT-AUTHORIZED)
    (asserts! (and (> amount u0) (<= amount (var-get max-mint-per-transaction))) ERR-INVALID-AMOUNT)
    (asserts! (not (is-eq recipient tx-sender)) ERR-INVALID-INPUT) ;; Prevent self-minting
    (asserts! (not (is-eq recipient CONTRACT-OWNER)) ERR-INVALID-INPUT) ;; Prevent minting to contract owner
    
    (let ((current-issued (get issued-credits project))
          (total-credits (get total-credits project))
          (new-issued (unwrap! (safe-add current-issued amount) ERR-OVERFLOW)))
      (asserts! (<= new-issued total-credits) ERR-INVALID-AMOUNT)
      
      ;; Update project issued credits
      (map-set carbon-projects project-id 
        (merge project { issued-credits: new-issued }))
      
      ;; Update user balance by project
      (let ((current-balance (default-to u0 (map-get? user-balances-by-project { user: recipient, project-id: project-id })))
            (new-balance (unwrap! (safe-add current-balance amount) ERR-OVERFLOW)))
        (map-set user-balances-by-project 
          { user: recipient, project-id: project-id }
          new-balance))
      
      ;; Mint tokens
      (ft-mint? carbon-token amount recipient)
    )
  )
)

;; Create marketplace listing
(define-public (create-listing (amount uint) (price-per-token uint) (project-id uint))
  (let ((listing-id (var-get next-listing-id))
        (user-balance (default-to u0 (map-get? user-balances-by-project { user: tx-sender, project-id: project-id }))))
    (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
    (try! (check-rate-limit tx-sender))
    (asserts! (and (> amount u0) (<= amount (var-get max-listing-amount))) ERR-INVALID-AMOUNT)
    (asserts! (and (> price-per-token u0) (<= price-per-token MAX-PRICE)) ERR-PRICE-TOO-HIGH)
    (asserts! (>= user-balance amount) ERR-INSUFFICIENT-BALANCE)
    (asserts! (is-some (map-get? carbon-projects project-id)) ERR-PROJECT-NOT-FOUND)
    
    (map-set marketplace-listings listing-id {
      seller: tx-sender,
      amount: amount,
      price-per-token: price-per-token,
      project-id: project-id,
      created-at: stacks-block-height,
      active: true
    })
    (var-set next-listing-id (unwrap! (safe-add listing-id u1) ERR-OVERFLOW))
    (ok listing-id)
  )
)

;; Buy from marketplace
(define-public (buy-listing (listing-id uint) (amount uint))
  (let ((listing (unwrap! (map-get? marketplace-listings listing-id) ERR-LISTING-NOT-FOUND)))
    (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
    (try! (check-rate-limit tx-sender))
    (asserts! (get active listing) ERR-LISTING-NOT-FOUND)
    (asserts! (not (is-eq tx-sender (get seller listing))) ERR-CANNOT-BUY-OWN-LISTING)
    (asserts! (and (> amount u0) (<= amount (var-get max-mint-per-transaction))) ERR-INVALID-AMOUNT)
    (asserts! (<= amount (get amount listing)) ERR-INVALID-AMOUNT)
    
    (let ((price-per-token (get price-per-token listing))
          (total-price (unwrap! (safe-mul amount price-per-token) ERR-OVERFLOW))
          (treasury-fee-amount (/ (* total-price TREASURY-FEE) BASIS-POINTS))
          (seller-amount (unwrap! (safe-sub total-price treasury-fee-amount) ERR-UNDERFLOW)))
      
      ;; Update balances FIRST (before external calls) - prevents reentrancy
      (let ((seller-balance (default-to u0 (map-get? user-balances-by-project 
              { user: (get seller listing), project-id: (get project-id listing) })))
            (buyer-balance (default-to u0 (map-get? user-balances-by-project 
              { user: tx-sender, project-id: (get project-id listing) }))))
        
        (map-set user-balances-by-project 
          { user: (get seller listing), project-id: (get project-id listing) }
          (unwrap! (safe-sub seller-balance amount) ERR-UNDERFLOW))
        
        (map-set user-balances-by-project 
          { user: tx-sender, project-id: (get project-id listing) }
          (unwrap! (safe-add buyer-balance amount) ERR-OVERFLOW))
      )
      
      ;; Update or remove listing BEFORE external calls
      (if (is-eq amount (get amount listing))
        (map-set marketplace-listings listing-id (merge listing { active: false }))
        (map-set marketplace-listings listing-id (merge listing { 
          amount: (unwrap! (safe-sub (get amount listing) amount) ERR-UNDERFLOW) 
        })))
      
      ;; Transfer tokens BEFORE STX transfers
      (try! (ft-transfer? carbon-token amount (get seller listing) tx-sender))
      
      ;; Transfer STX to seller and treasury LAST
      (try! (stx-transfer? seller-amount tx-sender (get seller listing)))
      (try! (stx-transfer? treasury-fee-amount tx-sender (var-get treasury-address)))
      
      (ok true)
    )
  )
)

;; Cancel marketplace listing
(define-public (cancel-listing (listing-id uint))
  (let ((listing (unwrap! (map-get? marketplace-listings listing-id) ERR-LISTING-NOT-FOUND)))
    (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
    (try! (check-rate-limit tx-sender))
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
    
    (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
    (try! (check-rate-limit tx-sender))
    (asserts! (and (> amount u0) (<= amount (var-get max-mint-per-transaction))) ERR-INVALID-AMOUNT)
    (asserts! (and (> (len reason) u0) (<= (len reason) MAX-REASON-LENGTH)) ERR-INVALID-REASON)
    (asserts! (>= user-balance amount) ERR-INSUFFICIENT-BALANCE)
    (asserts! (is-some (map-get? carbon-projects project-id)) ERR-PROJECT-NOT-FOUND)
    
    ;; Update balances FIRST (reentrancy protection)
    (map-set user-balances-by-project 
      { user: tx-sender, project-id: project-id } 
      (unwrap! (safe-sub user-balance amount) ERR-UNDERFLOW))
    
    ;; Burn tokens
    (try! (ft-burn? carbon-token amount tx-sender))
    
    ;; Record retirement with block-height timestamp
    (map-set retirement-records 
      { user: tx-sender, retirement-id: retirement-counter }
      {
        amount: amount,
        project-id: project-id,
        retired-at: stacks-block-height,
        reason: reason,
        proof-hash: proof-hash
      })
    
    (map-set user-retirement-counter tx-sender (unwrap! (safe-add retirement-counter u1) ERR-OVERFLOW))
    (var-set total-retired (unwrap! (safe-add (var-get total-retired) amount) ERR-OVERFLOW))
    
    (ok retirement-counter)
  )
)

;; Add project audit
(define-public (add-project-audit (project-id uint) (audit-hash (buff 32)) (status (string-ascii 16)))
  (let ((audit-counter (default-to u0 (map-get? project-audit-counter project-id))))
    (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
    (try! (check-rate-limit tx-sender))
    (asserts! (default-to false (map-get? authorized-verifiers tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? carbon-projects project-id)) ERR-PROJECT-NOT-FOUND)
    (asserts! (not (default-to false (map-get? audit-hashes audit-hash))) ERR-DUPLICATE-AUDIT)
    (asserts! (and (> (len status) u0) (<= (len status) u16)) ERR-INVALID-INPUT)
    
    (map-set project-audits 
      { project-id: project-id, audit-id: audit-counter }
      {
        auditor: tx-sender,
        audit-date: stacks-block-height,
        audit-hash: audit-hash,
        status: status
      })
    
    (map-set audit-hashes audit-hash true)
    (map-set project-audit-counter project-id (unwrap! (safe-add audit-counter u1) ERR-OVERFLOW))
    (ok audit-counter)
  )
)

;; Update treasury address
(define-public (set-treasury-address (new-treasury principal))
  (begin
    (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq new-treasury tx-sender)) ERR-INVALID-INPUT)
    (var-set treasury-address new-treasury)
    (ok true)
  )
)

;; Emergency pause function
(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set contract-paused true)
    (ok true)
  )
)

;; Unpause contract
(define-public (unpause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set contract-paused false)
    (ok true)
  )
)

;; Update maximum mint per transaction
(define-public (set-max-mint-per-transaction (new-max uint))
  (begin
    (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> new-max u0) ERR-INVALID-AMOUNT)
    (var-set max-mint-per-transaction new-max)
    (ok true)
  )
)

;; Update maximum listing amount
(define-public (set-max-listing-amount (new-max uint))
  (begin
    (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> new-max u0) ERR-INVALID-AMOUNT)
    (var-set max-listing-amount new-max)
    (ok true)
  )
)

;; Remove authorized verifier
(define-public (remove-authorized-verifier (verifier principal))
  (begin
    (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq verifier tx-sender)) ERR-INVALID-INPUT)
    (ok (map-set authorized-verifiers verifier false))
  )
)

;; Transfer tokens between users
(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
  (begin
    (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
    (try! (check-rate-limit tx-sender))
    ;; Only allow users to transfer their own tokens (removed CONTRACT-OWNER override)
    (asserts! (is-eq tx-sender from) ERR-NOT-AUTHORIZED)
    (asserts! (and (> amount u0) (<= amount (var-get max-mint-per-transaction))) ERR-INVALID-AMOUNT)
    (asserts! (not (is-eq from to)) ERR-INVALID-INPUT)
    (asserts! (not (is-eq to CONTRACT-OWNER)) ERR-INVALID-INPUT) ;; Prevent transfers to contract owner
    (ft-transfer? carbon-token amount from to)
  )
)

;; Read-only functions for security checks
(define-read-only (is-contract-paused)
  (var-get contract-paused)
)

(define-read-only (get-max-mint-per-transaction)
  (var-get max-mint-per-transaction)
)

(define-read-only (get-max-listing-amount)
  (var-get max-listing-amount)
)

(define-read-only (is-authorized-verifier (verifier principal))
  (default-to false (map-get? authorized-verifiers verifier))
)

(define-read-only (get-user-balance (user principal) (project-id uint))
  (default-to u0 (map-get? user-balances-by-project { user: user, project-id: project-id }))
)

(define-read-only (get-project-info (project-id uint))
  (map-get? carbon-projects project-id)
)

(define-read-only (get-listing-info (listing-id uint))
  (map-get? marketplace-listings listing-id)
)

(define-read-only (get-retirement-record (user principal) (retirement-id uint))
  (map-get? retirement-records { user: user, retirement-id: retirement-id })
)

(define-read-only (get-total-retired)
  (var-get total-retired)
)

(define-read-only (get-treasury-address)
  (var-get treasury-address)
)

(define-read-only (get-user-nonce (user principal))
  (default-to u0 (map-get? nonce-map user))
)

(define-read-only (get-last-operation-block (user principal))
  (default-to u0 (map-get? last-operation-block user))
)

(define-read-only (is-project-name-taken (name (string-ascii 64)))
  (default-to false (map-get? project-names name))
)

(define-read-only (get-audit-info (project-id uint) (audit-id uint))
  (map-get? project-audits { project-id: project-id, audit-id: audit-id })
)