local function fetchColumnType(tableName, columnName)
    local row = MySQL.single.await([[SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ? LIMIT 1;]], { tableName, columnName })
    return row and (row.DATA_TYPE or row.data_type) or nil
end

local function countNumericIds(tableName, columnName)
    local row = MySQL.single.await(('SELECT COUNT(*) AS cnt FROM `%s` WHERE `%s` REGEXP "^[0-9]+$";'):format(tableName, columnName))
    return row and tonumber(row.cnt or row.CNT or row['COUNT(*)'] or 0) or 0
end

local function isLegacyNumericId(value)
    if value == nil then return false end
    if type(value) == 'number' then return true end
    local str = tostring(value)
    if str == '' then return false end
    return str:match('^%d+$') ~= nil
end

local function buildMappingTable(tableName, columnName, mappingTable)
    MySQL.query.await(('DROP TABLE IF EXISTS `%s`;'):format(mappingTable))
    MySQL.query.await(('CREATE TABLE `%s` (`old_id` VARCHAR(36) PRIMARY KEY, `new_id` VARCHAR(36) NOT NULL) ENGINE=InnoDB;'):format(mappingTable))
    MySQL.query.await(('INSERT INTO `%s` (old_id, new_id) SELECT `%s`, UUID() FROM `%s` WHERE `%s` REGEXP "^[0-9]+$";'):format(mappingTable, columnName, tableName, columnName))
end

local function dropMappingTable(mappingTable)
    MySQL.query.await(('DROP TABLE IF EXISTS `%s`;'):format(mappingTable))
end

local function dropForeignKeysReferencing(tableName, columnName)
    local rows = MySQL.query.await([[SELECT CONSTRAINT_NAME, TABLE_NAME FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA = DATABASE() AND REFERENCED_TABLE_NAME = ? AND REFERENCED_COLUMN_NAME = ? GROUP BY CONSTRAINT_NAME, TABLE_NAME;]], { tableName, columnName }) or {}
    for _, row in ipairs(rows) do
        local constraintName = row.CONSTRAINT_NAME or row.constraint_name
        local referencingTable = row.TABLE_NAME or row.table_name
        if constraintName and referencingTable then
            local dropStmt = ('ALTER TABLE `%s` DROP FOREIGN KEY `%s`;'):format(referencingTable, constraintName)
            local ok, err = pcall(function()
                MySQL.query.await(dropStmt)
            end)
            if not ok then
                devPrint('[migration] Unable to drop FK', constraintName, 'on table', referencingTable, '->', err)
            end
        end
    end
end

local function ensureColumnIsVarchar(tableName, columnName)
    local columnType = fetchColumnType(tableName, columnName)
    if columnType and columnType:lower() == 'varchar' then
        return
    end
    local stmt = ('ALTER TABLE `%s` MODIFY COLUMN `%s` VARCHAR(36) NOT NULL;'):format(tableName, columnName)
    MySQL.query.await(stmt)
end

local function ensureOptionalColumnIsVarchar(tableName, columnName)
    local columnType = fetchColumnType(tableName, columnName)
    if columnType and columnType:lower() == 'varchar' then
        return
    end
    local stmt = ('ALTER TABLE `%s` MODIFY COLUMN `%s` VARCHAR(36) NULL;'):format(tableName, columnName)
    MySQL.query.await(stmt)
end

local function migrateBanks(mappingTable)
    MySQL.query.await([[UPDATE `bcc_banks` b INNER JOIN `]] .. mappingTable .. [[` m ON b.id = m.old_id SET b.id = m.new_id;]])
    MySQL.query.await([[UPDATE `bcc_accounts` a INNER JOIN `]] .. mappingTable .. [[` m ON a.bank_id = m.old_id SET a.bank_id = m.new_id;]])
    MySQL.query.await([[UPDATE `bcc_loans` l INNER JOIN `]] .. mappingTable .. [[` m ON l.bank_id = m.old_id SET l.bank_id = m.new_id;]])
    MySQL.query.await([[UPDATE `bcc_safety_deposit_boxes` s INNER JOIN `]] .. mappingTable .. [[` m ON s.bank_id = m.old_id SET s.bank_id = m.new_id;]])
    MySQL.query.await([[UPDATE `bcc_bank_interest_rates` bir INNER JOIN `]] .. mappingTable .. [[` m ON bir.bank_id = m.old_id SET bir.bank_id = m.new_id;]])
    MySQL.query.await([[UPDATE `bcc_loan_interest_rates` lir INNER JOIN `]] .. mappingTable .. [[` m ON lir.bank_id = m.old_id SET lir.bank_id = m.new_id;]])
