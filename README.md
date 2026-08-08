# BCC Banks

Modern, feature-rich banking for RedM (VORP). BCC Banks adds multi‑account banking, transfers, safety deposit boxes integrated with vorp_inventory, a gold exchange, a full loans system with admin approvals, a check/cheque system, and immersive world integration (NPC tellers, door locks, distance blips, prompts).

Works out of the box: tables are auto‑created on first run, UI is powered by feather-menu, and all actions are server‑validated to prevent client-side cheating.

## Features

- Accounts: multiple accounts per bank, close with zero balance, share access by level (Admin, Withdraw/Deposit, Deposit, Read‑only), server-side locking while viewing, full transaction history. Grant/revoke access by character first and last name.
- Transfers: send between accounts (same or other banks) with configurable cross‑bank fee; logs both sides and the fee.
- Safety Deposit Boxes (SDB): create boxes in sizes (Small/Medium/Large), pay in cash or gold, per‑size weight limits and blacklist, shared custom inventories via vorp_inventory, grant/revoke access by character name or player ID.
- Gold Exchange: buy/sell gold currency for cash at config rates; redeem inventory gold bars to gold with a configurable fee.
- Loans: apply with or without an account, per‑bank/per‑character interest rates, admin approve/reject, disburse to account or claim later, repayments, overdue/default tracking using in‑game days, freeze all owner accounts on default. Loan status mail sent on approve/reject via the configured mail script.
- Checks: write checks from any account to a named recipient (first + last name lookup). Funds deduct immediately — no bounced checks. Two modes: DB-only (recipient cashes via bank menu) or physical item mode (issuer receives a `bank_check` inventory item to hand over in RP; recipient double-clicks it at a bank to cash). Issued checks can be voided by the issuer, refunding the account.
- Mail System: configurable mail script support. Ships with built-in handlers for `bcc-mailbox` and `syn_mail` (direct DB insert). A `custom` mode fires a server event for any other mail script. Used for loan approval/rejection notices and daily loan payment reminders.
- Admin UI: `/bankadmin` to manage banks (create at your position), base bank rates, per‑character overrides, list accounts/loans/SDBs, approve/reject loans.
- World Integration: distance-spawned tellers (NPCs), distance blips with open/closed color, prompt key to open, configurable banker busy lock (one player at a time per bank, auto-released on menu close), initial door-lock states per bank, opening hours with closed prompt display.
- Localization: English, Romanian, Polish, Spanish, Italian, French, and German included. Switch default language in config.

## Requirements

Ensure these resources are installed and started before `bcc-banks`:

- vorp_core
- vorp_inventory
- feather-menu
- bcc-utils
- oxmysql
- Optional: weathersync (used to track in‑game days for loan due/default logic)
- Optional: bcc-mailbox, syn_mail, or any custom mail script (for loan mail notifications)

Note: `fxmanifest.lua` only declares `oxmysql` as a formal dependency; the others are used via exports and must be started first in your server.cfg.

## Installation

1) Copy this folder to `[BCC]/bcc-banks`.

2) Add start order to your `server.cfg` (example):

```
ensure oxmysql
ensure vorp_core
ensure vorp_inventory
ensure feather-menu
ensure bcc-utils
ensure bcc-minigames
ensure bcc-banks
```
If you want to use this lockpick instead of bcc-minigames 

Requires the lockpick system dependency: https://github.com/guf1ck/lockpick-system

3) Start the server. All required tables are created automatically (see "Database" below). Use `/bankadmin` to create your first bank at your position, or insert banks via SQL.

## Configuration

Main settings live in `BCC/bcc-banks/shared/config.lua`:

