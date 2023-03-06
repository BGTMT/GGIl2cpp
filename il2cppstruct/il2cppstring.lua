local AndroidInfo = require("utils.androidinfo")

---@class StringApi
---@field address number
---@field Fields table<string, number>
---@field ClassAddress number
local StringApi = {


    ---@param self StringApi
    ---@param newStr string
    EditString = function(self, newStr)
        local _stringLength = gg.getValues{{address = self.address + self.Fields._stringLength, flags = gg.TYPE_DWORD}}[1].value
        local bytes = gg.bytes(newStr, "UTF-16LE")
        if _stringLength * 2 >= #bytes then
            local strStart = self.address + self.Fields._firstChar
            for i, v in ipairs(bytes) do
                bytes[i] = {
                    address = strStart + (i - 1),
                    flags = gg.TYPE_BYTE,
                    value = v
                }
            end

            if #bytes % 2 == 1 then
                bytes[#bytes + 1] = {
                    address = bytes[#bytes].address + 0x1,
                    flags = gg.TYPE_BYTE,
                    value = 0
                }
            end

            gg.setValues(bytes)
        end
    end,



    ---@param self StringApi
    ---@return string
    ReadString = function(self)
        local _stringLength = gg.getValues{{address = self.address + self.Fields._stringLength, flags = gg.TYPE_DWORD}}[1].value
        local bytes = {}
        if _stringLength > 0 and _stringLength < 200 then
            local strStart = self.address + self.Fields._firstChar
            for i = 0, _stringLength do
                bytes[#bytes + 1] = {
                    address = strStart + (i << 1),
                    flags = gg.TYPE_WORD
                }
            end
            bytes = gg.getValues(bytes)
            local code = {"return table.concat({"}
            for i, v in ipairs(bytes) do
                code[#code + 1] = string.format([["\u{%x}",]], v.value & 0xFFFF)
            end
            code[#code + 1] = "})"
            local read, err = load(table.concat(code))
            if read then
                return read()
            end
        end
        return ""
    end
}

local String = {

    ---@param address number
    From = function(address)
        local str = setmetatable({address = Il2cpp.FixValue(address), Fields = {}}, {__index = StringApi})
        local pointClassAddress = gg.getValues({{address = str.address, flags = Il2cpp.MainType}})[1].value
        local stringInfo = Il2cpp.FindClass({{Class = Il2cpp.FixValue(pointClassAddress), FieldsDump = true}})[1]
        for i, v in ipairs(stringInfo) do
            if v.ClassNameSpace == "System" then
                str.ClassAddress = tonumber(v.ClassAddress, 16)
                for indexField, FieldInfo in ipairs(v.Fields) do
                    str.Fields[FieldInfo.FieldName] = tonumber(FieldInfo.Offset, 16)
                end
            end
        end
        return str
    end,
    
}

return String