end

local function migrateAccounts(mappingTable)
    MySQL.query.await([[UPDATE `bcc_accounts` a INNER JOIN `]] .. mappingTable .. [[` m ON a.id = m.old_id SET a.id = m.new_id;]])
    MySQL.query.await([[UPDATE `bcc_accounts_access` aa INNER JOIN `]] .. mappingTable .. [[` m ON aa.account_id = m.old_id SET aa.account_id = m.new_id;]])
    MySQL.query.await([[UPDATE `bcc_loans` l INNER JOIN `]] .. mappingTable .. [[` m ON l.account_id = m.old_id SET l.account_id = m.new_id;]])
    MySQL.query.await([[UPDATE `bcc_loans` l INNER JOIN `]] .. mappingTable .. [[` m ON l.disbursed_account_id = m.old_id SET l.disbursed_account_id = m.new_id;]])
    MySQL.query.await([[UPDATE `bcc_transactions` t INNER JOIN `]] .. mappingTable .. [[` m ON t.account_id = m.old_id SET t.account_id = m.new_id;]])
end

local function migrateSafetyDepositBoxes(mappingTable)
    MySQL.query.await([[UPDATE `bcc_safety_deposit_boxes` s INNER JOIN `]] .. mappingTable .. [[` m ON s.id = m.old_id SET s.id = m.new_id;]])
    MySQL.query.await([[UPDATE `bcc_safety_deposit_boxes_access` sa INNER JOIN `]] .. mappingTable .. [[` m ON sa.safety_deposit_box_id = m.old_id SET sa.safety_deposit_box_id = m.new_id;]])
end

local function migrateLoans(mappingTable)
    MySQL.query.await([[UPDATE `bcc_loans` l INNER JOIN `]] .. mappingTable .. [[` m ON l.id = m.old_id SET l.id = m.new_id;]])
    MySQL.query.await([[UPDATE `bcc_loans_payments` lp INNER JOIN `]] .. mappingTable .. [[` m ON lp.loan_id = m.old_id SET lp.loan_id = m.new_id;]])
    MySQL.query.await([[UPDATE `bcc_transactions` t INNER JOIN `]] .. mappingTable .. [[` m ON t.loan_id = m.old_id SET t.loan_id = m.new_id;]])
end

local function migrateTransactions(mappingTable)
    MySQL.query.await([[UPDATE `bcc_transactions` t INNER JOIN `]] .. mappingTable .. [[` m ON t.id = m.old_id SET t.id = m.new_id;]])
end

local function migrateLoanPayments(mappingTable)
    MySQL.query.await([[UPDATE `bcc_loans_payments` lp INNER JOIN `]] .. mappingTable .. [[` m ON lp.id = m.old_id SET lp.id = m.new_id;]])
end

local function cleanupOrphans()
    -- Remove bank interest rows that refer to non-existent banks
    MySQL.query.await([[DELETE bir FROM `bcc_bank_interest_rates` bir LEFT JOIN `bcc_banks` b ON bir.bank_id = b.id WHERE b.id IS NULL;]])
    -- Remove loan interest rows (except global bank_id = '0') that no longer reference a bank
    MySQL.query.await([[DELETE lir FROM `bcc_loan_interest_rates` lir LEFT JOIN `bcc_banks` b ON lir.bank_id = b.id WHERE lir.bank_id <> '0' AND b.id IS NULL;]])
    -- Set loan bank_id to NULL if the bank no longer exists so FK with ON DELETE SET NULL can be restored
    MySQL.query.await([[UPDATE `bcc_loans` l LEFT JOIN `bcc_banks` b ON l.bank_id = b.id SET l.bank_id = NULL WHERE l.bank_id IS NOT NULL AND b.id IS NULL;]])
end

