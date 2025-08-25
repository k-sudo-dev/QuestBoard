
;; title: QuestBoard - Community Quest Management System
;; version: 1.0.0
;; summary: A smart contract for managing community quests and rewarding players with NFT badges
;; description: This contract allows game developers to post quests and reward players with unique NFT badges upon completion

;; traits
(use-trait sip009-nft-trait .sip009-nft-trait.sip009-nft-trait)

;; token definitions
(define-non-fungible-token quest-badge uint)

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-QUEST-NOT-FOUND (err u101))
(define-constant ERR-QUEST-INACTIVE (err u102))
(define-constant ERR-QUEST-EXPIRED (err u103))
(define-constant ERR-ALREADY-COMPLETED (err u104))
(define-constant ERR-INVALID-INPUT (err u105))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u106))

;; data vars
(define-data-var quest-counter uint u0)
(define-data-var badge-counter uint u0)
(define-data-var contract-uri (string-ascii 256) "https://questboard.stacks.co/metadata/")

;; data maps
(define-map quests 
  uint 
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    reward-amount: uint,
    max-participants: uint,
    current-participants: uint,
    expiry-block: uint,
    is-active: bool,
    created-at: uint
  }
)

(define-map quest-participants 
  {quest-id: uint, player: principal}
  {completed: bool, completion-block: uint}
)

(define-map player-badges
  principal
  {total-badges: uint, last-badge-id: uint}
)

;; public functions
(define-public (create-quest 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (reward-amount uint)
  (max-participants uint)
  (duration-blocks uint)
)
  (let 
    (
      (quest-id (+ (var-get quest-counter) u1))
      (expiry-block (+ block-height duration-blocks))
    )
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)
    (asserts! (> max-participants u0) ERR-INVALID-INPUT)
    (asserts! (> duration-blocks u0) ERR-INVALID-INPUT)
    
    (map-set quests quest-id {
      creator: tx-sender,
      title: title,
      description: description,
      reward-amount: reward-amount,
      max-participants: max-participants,
      current-participants: u0,
      expiry-block: expiry-block,
      is-active: true,
      created-at: block-height
    })
    
    (var-set quest-counter quest-id)
    (ok quest-id)
  )
)

(define-public (join-quest (quest-id uint))
  (let 
    (
      (quest (unwrap! (map-get? quests quest-id) ERR-QUEST-NOT-FOUND))
      (participant-key {quest-id: quest-id, player: tx-sender})
    )
    (asserts! (get is-active quest) ERR-QUEST-INACTIVE)
    (asserts! (< block-height (get expiry-block quest)) ERR-QUEST-EXPIRED)
    (asserts! (< (get current-participants quest) (get max-participants quest)) ERR-QUEST-INACTIVE)
    (asserts! (is-none (map-get? quest-participants participant-key)) ERR-ALREADY-COMPLETED)
    
    (map-set quest-participants participant-key {
      completed: false,
      completion-block: u0
    })
    
    (map-set quests quest-id (merge quest {
      current-participants: (+ (get current-participants quest) u1)
    }))
    
    (ok true)
  )
)

