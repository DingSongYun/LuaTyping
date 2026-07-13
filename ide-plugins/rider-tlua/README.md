# TypingLua Language Server for Rider

对 `.lua` 文件启动 TypingLua 语言服务器（LuaLS fork），提供内联类型标注（`local x: number = 42`、`function f(a: number): string`）的补全、悬停、诊断。

**本插件只负责 LSP，不提供语法高亮。** 高亮由你自选的 Lua 插件（如 EmmyLua）提供，不依赖 EmmyLua。

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
- 无标记的 `.lua` 文件：按普通 Lua 处理，不解析内联标注。

标记匹配规则（第 1 行，去前导空白后）：`--` 或 `---`（≥2 个减号）+ 任意空格 + 连续的 `@lua-typing`。大小写敏感；`@lua-typing` 不可被空格打断。合法写法：`---@lua-typing`、`--@lua-typing`、`---    @lua-typing`。

## 构建

前置：本机已装 JDK 17+ 和 Gradle 8.10+（或用 Rider 自带 JBR）；`tlua-language-server/` 已构建（`bin/lua-language-server.exe` 存在）。

```bash
cd rider-tlua
bash scripts/copy-server.sh                      # 拷贝 server 运行时到 resources/bin/
gradle wrapper --gradle-version 8.10             # 首次：生成 gradlew
./gradlew buildPlugin                            # → build/distributions/rider-tlua-0.1.0.zip
```

## 安装

Rider → Settings → Plugins → ⚙ → Install Plugin from Disk → 选 `rider-tlua-0.1.0.zip`。

## 与官方 Lua 插件共存

本插件不提供高亮，高亮请保留你惯用的 Lua 插件（如 EmmyLua）。但若该插件同时启用了它自己的 LSP server，同一 `.lua` 文件会有两个 server，可能产生双重诊断/补全冲突。建议二选一：保留本插件做 LSP 并禁用另一插件的 server，或反之。

## 兼容性

- 仅 Windows（内嵌 `lua-language-server.exe`）。
- 依赖 `com.intellij.modules.lsp`，仅商业版 IntelliJ IDE（Rider / IDEA Ultimate 等）可用，IDEA Community / Android Studio 不支持。