local function restoreForeignKeys()
    local statements = {
        'ALTER TABLE `bcc_accounts` ADD CONSTRAINT `FK_accounts_bank` FOREIGN KEY (`bank_id`) REFERENCES `bcc_banks`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;',
        'ALTER TABLE `bcc_accounts_access` ADD CONSTRAINT `FK_baa_account` FOREIGN KEY (`account_id`) REFERENCES `bcc_accounts`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;',
        'ALTER TABLE `bcc_loans` ADD CONSTRAINT `FK_loans_account` FOREIGN KEY (`account_id`) REFERENCES `bcc_accounts`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;',
        'ALTER TABLE `bcc_loans` ADD CONSTRAINT `FK_loans_bank` FOREIGN KEY (`bank_id`) REFERENCES `bcc_banks`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;',
        'ALTER TABLE `bcc_loans_payments` ADD CONSTRAINT `FK_lp_loan` FOREIGN KEY (`loan_id`) REFERENCES `bcc_loans`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;',
        'ALTER TABLE `bcc_transactions` ADD CONSTRAINT `FK_t_account` FOREIGN KEY (`account_id`) REFERENCES `bcc_accounts`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;',
        'ALTER TABLE `bcc_safety_deposit_boxes` ADD CONSTRAINT `FK_sdb_bank` FOREIGN KEY (`bank_id`) REFERENCES `bcc_banks`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;',
        'ALTER TABLE `bcc_safety_deposit_boxes_access` ADD CONSTRAINT `FK_sdba_sdb` FOREIGN KEY (`safety_deposit_box_id`) REFERENCES `bcc_safety_deposit_boxes`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;',
        'ALTER TABLE `bcc_loan_interest_rates` ADD CONSTRAINT `FK_lir_bank` FOREIGN KEY (`bank_id`) REFERENCES `bcc_banks`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;',
        'ALTER TABLE `bcc_bank_interest_rates` ADD CONSTRAINT `FK_bir_bank` FOREIGN KEY (`bank_id`) REFERENCES `bcc_banks`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;'
    }

    for _, stmt in ipairs(statements) do
        local ok, err = pcall(function()
            MySQL.query.await(stmt)
        end)
        if not ok then
            devPrint('[migration] Failed to recreate FK:', stmt, err)
        end
    end
end