- Language: set `defaultlang` to `'en_lang'`, `'ro_lang'`, `'pl_lang'`, `'es_lang'`, `'it_lang'`, `'fr_lang'`, or `'de_lang'`.
- Notifications: `Notify = "feather-menu"` (recommended) or `vorp_core`.
- Busy Banker: `UseBankerBusy = true` limits the teller UI to one player at a time. The lock is automatically released when the player closes the menu.
- Prompts: `PromptSettings.Distance` and `TellerKey` (default G).
- NPCs: `NPCSettings` model, spawn distance.
- Blips: show, color per state, distance spawn radius.
- Access Levels: numeric mapping for Admin/Withdraw+Deposit/Deposit/ReadOnly.
- Transfers: enable and set `CrossBankFeePercent` (applies to sender).
- Gold Exchange: enable and set buy/sell rates; set `GoldBarItemName`, conversion `GoldBarToGold`, and `GoldBarFeePercent` for redeeming inventory items to gold.
- Accounts: `MaxAccounts` per bank (0 = no limit).
- Checks: enable/disable, optional `MaxAmount` cap, and `UseItem` toggle for physical item mode. When `UseItem = true` set `ItemName` to the registered vorp_inventory item name.
- Mail: set `Script` to `'bcc-mailbox'`, `'syn_mail'`, or `'custom'`. For `'custom'` set `CustomEvent` to your server event name — it receives `(charId, fromName, subject, body)`.
- Safety Deposit Boxes: global max per player/bank and per‑size prices, weight, item blacklist and stack behavior.
- Doors: map door hashes to initial lock state per bank.

Tip: The admin permission check uses VORP character `group` and `job` against `Config.adminGroups` and `Config.AllowedJobs`. There is an optional ACE check in code you can enable if desired.

## Usage

- Approach a bank teller NPC and press the prompt key (default G) to open the bank UI.
- Accounts: create/manage, deposit/withdraw cash or gold, view transactions, share/revoke access by character name, transfer funds, write checks, and view issued checks.
- Checks (DB-only mode): write a check from an account by entering the recipient's first and last name and an amount. Funds deduct immediately. The recipient cashes it via the "Cash a Check" button in the main bank menu.
- Checks (item mode): write a check as above — you receive a `bank_check` inventory item. Hand it to the recipient in RP. They double-click it while near a bank to cash it. Proximity is enforced server-side.
- Safety Deposit Boxes: create boxes (cash or gold), open inventory UI, manage access by character name.
- Gold Exchange: buy/sell gold, redeem gold bars from inventory to gold.
- Loans: apply (auto‑creates an account if needed), claim funds to an account once approved, repay from cash, track status. Overdue/default marks freeze all owner accounts until resolved. Approval and rejection notices are sent via the configured mail script.
- Admin: `/bankadmin` to open the admin UI. Create banks, adjust rates, review lists, approve/reject loans.

## Commands & Keys

- `/bankadmin` — open the bank admin UI (requires admin per config).
- Prompt key: `Config.PromptSettings.TellerKey` (default G) at teller.
- A developer-only `banksReady` command exists to reinit banks in dev mode.

## Database

Tables are created automatically on server start in `server/services/database.lua`:

- `bcc_banks`, `bcc_accounts`, `bcc_accounts_access`
- `bcc_transactions`
- `bcc_loans`, `bcc_loans_payments`, `bcc_loan_interest_rates`, `bcc_bank_interest_rates`
- `bcc_safety_deposit_boxes`, `bcc_safety_deposit_boxes_access`
- `bcc_checks`

You can seed banks by using `/bankadmin` → Create Bank At Your Location, or insert rows into `bcc_banks`.

## Technical Notes

- Server‑side validation: all sensitive operations run through server RPCs and DB checks; accounts can be locked while viewing to prevent race conditions. Stale locks from disconnected players are auto-cleared on the next access attempt.
- Inventory: SDB inventories are registered dynamically using `vorp_inventory` exports. Older rows are backfilled on startup.
- Loan timing: if `weathersync` is present, the script tracks game days to progress loan due dates and mark defaults.
- Checks: written checks deduct from the account immediately. In item mode, the check item stores the `check_id` in metadata; the server validates the recipient and item ownership before paying out.
- Mail: loan mail uses a unified dispatcher that routes to the configured script. `syn_mail` is supported via direct DB insert into the `mails` table with a live client push via `syn_mail:rec_addedMailid`.
- Discord: code includes a `bcc-utils` Discord webhook setup; provide `Config.WebhookLink`, `WebhookTitle`, and `WebhookAvatar` if you wish to emit notifications.

## Credits

Author: BCC Scripts
