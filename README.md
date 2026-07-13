# LuaTyping

为 Lua 添加**内联类型注解**的实验性语言扩展，包含转译器/解释器和语言服务器两个子项目。

## 项目组成

| 子项目 | 说明 | 仓库 |
|--------|------|------|
| [tlua](tlua/) | TypingLua 转译器 & 解释器（C 语言实现） | [DingSongYun/tlua](https://github.com/DingSongYun/tlua) |
| [tlua-language-server](tlua-language-server/) | TypingLua 语言服务器（基于 LuaLS fork） | [DingSongYun/lua-language-server](https://github.com/DingSongYun/lua-language-server) |
| [vscode-tlua](ide-plugins/vscode-tlua/) | VSCode 扩展（对 .lua 启动内嵌 LSP server，LSP-only） | — |
| [rider-tlua](ide-plugins/rider-tlua/) | Rider 插件（对 .lua 启动内嵌 LSP server，LSP-only，独立，不依赖 EmmyLua） | — |

## 安装编辑器插件

TypingLua 的类型标注直接写在标准 `.lua` 文件里（如 `local x: number = 42`）。两个插件各自内嵌 Windows 版 LSP server 运行时，对 `.lua` 文件启动 fork 的 server，提供补全/悬停/诊断。**插件只负责 LSP，不提供语法高亮** —— 高亮由用户自选的 Lua 扩展（官方 sumneko.lua / EmmyLua 等）提供。

### 启用内联标注

在 `.lua` 文件**第 1 行**写 `---@lua-typing` 标记，server 才会解析该文件的内联类型标注；无标记的 `.lua` 按普通 Lua 处理。这样同一工作区可混用 TypingLua 文件与普通 Lua 文件，且与官方 Lua 扩展零冲突。

标记匹配较宽松：`--` 或 `---`（≥2 个减号）+ 任意空格 + 连续的 `@lua-typing`（不可被空格打断）。`---@lua-typing`、`--@lua-typing`、`--- @lua-typing` 均合法。

```lua
---@lua-typing
local x: number = 42
local function add(a: number, b: number): number
    return a + b
end
```

前置：`tlua-language-server/` 已构建（`bin/lua-language-server.exe` 存在）。

### VSCode

```bash
cd ide-plugins/vscode-tlua
bash scripts/copy-server.sh   # 拷贝 server 运行时到 server/
npm install
npm run compile
npx @vscode/vsce package      # → tlua-0.1.0.vsix
code --install-extension tlua-0.1.0.vsix
```

或 VSCode → 扩展 → ⋯ → 从 VSIX 安装。配置项 `tluaLsp.serverPath` 可覆盖内嵌 server 路径。

> 若官方 `sumneko.lua` 同时启用其 LSP server，会与本插件产生双重诊断，建议二选一。

### Rider

前置：本机已装 JDK 17+ 和 Gradle 8.10+（或用 Rider 自带 JBR）。

```bash
cd ide-plugins/rider-tlua
bash scripts/copy-server.sh                      # 拷贝 server 运行时到 resources/bin/
gradle wrapper --gradle-version 8.10             # 首次：生成 gradlew
./gradlew buildPlugin                            # → build/distributions/rider-tlua-0.1.0.zip
```

Rider → Settings → Plugins → ⚙ → Install Plugin from Disk → 选 zip。

> 注：Rider 插件依赖 `com.intellij.modules.lsp`，仅商业版 IntelliJ IDE（Rider / IDEA Ultimate 等）可用，IDEA Community / Android Studio 不支持。

## 核心理念

TypingLua 的内联类型标注直接写在 Lua 代码里，转译器通过 **Type Erasure** 将类型信息完全剥离，输出标准 Lua 5.4 代码。类型信息仅用于静态分析（语言服务器），不影响运行时行为。

支持两种文件形式：

- **`.lua` + 首行 `---@lua-typing` 标记**（推荐）：转译器与 LSP server 据此启用类型标注语义；无标记的 `.lua` 按普通 Lua 处理（原样透传）。
- **`.tlua` 扩展名**（兼容）：总是被转译，不论是否含标记。

```lua
-- examples/demo.tlua（.tlua 无需标记；若用 .lua 需首行写 ---@lua-typing）
local function add(a: number, b: number): number
    return a + b
end

local scores: number[] = {90, 85, 92}
local config: {string: any} = {host = "localhost", port = 8080}
```

转译输出（标准 Lua）：

```lua
local function add(a, b)
    return a + b
end

local scores = {90, 85, 92}
local config = {host = "localhost", port = 8080}
```

## 快速开始

### 前置条件

- **Visual Studio 2022+**（含 C/C++ 工作负载）
- **CMake** 3.15+
- **Ninja** 构建系统

### 构建 tlua

```bash
cd tlua
# 使用 smoke.sh 一键构建（自动配置 MSVC 环境）
.claude/skills/run-tlua/smoke.sh build
```

### 运行 TypingLua 文件

```bash
cd tlua
# 运行 .tlua（总是转译）
build/tlua.exe examples/demo.tlua

# 运行 .lua（首行有 ---@lua-typing 标记才转译，否则按普通 Lua 执行）
build/tlua.exe path/to/marked.lua

# 执行内联代码（总是转译）
build/tlua.exe -e "local x: number = 42; print(x)"

# 转译为 .lua
build/tluac.exe -p examples/demo.tlua          # .tlua 总是转译
build/tluac.exe -p path/to/marked.lua          # .lua 有标记才转译，无标记原样输出
```

### 构建语言服务器

```bash
cd tlua-language-server
git submodule update --init --recursive
.claude/skills/run-tlua-language-server/smoke.sh build
```

### 运行测试

```bash
# tlua 测试（83 个用例）
cd tlua && .claude/skills/run-tlua/smoke.sh test

# 语言服务器测试
cd tlua-language-server && .claude/skills/run-tlua-language-server/smoke.sh test
```

## 类型语法概览

| 语法 | 示例 |
|------|------|
| 基本类型 | `local x: number = 42` |
| 联合类型 | `local id: number \| string` |
| 可选类型 | `local name: string? = nil` |
| 数组类型 | `local items: number[] = {1, 2, 3}` |
| 表泛型 | `local m: table<string, number>` |
| 函数类型 | `local fn: fun(x: number): string` |
| 多返回值 | `function f(): number, string` |
| 方法声明 | `function obj:getName(): string` |

> 完整语法参考：[`tlua/docs/tlua-reference.md`](tlua/docs/tlua-reference.md)

## 项目结构

```
LuaTyping/
├── tlua/                       # TypingLua 核心（C 语言）
│   ├── tlua/                   #   词法分析器 + 语法解析器/转译器
│   ├── lua/                    #   Lua 5.4.7 官方源码
│   ├── tests/                  #   单元测试 + E2E 测试 + 运行时测试
│   ├── examples/               #   .tlua 示例文件
│   ├── docs/                   #   语法文档 & EBNF
│   └── CMakeLists.txt          #   CMake 构建配置
├── tlua-language-server/       # 语言服务器（LuaLS fork）
│   ├── script/                 #   LSP 功能实现（Lua）
│   │   ├── parser/             #     PEG 解析器
│   │   ├── core/               #     补全/悬停/定义/诊断等
│   │   └── vm/                 #     类型推断引擎
│   ├── test/                   #   测试套件
│   ├── 3rd/                    #   依赖（bee.lua, luamake, lpeglabel）
│   └── make.lua                #   构建配置
├── ide-plugins/                # 编辑器插件（LSP-only）
│   ├── vscode-tlua/            #   VSCode 扩展（npm + tsc + vscode-languageclient）
│   └── rider-tlua/             #   Rider 插件（Kotlin + Gradle + IntelliJ LSP API）
└── README.md                   # 本文件
```

## 开发指南

每个子项目都有对应的 Claude Code skill，提供完整的构建/运行/测试自动化：

- **`/run-tlua`** — 开发 tlua 转译器/解释器
- **`/run-tlua-language-server`** — 开发语言服务器

详见各子项目中的 `.claude/skills/` 目录。

## License

- `tlua/` 中的 Lua 源码遵循 [MIT License](https://www.lua.org/license.html)
- `tlua-language-server/` 遵循上游 [MIT License](tlua-language-server/LICENSE)
