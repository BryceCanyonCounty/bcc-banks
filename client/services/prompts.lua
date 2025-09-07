local OpenGroup = BccUtils.Prompt:SetupPromptGroup()
local OpenPrompt = nil
local ClosedGroup = BccUtils.Prompt:SetupPromptGroup()
local ClosePrompt = nil

function GetOpenPromptGroup()
  return OpenGroup
end

function GetOpenPrompt()
  return OpenPrompt
end

function GetClosedPromptGroup()
  return ClosedGroup
end

function BankOpen()
  if not OpenPrompt then
    OpenPrompt = OpenGroup:RegisterPrompt('Menu', Config.PromptSettings.TellerKey, 1, 1, false, 'hold',
      { timedeventhash = "SHORT_TIMED_EVENT" })
  end
end

function BankClosed()
  if not ClosePrompt then
    ClosedPrompt = ClosedGroup:RegisterPrompt('Menu', Config.PromptSettings.TellerKey, 0, 1, false, 'hold',
      { timedeventhash = "SHORT_TIMED_EVENT" })
  end
end

function DeletePrompts()
  if ClosedPrompt then
    ClosedPrompt:DeletePrompt()
    ClosedPrompt = nil
  end

  if OpenPrompt then
    OpenPrompt:DeletePrompt()
    OpenPrompt = nil
  end
end
