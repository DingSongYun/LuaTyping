# LuaTyping

为 Lua 添加**内联类型注解**的实验性语言扩展，包含转译器/解释器和语言服务器两个子项目。

## 项目组成

| 子项目 | 说明 | 仓库 |
|--------|------|------|
| [tlua](tlua/) | TypingLua 转译器 & 解释器（C 语言实现） | [DingSongYun/tlua](https://github.com/DingSongYun/tlua) |
| [tlua-language-server](tlua-language-server/) | TypingLua 语言服务器（基于 LuaLS fork） | [DingSongYun/lua-language-server](https://github.com/DingSongYun/lua-language-server) |

## 核心理念

`.tlua` 文件使用冒号语法进行内联类型标注，转译器通过 **Type Erasure** 将类型信息完全剥离，输出标准 Lua 5.4 代码。类型信息仅用于静态分析（语言服务器），不影响运行时行为。

```lua
-- examples/demo.tlua
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

### 运行 .tlua 文件

```bash
cd tlua
# 直接运行
build/tlua.exe examples/demo.tlua

# 执行内联代码
build/tlua.exe -e "local x: number = 42; print(x)"

# 转译为 .lua
build/tluac.exe -p examples/demo.tlua
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