function RunLegacyIdMigration()
    -- Detect if any legacy numeric identifiers remain
    local legacyBanks = countNumericIds('bcc_banks', 'id')
    local legacyAccounts = countNumericIds('bcc_accounts', 'id')
    local legacyLoans = countNumericIds('bcc_loans', 'id')
    local legacySDBs = countNumericIds('bcc_safety_deposit_boxes', 'id')
    local legacyTransactions = countNumericIds('bcc_transactions', 'id')
    local legacyLoanPayments = countNumericIds('bcc_loans_payments', 'id')

    if legacyBanks == 0 and legacyAccounts == 0 and legacyLoans == 0 and legacySDBs == 0 and legacyTransactions == 0 and legacyLoanPayments == 0 then
        devPrint('[migration] No legacy numeric identifiers detected; skipping migration.')
        return
    end

    devPrint(('[migration] Legacy numeric identifiers detected (banks=%d, accounts=%d, loans=%d, sdbs=%d, tx=%d, loan_payments=%d). Starting migration...'):format(legacyBanks, legacyAccounts, legacyLoans, legacySDBs, legacyTransactions, legacyLoanPayments))

    local fkDisabled = false
    local totalConverted = 0

    local ok, err = pcall(function()
        MySQL.query.await('SET FOREIGN_KEY_CHECKS = 0;')
        fkDisabled = true

        -- Drop existing foreign keys that reference the tables we are about to mutate
        dropForeignKeysReferencing('bcc_banks', 'id')
        dropForeignKeysReferencing('bcc_accounts', 'id')
        dropForeignKeysReferencing('bcc_loans', 'id')
        dropForeignKeysReferencing('bcc_safety_deposit_boxes', 'id')

        -- Ensure columns are typed as VARCHAR(36) prior to updates
        ensureColumnIsVarchar('bcc_banks', 'id')
        ensureColumnIsVarchar('bcc_accounts', 'id')
        ensureColumnIsVarchar('bcc_accounts', 'bank_id')
        ensureColumnIsVarchar('bcc_accounts_access', 'account_id')
        ensureColumnIsVarchar('bcc_loans', 'id')
        ensureOptionalColumnIsVarchar('bcc_loans', 'account_id')
        ensureOptionalColumnIsVarchar('bcc_loans', 'bank_id')
        ensureOptionalColumnIsVarchar('bcc_loans', 'disbursed_account_id')
        ensureColumnIsVarchar('bcc_loans_payments', 'id')
        ensureColumnIsVarchar('bcc_loans_payments', 'loan_id')
        ensureColumnIsVarchar('bcc_bank_interest_rates', 'bank_id')
        ensureColumnIsVarchar('bcc_loan_interest_rates', 'bank_id')
        ensureColumnIsVarchar('bcc_safety_deposit_boxes', 'id')
        ensureColumnIsVarchar('bcc_safety_deposit_boxes', 'bank_id')
        ensureColumnIsVarchar('bcc_safety_deposit_boxes_access', 'safety_deposit_box_id')
        ensureColumnIsVarchar('bcc_transactions', 'id')
        ensureOptionalColumnIsVarchar('bcc_transactions', 'account_id')
        ensureOptionalColumnIsVarchar('bcc_transactions', 'loan_id')

        -- Build mapping tables for legacy identifiers
        local bankMappingCount = legacyBanks
        if bankMappingCount > 0 then
            buildMappingTable('bcc_banks', 'id', 'bcc_migration_tmp_banks')
            migrateBanks('bcc_migration_tmp_banks')
            totalConverted = totalConverted + bankMappingCount
        end

        local accountMappingCount = legacyAccounts
        if accountMappingCount > 0 then
            buildMappingTable('bcc_accounts', 'id', 'bcc_migration_tmp_accounts')
            migrateAccounts('bcc_migration_tmp_accounts')
            totalConverted = totalConverted + accountMappingCount
        end

        local sdbMappingCount = legacySDBs
        if sdbMappingCount > 0 then
            buildMappingTable('bcc_safety_deposit_boxes', 'id', 'bcc_migration_tmp_sdbs')
            migrateSafetyDepositBoxes('bcc_migration_tmp_sdbs')
            totalConverted = totalConverted + sdbMappingCount
        end

        local loanMappingCount = legacyLoans
        if loanMappingCount > 0 then
            buildMappingTable('bcc_loans', 'id', 'bcc_migration_tmp_loans')
            migrateLoans('bcc_migration_tmp_loans')
            totalConverted = totalConverted + loanMappingCount
        end

        local loanPaymentMappingCount = legacyLoanPayments
        if loanPaymentMappingCount > 0 then
            buildMappingTable('bcc_loans_payments', 'id', 'bcc_migration_tmp_loan_payments')
            migrateLoanPayments('bcc_migration_tmp_loan_payments')
            totalConverted = totalConverted + loanPaymentMappingCount
        end

        local transactionMappingCount = legacyTransactions
        if transactionMappingCount > 0 then
            buildMappingTable('bcc_transactions', 'id', 'bcc_migration_tmp_transactions')
            migrateTransactions('bcc_migration_tmp_transactions')
            totalConverted = totalConverted + transactionMappingCount
        end

        -- Clean up orphaned data created by deleted banks
        cleanupOrphans()

        -- Drop mapping tables
        dropMappingTable('bcc_migration_tmp_transactions')
        dropMappingTable('bcc_migration_tmp_loan_payments')
        dropMappingTable('bcc_migration_tmp_loans')
        dropMappingTable('bcc_migration_tmp_sdbs')
        dropMappingTable('bcc_migration_tmp_accounts')
        dropMappingTable('bcc_migration_tmp_banks')

        -- Restore foreign keys
        restoreForeignKeys()
    end)

    if fkDisabled then
        MySQL.query.await('SET FOREIGN_KEY_CHECKS = 1;')
    end

    if not ok then
        error(err)
    end

    devPrint(string.format('[migration] Legacy migration complete. %d primary identifiers converted to UUIDs.', totalConverted))
end

CreateThread(function()
    Wait(1500)
    local ok, err = pcall(RunLegacyIdMigration)
    if not ok and err then
        print(('^1[bcc-banks] Legacy ID migration failed: %s^0'):format(err))
    end
end)
