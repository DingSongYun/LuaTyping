# TypingLua Language Server for Visual Studio Code

对 `.lua` 文件启动 TypingLua 语言服务器（LuaLS fork），提供内联类型标注（`local x: number = 42`、`function f(a: number): string`）的补全、悬停、诊断。

**本扩展只负责 LSP，不提供语法高亮。** 高亮由你自选的 Lua 扩展（如官方 `sumneko.lua`）提供。

## 启用 TypingLua 内联标注

在 `.lua` 文件**第 1 行**写标记：

```lua
---@lua-typing
local x: number = 42
local function add(a: number, b: number): number
    return a + b
end
```

- 有标记的文件：server 解析内联类型标注，提供类型补全/悬停/诊断。
- 无标记的 `.lua` 文件：按普通 Lua 处理（与标准 LuaLS 行为一致），不解析内联标注。

标记匹配规则（第 1 行，去前导空白后）：`--` 或 `---`（≥2 个减号）+ 任意空格 + 连续的 `@lua-typing`。大小写敏感；`@lua-typing` 不可被空格打断；允许行尾后缀。以下都合法：

```lua
---@lua-typing
-- @lua-typing
---    @lua-typing
---@lua-typing strict
```

## 构建

前置：`tlua-language-server/` 已构建（`bin/lua-language-server.exe` 存在）。

```bash
cd vscode-tlua
bash scripts/copy-server.sh   # 拷贝 server 运行时到 server/
npm install
npm run compile
npx @vscode/vsce package      # → tlua-0.1.0.vsix
```

## 安装

```bash
code --install-extension tlua-0.1.0.vsix
```

或 VSCode → 扩展 → ⋯ → 从 VSIX 安装。

## 配置

- `tluaLsp.serverPath`：自定义 server 可执行文件路径，留空则用内嵌 server。

## 与官方 Lua 扩展共存

本扩展不提供高亮，高亮请保留你惯用的 Lua 扩展。但若该扩展（如 `sumneko.lua`）同时启用了它自己的 LSP server，同一 `.lua` 文件会有两个 server，可能产生双重诊断/补全冲突。建议二选一：

- 保留本扩展做 LSP，禁用官方扩展的 server（如 `sumneko.lua` 设置 `"lua.languageServerVariable": ""` 或禁用扩展）；
- 或仅用本扩展，卸载官方 Lua 扩展。

## 平台

仅 Windows（内嵌 `lua-language-server.exe`）。
