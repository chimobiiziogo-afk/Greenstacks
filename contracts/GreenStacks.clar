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