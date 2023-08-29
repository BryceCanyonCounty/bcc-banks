function LoadModel(model)
  RequestModel(model)
  while not HasModelLoaded(model) do
    RequestModel(model)
    Wait(100)
  end
end
