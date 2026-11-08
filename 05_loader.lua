-- BF License GUI: standalone public loader; script only executes after Worker validation.
-- Device binding is a persistent installation ID, not a hardware ID.
local WORKER_URL = 'https://bf-license-worker.leducho1900.workers.dev'
local HS=game:GetService('HttpService')
local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local pg=Players.LocalPlayer:WaitForChild('PlayerGui')
local env=(getgenv and getgenv()) or _G
if env.BF_LICENSE_GUI_STOP then pcall(env.BF_LICENSE_GUI_STOP) end
local stopped=false
local conn={}
local gui=Instance.new('ScreenGui')
gui.Name='BF_License_KeyGui'
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.DisplayOrder=999998
gui.Parent=pg
local function cleanup()
 if stopped then return end
 stopped=true
 for _,c in ipairs(conn) do pcall(function() c:Disconnect() end) end
 if gui and gui.Parent then gui:Destroy() end
end
env.BF_LICENSE_GUI_STOP=cleanup
local function requestFn()
 return (syn and syn.request) or http_request or request
end
local function post(path,body,expectLua)
 local fn=requestFn()
 if type(fn)~='function' then return nil,'HTTP_UNAVAILABLE' end
 local ok,res=pcall(fn,{Url=WORKER_URL..path,Method='POST',Headers={['Content-Type']='application/json'},Body=HS:JSONEncode(body)})
 if not ok or type(res)~='table' then return nil,'NETWORK_ERROR' end
 local status=tonumber(res.StatusCode or res.Status or 0)
 local content=tostring(res.Body or '')
 if expectLua and status==200 then
  if content=='' then return nil,'EMPTY_SCRIPT' end
  return content,nil
 end
 local decoded,data=pcall(function() return HS:JSONDecode(content) end)
 if not decoded or type(data)~='table' then return nil,'SERVER_RESPONSE_ERROR' end
 if status~=200 or not data.ok then return nil,tostring(data.error or 'SERVER_ERROR') end
 return data,nil
end
local path='BF_LICENSE_INSTALL_ID.txt'
local savedKeyPath='BF_LICENSE_SAVED_KEY.txt'
local function saveKey(key)
 if type(writefile)=='function' then pcall(writefile,savedKeyPath,key) end
end
local function clearSavedKey()
 if type(delfile)=='function' then pcall(delfile,savedKeyPath)
 elseif type(writefile)=='function' then pcall(writefile,savedKeyPath,'') end
end
local savedKey=nil
if type(isfile)=='function' and type(readfile)=='function' then
 pcall(function() if isfile(savedKeyPath) then savedKey=readfile(savedKeyPath) end end)
end
if type(savedKey)~='string' or #savedKey<16 or #savedKey>128 then savedKey=nil end
local device
if type(isfile)=='function' and type(readfile)=='function' then
 pcall(function() if isfile(path) then device=readfile(path) end end)
end
if type(device)~='string' or #device<20 or #device>100 or not device:match('^[%w_-]+$') then
 device=HS:GenerateGUID(false):gsub('%-','')..HS:GenerateGUID(false):gsub('%-','')
 if type(writefile)=='function' then pcall(writefile,path,device) end
end
local frame=Instance.new('Frame')
frame.Name='Panel';frame.Size=UDim2.fromOffset(390,212)
frame.Position=UDim2.new(.5,-195,.5,-106)
frame.BackgroundColor3=Color3.fromRGB(23,27,37)
frame.BorderSizePixel=0;frame.Active=true;frame.Draggable=true;frame.Parent=gui
Instance.new('UICorner',frame).CornerRadius=UDim.new(0,12)
local function label(name,str,y,h,size)
 local o=Instance.new('TextLabel')
 o.Name=name;o.Size=UDim2.new(1,-32,0,h);o.Position=UDim2.fromOffset(16,y)
 o.BackgroundTransparency=1;o.Text=str;o.TextSize=size or 14
 o.TextColor3=Color3.fromRGB(235,239,248);o.Font=Enum.Font.Gotham
 o.TextWrapped=true;o.Parent=frame
 return o
