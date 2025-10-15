# 🧠 Mind-Sync

A decentralized smart contract for synchronizing minds and thoughts on the Stacks blockchain. Connect consciousness, share mental energy, and create synchronized thought networks.

## ✨ Features

🔗 **Mind Connections**: Create and manage connections between different minds  
⚡ **Energy System**: Manage mental energy for synchronization operations  
💭 **Thought Creation**: Store and synchronize thoughts across connected minds  
🎭 **Sync Sessions**: Participate in group synchronization sessions  
📊 **Connection Tracking**: Monitor sync counts and interaction history  
🔧 **Configurable Parameters**: Adjust sync costs and connection limits  

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet/getting-started) installed
- Basic understanding of Clarity smart contracts

### Installation

```bash
git clone <your-repo>
cd mind-sync
clarinet check
```

### Running Tests

```bash
npm install
npm test
```

## 📋 Contract Functions

### 🏗️ Initialization

#### `initialize-mind`
Initialize your mind with starting energy.

```clarity
(contract-call? .mind-sync initialize-mind u100)
```

### 🔗 Connection Management

#### `create-connection`
Create a connection to another mind.

```clarity
(contract-call? .mind-sync create-connection 'ST1MIND... u50)
```

#### `update-connection-strength`
Modify the strength of an existing connection (1-100).

```clarity
(contract-call? .mind-sync update-connection-strength 'ST1MIND... u75)
```

#### `deactivate-connection`
Deactivate a connection with another mind.

```clarity
(contract-call? .mind-sync deactivate-connection 'ST1MIND...)
```

### 💭 Thought Operations

#### `create-thought`
Create a new thought with energy cost.

```clarity
(contract-call? .mind-sync create-thought 0x1234... u10 (some 'ST1RECEIVER...))
```

#### `synchronize-thought`
Synchronize a thought with target mind.

```clarity
(contract-call? .mind-sync synchronize-thought u1 'ST1TARGET...)
```

### 🎭 Session Management

#### `start-sync-session`
Start a group synchronization session.

```clarity
(contract-call? .mind-sync start-sync-session (list 'ST1MIND1... 'ST1MIND2...) 0xABCD...)
```

#### `contribute-to-session`
Add energy to an active session.

```clarity
(contract-call? .mind-sync contribute-to-session u1 u25)
```

#### `end-sync-session`
End an active synchronization session.

```clarity
(contract-call? .mind-sync end-sync-session u1)
```

### ⚡ Energy Management

#### `recharge-energy`
Recharge your mind's energy (max 1000 per transaction).

```clarity
(contract-call? .mind-sync recharge-energy u50)
```

### 🔍 Read-Only Functions

#### Query Functions
- `get-mind`: Get mind information for a principal
- `get-connection`: Get connection details between two minds
- `get-thought`: Get thought information by ID
- `get-sync-session`: Get session information by ID
- `get-current-thought-id`: Get next thought ID
- `get-current-session-id`: Get next session ID
- `get-total-syncs`: Get total synchronizations performed
- `get-sync-cost`: Get current synchronization cost
- `can-sync`: Check if a mind has enough energy to sync

### ⚙️ Configuration

#### `set-mind-status`
Update your mind's status (max 20 characters).

```clarity
(contract-call? .mind-sync set-mind-status "meditative")
```

#### `set-sync-parameters` (Owner Only)
Configure global synchronization parameters.

```clarity
(contract-call? .mind-sync set-sync-parameters u15 u150 u8)
```

## 📊 Data Structures

### Mind Map
```clarity
{
  energy: uint,
  last-sync: uint,
  connection-count: uint,
  status: (string-ascii 20),
  created-at: uint
}
```

### Connection Map
```clarity
{
  strength: uint,
  created-at: uint,
  last-interaction: uint,
  sync-count: uint,
  is-active: bool
}
```

### Thought Map
```clarity
{
  creator: principal,
  content-hash: (buff 32),
  energy-cost: uint,
  timestamp: uint,
  connection-id: (optional {sender: principal, receiver: principal}),
  is-synchronized: bool
}
```

## 🔢 Error Codes

- `u100`: Owner only operation
- `u101`: Resource not found
- `u102`: Unauthorized access
- `u103`: Resource already exists
- `u104`: Invalid input parameters
- `u105`: Synchronization failed
- `u106`: Insufficient energy

## 🛠️ Development

### Testing

```bash
clarinet test
```

### Console Testing

```bash
clarinet console
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-sync`)
3. Commit your changes (`git commit -m 'Add amazing sync feature'`)
4. Push to the branch (`git push origin feature/amazing-sync`)
5. Open a Pull Request

## 📄 License

This project is open source and available under the MIT License.

## 🔮 Future Enhancements

- 🌐 Cross-chain mind synchronization
- 🎯 Thought categorization and filtering  
- 📈 Energy regeneration mechanisms
- 🏆 Reputation system for reliable minds
- 🔐 Encrypted thought content
- 📱 Mobile app integration

---

*"In the realm of synchronized consciousness, every thought becomes a bridge to understanding."* ✨
