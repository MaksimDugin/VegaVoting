# HW 6 Voting Contract MVP

## Что уже реализовано

- `VVToken.sol` — ERC20-токен VV.
- `Voting.sol` — создание голосований, стейкинг VV, yes/no voting, ранняя финализация по threshold, финализация по deadline.
- `VoteResultNFT.sol` — ERC721 NFT, который минтится при финализации и хранит результат голосования в metadata.
- `script/Deploy.s.sol` — деплой под Foundry.
- `script/SetupDemoVote.s.sol` — сценарий для создания голосования и участия двух адресов.
- `test/Voting.t.sol` — базовые тесты.

## Модель MVP

- Голосование создаёт только `owner`.
- Каждый vote имеет уникальный `bytes32 id`.
- Voting power считается по формуле:
  `power = sum(amount_i * remainingTime_i^2 / 1 days^2)`
- Два пути завершения:
  - `yesVotes >= votingPowerThreshold`
  - или `block.timestamp >= deadline`
- После финализации минтится NFT с результатом.

## Установка зависимостей

Нужны:
- Foundry
- OpenZeppelin Contracts v5
- forge-std

Пример:
```bash
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install foundry-rs/forge-std --no-commit
```

## Сборка и тесты

```bash
forge build
forge test
```

## Деплой в Sepolia

Пример переменных окружения:

```bash
export PRIVATE_KEY=0x...
export RPC_URL=https://sepolia.infura.io/v3/...
```

Деплой:

```bash
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify
```

## Демонстрационное голосование

После деплоя:

```bash
export ADMIN_PRIVATE_KEY=0x...
export VOTER1_PRIVATE_KEY=0x...
export VOTER2_PRIVATE_KEY=0x...
export VV_TOKEN_ADDRESS=0x...
export VOTING_ADDRESS=0x...
export VOTE_ID=0x1234...
export DESCRIPTION="Should the proposal pass?"
export VOTING_POWER_THRESHOLD=3200000000000000000000
```

Запуск:

```bash
forge script script/SetupDemoVote.s.sol:SetupDemoVote \
  --rpc-url $RPC_URL \
  --broadcast
```

## Что стоит сделать следующим шагом

- Добавить более строгую модель quorum / threshold.
- Добавить отдельный finalize role, если это потребуется по формулировке курса.
- Добавить более подробные проверки на повторный vote / кастомную логику withdrawal.
- Подготовить Sepolia verify commands и README с адресами контрактов.