end
local title=label('Title','BLOX FRUITS  |  KEY',12,30,17)
title.Font=Enum.Font.GothamBold
local entry=Instance.new('TextBox')
entry.Name='KeyInput';entry.Size=UDim2.new(1,-32,0,39);entry.Position=UDim2.fromOffset(16,55)
entry.BackgroundColor3=Color3.fromRGB(42,49,64);entry.BorderSizePixel=0
entry.Text='';entry.PlaceholderText='Nhập key';entry.ClearTextOnFocus=false
entry.TextColor3=Color3.new(1,1,1);entry.PlaceholderColor3=Color3.fromRGB(160,168,183)
entry.Font=Enum.Font.Gotham;entry.TextSize=14;entry.Parent=frame
Instance.new('UICorner',entry).CornerRadius=UDim.new(0,7)
local status=label('Status','Nhập key để tiếp tục',101,36,13)
local go=Instance.new('TextButton')
go.Name='Submit';go.Size=UDim2.new(1,-32,0,40);go.Position=UDim2.fromOffset(16,151)
go.BackgroundColor3=Color3.fromRGB(38,131,101);go.BorderSizePixel=0
 go.Text='XÁC NHẬN KEY';go.TextColor3=Color3.new(1,1,1)
go.Font=Enum.Font.GothamBold;go.TextSize=14;go.Parent=frame
Instance.new('UICorner',go).CornerRadius=UDim.new(0,7)
local errorText={
 INVALID_INPUT='Key không hợp lệ',INVALID_KEY='Key sai',RELOGIN_REQUIRED='Vui lòng nhập key lại',
 INVALID_OR_REVOKED='Key sai hoặc đã bị khóa',KEY_LOCKED='Key đã bị khóa',
 EXPIRED='Key đã hết hạn',BOUND_TO_OTHER_DEVICE='Key đã liên kết với thiết bị khác',
 RETRY='Vui lòng thử lại',UNAUTHORIZED='Key không còn hợp lệ',
 SOURCE_UNAVAILABLE='Không tải được script',NETWORK_ERROR='Lỗi kết nối',
 HTTP_UNAVAILABLE='Không hỗ trợ kết nối',SERVER_ERROR='Lỗi máy chủ',
 SERVER_RESPONSE_ERROR='Phản hồi máy chủ không hợp lệ',EMPTY_SCRIPT='Script trống'
}
local busy=false
local function setStatus(s,ok)
 if stopped then return end
 status.Text=s
 status.TextColor3=ok and Color3.fromRGB(118,230,168) or Color3.fromRGB(255,169,169)
end
local function resetButton()
 if stopped then return end
 go.Text='XÁC NHẬN KEY';go.AutoButtonColor=true;busy=false
end
local function checkAndLoad(key,auto)
 if busy or stopped then return end
 busy=true
 go.Text='ĐANG KIỂM TRA...';go.AutoButtonColor=false
 status.TextColor3=Color3.fromRGB(235,239,248)
 status.Text='Đang kiểm tra key...'
 task.spawn(function()
  local verified,err=post('/api/verify',{key=key,device=device,auto=auto==true},false)
  if stopped then return end
  if not verified then
   if auto then
    clearSavedKey();savedKey=nil
    frame.Visible=true;entry.Text=''
   end
   setStatus(errorText[err] or ('Lỗi: '..tostring(err)),false)
   resetButton();return
  end
  setStatus('Key đúng! Đang tải chức năng...',true)
  go.Text='ĐANG TẢI...'
  local code,downloadErr=post('/api/script',{key=key,device=device},true)
  if stopped then return end
  if not code then
   if auto and (downloadErr=='UNAUTHORIZED' or downloadErr=='INVALID_KEY' or downloadErr=='KEY_LOCKED') then
    clearSavedKey();savedKey=nil;frame.Visible=true;entry.Text=''
   end
   setStatus(errorText[downloadErr] or ('Không tải được: '..tostring(downloadErr)),false)
   resetButton();return
  end
  local compiled,compileErr=loadstring(code)
  if not compiled then
   if auto then frame.Visible=true end
   setStatus('Không thể chạy script đã tải',false)
   warn('[BF License] compile failed:',compileErr)
   resetButton();return
  end
  -- Only persist after validation and successful script compilation.
  saveKey(key)
  cleanup()
  task.spawn(function()
   local ok,runErr=pcall(compiled)
   if not ok then warn('[BF License] script failed:',runErr) end
  end)
 end)
end
local function submit()
 if busy or stopped then return end
 local key=entry.Text:match('^%s*(.-)%s*$')
 if key=='' then setStatus('Vui lòng nhập key',false);return end
 checkAndLoad(key,false)
end
table.insert(conn,go.MouseButton1Click:Connect(submit))
table.insert(conn,entry.FocusLost:Connect(function(enter)if enter then submit() end end))
if savedKey then
 frame.Visible=false
 checkAndLoad(savedKey,true)
end
