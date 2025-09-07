VORPcore = exports.vorp_core:GetCore()
BccUtils = exports['bcc-utils'].initiate()
Discord = BccUtils.Discord.setup(Config.WebhookLink, Config.WebhookTitle, Config.WebhookAvatar) -- Setup Discord webhook