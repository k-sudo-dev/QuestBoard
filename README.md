# QuestBoard 🎮

> A smart contract-powered community board where game developers post quests (missions) and players earn NFT badges or in-game currency upon completion.

[![Stacks](https://img.shields.io/badge/Stacks-Blockchain-purple)](https://stacks.org)
[![Clarity](https://img.shields.io/badge/Clarity-Smart%20Contract-blue)](https://clarity-lang.org)
[![SIP-009](https://img.shields.io/badge/SIP--009-Compliant-green)](https://github.com/stacksgov/sips)
[![Clarinet](https://img.shields.io/badge/Clarinet-Tested-orange)](https://github.com/hirosystems/clarinet)

## 🌟 Overview

QuestBoard is a decentralized quest management platform built on the Stacks blockchain using Clarity smart contracts. It enables game developers to create engaging community quests while players earn unique NFT badges as proof of completion and achievement.

## ✨ Features

### 🎯 For Game Developers
- **Quest Creation**: Post quests with detailed descriptions, participant limits, and deadlines
- **Reward Management**: Define reward amounts and achievement criteria
- **Player Validation**: Verify and approve quest completions
- **Community Building**: Foster engagement through structured challenges

### 🏆 For Players
- **Quest Discovery**: Browse and join available community quests
- **NFT Badges**: Earn unique SIP-009 compliant NFT badges for completions
- **Achievement Tracking**: Monitor personal statistics and badge collections
- **Competitive Gaming**: Participate in limited-slot competitive quests

### 🔧 Administrative Features
- **Quest Moderation**: Deactivate inappropriate or problematic quests
- **Contract Management**: Update metadata URIs and contract settings
- **Emergency Controls**: Pause/unpause contract for maintenance or security
- **Analytics Dashboard**: Comprehensive statistics and reporting

## 🏗️ Architecture

### Smart Contract Structure
```
questboard.clar (337+ lines)
├── SIP-009 NFT Trait Implementation
├── Quest Management System
├── Player Participation Logic
├── NFT Badge Minting
├── Administrative Functions
└── Analytics & Utilities
```

### Data Structures
- **Quests**: Creator, title, description, rewards, participants, expiry
- **Participants**: Completion status, timestamps, badge associations
- **Player Statistics**: Total badges, achievement tracking
- **Contract State**: Counters, URI settings, operational status

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks development environment
- Node.js 16+ (for testing)
- Stacks Wallet (for mainnet deployment)

### Installation
```bash
# Clone the repository
git clone https://github.com/k-sudo-dev/QuestBoard.git
cd QuestBoard

# Install dependencies
npm install

# Run contract checks
clarinet check

# Run tests
npm test
```

### Local Development
```bash
# Start local development environment
clarinet console

# Deploy to local testnet
clarinet deploy --testnet

# Interactive contract testing
clarinet console
```

## 📖 Usage Examples

### Creating a Quest
```clarity
;; Create a quest with 1000 STX reward, max 10 participants, 1440 blocks duration
(contract-call? .questboard create-quest 
  "Complete Tutorial Level"
  "Finish the complete game tutorial and submit proof"
  u1000000  ;; 1000 STX in microSTX
  u10       ;; Max 10 participants
  u1440)    ;; ~10 days (144 blocks/day)
```

### Joining a Quest
```clarity
;; Join quest with ID 1
(contract-call? .questboard join-quest u1)
```

### Completing a Quest (as creator)
```clarity
;; Mark player as completed (mints NFT badge)
(contract-call? .questboard complete-quest u1 'ST1PLAYER-ADDRESS)
```

### Querying Player Statistics
```clarity
;; Get player's badge collection info
(contract-call? .questboard get-player-badges 'ST1PLAYER-ADDRESS)

;; Check if player completed specific quest
(contract-call? .questboard has-completed-quest u1 'ST1PLAYER-ADDRESS)
```

## 🔍 Contract Functions

### Public Functions
| Function | Description | Access |
|----------|-------------|--------|
| `create-quest` | Create new quest with parameters | Anyone |
| `join-quest` | Join an active quest | Players |
| `complete-quest` | Mark quest completion & mint badge | Creator/Admin |
| `set-quest-inactive` | Deactivate problematic quest | Creator/Admin |
| `set-contract-uri` | Update metadata URI | Admin only |
| `transfer` | Transfer NFT badge ownership | Badge owner |

### Read-Only Functions
| Function | Description | Returns |
|----------|-------------|---------|
| `get-quest` | Quest details by ID | Quest data |
| `get-player-badges` | Player's badge statistics | Badge count & IDs |
| `is-quest-active` | Check if quest is active | Boolean |
| `get-quest-stats` | Detailed quest analytics | Statistics object |
| `get-contract-info` | Contract metadata & stats | Contract info |

## 🛡️ Security Features

### Access Controls
- **Creator Permissions**: Quest creators can complete their own quests
- **Admin Functions**: Contract owner has emergency controls
- **Player Protection**: Prevents double-joining and invalid completions

### Validation Systems
- **Input Validation**: Comprehensive checks for all user inputs
- **State Consistency**: Ensures valid state transitions
- **Time-based Logic**: Automatic quest expiry and activation checks

### Emergency Mechanisms
- **Contract Pause**: Halt all operations during security incidents
- **Quest Deactivation**: Remove problematic quests
- **Administrative Override**: Emergency controls for platform stability

## 🧪 Testing

### Running Tests
```bash
# Run all tests
npm test

# Run specific test file
npm test -- questboard.test.ts

# Test with coverage
npm run test:coverage
```

### Test Coverage
- ✅ Quest creation and validation
- ✅ Player participation flows
- ✅ NFT badge minting
- ✅ Administrative functions
- ✅ Error conditions and edge cases

## 📊 Analytics & Metrics

### Platform Statistics
- Total quests created
- Total badges minted
- Active player count
- Quest completion rates

### Quest Analytics
- Participant tracking
- Completion percentages
- Time-to-completion metrics
- Popular quest categories

## 🔗 SIP-009 NFT Compliance

QuestBoard badges are fully SIP-009 compliant, providing:
- **Interoperability**: Works with all SIP-009 compatible platforms
- **Transferability**: Badges can be traded or transferred
- **Metadata Support**: Rich metadata through IPFS integration
- **Wallet Support**: Compatible with all Stacks NFT wallets

## 🌐 Deployment

### Testnet Deployment
```bash
# Deploy to Stacks testnet
clarinet deploy --testnet

# Verify deployment
clarinet console --testnet
```

### Mainnet Deployment
```bash
# Deploy to Stacks mainnet
clarinet deploy --mainnet

# Monitor contract
stacks-cli balance STX-ADDRESS
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Process
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Make changes and add tests
4. Run test suite (`npm test`)
5. Commit changes (`git commit -m 'Add amazing feature'`)
6. Push to branch (`git push origin feature/amazing-feature`)
7. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Documentation**: [QuestBoard Docs](https://questboard.stacks.co/docs)
- **Stacks Explorer**: [View Contract](https://explorer.stacks.co)
- **Discord Community**: [Join Discussion](https://discord.gg/questboard)
- **Roadmap**: [Project Roadmap](https://github.com/k-sudo-dev/QuestBoard/projects)

## 🙏 Acknowledgments

- [Stacks Foundation](https://stacks.org) for the blockchain infrastructure
- [Hiro Systems](https://hiro.so) for Clarinet development tools
- [Clarity Language](https://clarity-lang.org) for smart contract capabilities
- The open-source community for inspiration and support

---

**Built with ❤️ for the Stacks ecosystem**
