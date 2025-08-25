
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

(define-public (complete-quest (quest-id uint) (player principal))
  (let 
    (
      (quest (unwrap! (map-get? quests quest-id) ERR-QUEST-NOT-FOUND))
      (participant-key {quest-id: quest-id, player: player})
      (participant (unwrap! (map-get? quest-participants participant-key) ERR-QUEST-NOT-FOUND))
      (badge-id (+ (var-get badge-counter) u1))
    )
    (asserts! (or (is-eq tx-sender (get creator quest)) (is-eq tx-sender CONTRACT-OWNER)) ERR-UNAUTHORIZED)
    (asserts! (get is-active quest) ERR-QUEST-INACTIVE)
    (asserts! (< block-height (get expiry-block quest)) ERR-QUEST-EXPIRED)
    (asserts! (not (get completed participant)) ERR-ALREADY-COMPLETED)
    
    ;; Mark quest as completed for player
    (map-set quest-participants participant-key {
      completed: true,
      completion-block: block-height
    })
    
    ;; Mint NFT badge to player
    (try! (nft-mint? quest-badge badge-id player))
    
    ;; Update player badge count
    (let 
      (
        (player-stats (default-to {total-badges: u0, last-badge-id: u0} 
                                 (map-get? player-badges player)))
      )
      (map-set player-badges player {
        total-badges: (+ (get total-badges player-stats) u1),
        last-badge-id: badge-id
      })
    )
    
    (var-set badge-counter badge-id)
    (ok badge-id)
  )
)

(define-public (deactivate-quest (quest-id uint))
  (let 
    (
      (quest (unwrap! (map-get? quests quest-id) ERR-QUEST-NOT-FOUND))
    )
    (asserts! (or (is-eq tx-sender (get creator quest)) (is-eq tx-sender CONTRACT-OWNER)) ERR-UNAUTHORIZED)
    
    (map-set quests quest-id (merge quest {is-active: false}))
    (ok true)
  )
)

(define-public (set-contract-uri (new-uri (string-ascii 256)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (var-set contract-uri new-uri)
    (ok true)
  )
)

;; read only functions
(define-read-only (get-quest (quest-id uint))
  (map-get? quests quest-id)
)

(define-read-only (get-quest-participant (quest-id uint) (player principal))
  (map-get? quest-participants {quest-id: quest-id, player: player})
)

(define-read-only (get-player-badges (player principal))
  (map-get? player-badges player)
)

(define-read-only (get-quest-count)
  (var-get quest-counter)
)

(define-read-only (get-badge-count)
  (var-get badge-counter)
)

(define-read-only (get-contract-uri)
  (var-get contract-uri)
)

(define-read-only (is-quest-active (quest-id uint))
  (match (map-get? quests quest-id)
    quest (and (get is-active quest) (< block-height (get expiry-block quest)))
    false
  )
)

;; SIP009 NFT trait implementation
(define-read-only (get-last-token-id)
  (ok (var-get badge-counter))
)

(define-read-only (get-token-uri (badge-id uint))
  (if (<= badge-id (var-get badge-counter))
    (ok (some (concat (var-get contract-uri) (uint-to-ascii badge-id))))
    (ok none)
  )
)

(define-read-only (get-owner (badge-id uint))
  (ok (nft-get-owner? quest-badge badge-id))
)

(define-public (transfer (badge-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR-UNAUTHORIZED)
    (nft-transfer? quest-badge badge-id sender recipient)
  )
)

