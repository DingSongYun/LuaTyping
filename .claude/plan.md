# TypingLua 接入 UE5.6 游戏工程方案评审

## 背景

将 tlua 内联类型标注方案接入 UE5.6 游戏工程（使用 UnLua/sluaunreal 作为 Lua 绑定层）。

---

## 一、方案层评审（架构 & 方向性问题）

### ✅ 已验证可行的设计决策

1. **Type Erasure 策略正确**：运行时与标准 Lua 完全兼容，UE 绑定层零感知
2. **复用 LuaLS 类型系统**：不重造轮子，hover/completion/goto-def/diagnostics 全部可用
3. **inline doc → ast.docs 注入管线**：与原有 `@class`/`@alias` 注解和平共存

---

### ⚠️ P0 — 阻塞性问题：自定义类型名 (UE 类) 的解析支持

**现状**：`parseInlineTypeName()` 接受任意 word token，所以 `UObject`、`AActor`、`FVector` 等名称在 parser 层已经可以通过。

**问题**：EBNF grammar 和 reference doc 中 `primary_type` 只列出了 11 个 base_type 关键字和 `table<K,V>` / `fun()` 三种形式。**没有明确的 `user_defined_type` 产生式**。这意味着：

- 文档与实现不一致（实现已支持，文档未覆盖）
- 用户不知道可以写 `local actor: AActor`
- **泛型 UE 容器**（如 `TArray<FVector>`、`TMap<FString, int32>`）依赖 `<T>` 语法已经实现，但文档没说明

**建议修复**：
1. EBNF 中 `primary_type` 增加 `user_type_name = identifier [ generic_args ]` 产生式
2. Reference doc 增加 "自定义类型" 章节，说明需配合 `@class` 定义使用
3. 增加示例展示 UE 类型用法

---

### ⚠️ P1 — 方案缺口：没有 `@class` / `@alias` 的内联替代方案

**问题**：在 UE5 游戏工程中，类型定义有两个来源：
1. **UnLua IntelliSense 自动导出**的 `@class` 注解文件（C++ 反射类）
2. **业务层自定义类型**（游戏内 Lua 类、协议结构体等）

对于来源 1，已有成熟的 EmmyLua stub 生成管线，`@class` 定义会被 LuaLS 正常加载。

对于来源 2，当前方案**要求用户写 EmmyLua `---@class` 注释来定义类型**，然后才能在 inline 标注中引用。这种"混合模式"（inline 标注 + comment 定义）虽然可行，但对用户心智模型是割裂的。

**建议**：
- **短期（推荐）**：接受混合模式，因为 UnLua stub 已经是 `@class` 格式；业务层定义也延续此方式
- **中期**：考虑增加 inline class/interface 声明语法（如 `class MyClass extends BaseClass { ... }`），但优先级不高
- **结论**：当前不阻塞接入，但需要在文档中明确说明 "inline 标注引用的类型需要通过 `@class` 或 stub 文件预先定义"

---

### ⚠️ P2 — 方案缺口：`.tlua` vs `.lua` 文件扩展名策略

**问题**：UE5 游戏工程中 Lua 文件走 `.lua` 扩展名。UnLua 的文件加载机制硬编码了 `.lua` 后缀（`Content/Script/xxx.lua`）。

两种策略的权衡：

| 策略 | 优点 | 缺点 |
|------|------|------|
| A: 保持 `.tlua`，构建时转译为 `.lua` | 清晰分离源码/产物；不影响运行时 | 需要构建管线；热重载复杂度增加；IDE 文件关联要额外配置 |
| B: 直接用 `.lua`，语言服务器开关 inline 模式 | 零构建成本；无文件关联问题；热重载正常 | 标准 Lua 文件混入非标准语法；其他工具（luacheck等）会报错 |

**建议**：**选择策略 B** — 在 `.lua` 文件中启用 inline 类型标注。原因：
1. UE5 工程已有 Lua 热重载机制，不希望增加转译步骤
2. Language server 已经在 `.lua` 文件中支持 inline 解析（`files.lua` 的判断逻辑）
3. 可以通过 `.luarc.json` 配置或 workspace setting 控制是否启用 inline 模式
4. 运行时发生在 UE 引擎内，不需要 tlua.exe 转译器

**需要实现**：
- 语言服务器需要一个配置开关：`"Lua.typingLua.enabled": true`
- 当 enabled 时，对所有 `.lua` 文件启用 inline 类型解析
- 运行时：UE 引擎加载 `.lua` 文件时，需要一个轻量 type-strip 预处理器（或直接在 UnLua 加载层 hook）

---

### ⚠️ P3 — 方案缺口：运行时类型擦除集成

**问题**：如果选择策略 B（`.lua` 文件内含 inline 标注），UE 引擎加载该文件时会报语法错误（标准 Lua parser 不认识 `: type`）。

**解决方案选项**：

| 方案 | 描述 | 改动量 |
|------|------|--------|
| R1: 构建时批量转译 | 项目 cook/package 时自动 strip | 中等（CI/CD 管线） |
| R2: UnLua 加载 hook | 在 `FLuaContext::LoadFile` 层 hook，加载前 strip | 小（C++ 几十行） |
| R3: 自定义 Lua reader | 实现 `lua_Reader` 级 type strip | 最小（C 层几十行） |
| R4: 双文件模式 | 编辑 `.tlua`，watch + auto-transpile 为 `.lua` | 需要文件监听服务 |

**建议**：
- **开发阶段用 R2/R3**（UnLua 加载时自动 strip，开发者写 inline 类型的 `.lua` 文件，UE 运行时透明处理）
- **发布阶段用 R1**（构建管线中批量转译，发布包只含标准 `.lua`）
- tlua 的 C transpiler 已经实现了完整的 type erasure，可以直接集成为库

---

### ⚠️ P4 — 方案缺口：UE 泛型容器类型映射

**问题**：UnLua IntelliSense 导出的类型映射：

| UE C++ 类型 | 导出的 Lua 注解 |
|-------------|----------------|
| `TArray<FVector>` | `TArray<FVector>` |
| `TMap<FString, int32>` | `TMap<FString, int32>` |
| `TSubclassOf<AActor>` | `TSubclassOf<AActor>` |

当前 inline 类型解析支持 `table<K,V>` 泛型语法。但 UE 的容器不是 `table`，而是 `TArray`/`TMap`/`TSet`。

**现状验证**：`parseInlineTypeSign()` 已经实现了通用的 `<T>` 泛型解析，不局限于 `table`。所以：

```lua
local positions: TArray<FVector> = {}  -- ✅ parser 已支持
local lookup: TMap<string, AActor> = {} -- ✅ parser 已支持
```

**结论**：当前实现已经支持，只需要确保：
1. UnLua stub 文件中有 `---@class TArray<T>` 的泛型定义
2. Language server 能正确解析泛型实例化

---

### ⚠️ P5 — 方案建议：Delegate / Event 类型表达

**问题**：UE5 Lua 开发中最常见的痛点之一是 delegate 绑定：

```lua
-- UnLua 模式
self.Button.OnClicked:Add(self, self.OnButtonClicked)
-- 没有任何类型提示告诉你 OnButtonClicked 的签名应该是什么
```

UnLua stub 导出 delegate 时只标注 `Delegate` 或 `MulticastDelegate`，丢失了签名信息。

**建议**：这是 UnLua stub 生成器的问题，不是 tlua 方案层的问题。但可以：
1. 提供自定义 stub 增强工具，将 delegate 导出为带签名的 `fun()` 类型
2. 在 tlua 文档中说明如何手动补充 delegate 类型定义

---

### ⚠️ P6 — 方案建议：`self` 类型推断

**问题**：UE5 Lua 中大量使用 `:` 方法语法：

```lua
function BP_MyActor_C:ReceiveBeginPlay()
    self.Health = 100  -- self 的类型是什么？
end
```

LuaLS 原有机制：通过文件路径 + `@class` 注解推断 `self` 类型。UnLua 模式下文件名对应 Blueprint 名，理论上可以自动绑定。

**建议**：
1. 确认 LuaLS 的 `self` 推断机制在 inline 模式下仍然工作
2. 如果不工作，考虑增加文件级类型声明（如首行 `-- @self BP_MyActor_C`）

---

## 二、实现层评审（代码质量 & 缺陷）

### 🔴 I1 — `registerInlineDoc` 的 originalComment sentinel 不完整

**问题**：当前 sentinel 只有 `type`、`start`、`finish`、`text` 四个字段。但 LuaLS 代码中还有些地方会访问 `originalComment.uri`、`originalComment[1]`（content）等字段。

**风险**：如果未来 LuaLS 版本或第三方插件访问这些字段，会 nil-index crash。

**建议**：增加防御性字段，或者在需要 `originalComment` 的 API 调用点加 nil guard。

---

### 🔴 I2 — inline 类型标注与 `---@type` 注释共存时的冲突

**问题**：如果用户同时写了 EmmyLua 注释和 inline 标注：

```lua
---@type string
local x: number = 42  -- 哪个类型生效？
```

当前行为：两者都会注入到 `ast.docs`，可能产生冲突或不确定的类型推断。

**建议**：
1. 明确优先级规则（inline 优先于 comment？或报 warning？）
2. 在文档中明确说明

---

### 🟡 I3 — `parseInlineType()` 的终止条件可能误匹配

**问题**：返回类型解析时，parser 贪婪读取类型表达式直到遇到 "不能作为类型一部分的 token"。但在某些场景下，可能误将后续代码当作类型的一部分。

例如：
```lua
local function foo(): table
    local x = 1  -- "local" 终止了返回类型解析
end
```

但如果是：
```lua
-- UE5 常见模式：返回后立即用
local result: AActor = self:SpawnActor(...)
```

这里 `= self:SpawnActor(...)` 中的 `=` 能正确终止类型解析吗？需要验证。

**结论**：当前实现中 `tryParseInlineTypeAnnotation()` 解析后遇到 `=` / `,` / `)` / 换行 等都会正确终止。但建议增加 UE 风格的集成测试用例。

---

### 🟡 I4 — 泛型参数 `<>` 与 Lua 比较运算符 `<` `>` 的歧义

**问题**：
```lua
local x: MyType<number> = nil   -- 泛型
local y = a < b                  -- 比较
```

`parseInlineTypeSign()` 在 `:` 之后解析类型时看到 `<` 会进入泛型模式。但如果某种情况下 `<` 出现在非类型上下文中：

```lua
if x: number < 10 then  -- ❌ 这不是合法 tlua 语法
```

**结论**：因为 inline 类型标注只在特定注入点（local/param/return）触发 `tryParseInlineTypeAnnotation()`，不会在任意表达式位置出现，所以这个歧义实际上**不存在**。但建议在文档中明确说明 inline 标注的合法位置。

---

### 🟡 I5 — 没有增量更新机制

**问题**：`state.inlineDocs` 每次全量解析都会重新收集。对于 UE5 大型工程（可能有数千个 Lua 文件），全量解析的性能需要关注。

**结论**：LuaLS 本身已有文件级增量更新机制（只重新解析修改的文件），`state.inlineDocs` 是 per-file state，所以不存在跨文件的性能问题。**无需额外处理**。

---

### 🟡 I6 — `void` 类型在 reference doc 中保留但实际已移除

**问题**：之前的会话中已经移除了 `void` 的使用（方案 A），但 `tlua-reference.md` 的类型表和示例中仍然列出了 `void`：
- 第 211 行：`| void | 无返回值（仅用于返回类型） | — |`
- 第 137-139 行：void 使用示例
- 第 263 行：fun() 中的 void 示例

**建议**：要么将 void 从文档中移除，要么保留 void 为合法类型（只是不推荐使用）。需要明确决策。

---

## 三、UE5.6 接入行动计划

### Phase 1：文档 & 规范对齐（1天）
- [ ] 更新 EBNF 增加 `user_type_name` 产生式
- [ ] 更新 reference doc 增加"自定义类型"章节
- [ ] 明确 void 的去留
- [ ] 明确 inline 与 @type 注释共存规则

### Phase 2：Language Server 配置化（2-3天）
- [ ] 增加 `Lua.typingLua.enabled` 配置项
- [ ] 确保 `.lua` 文件在该配置开启时启用 inline 解析
- [ ] 验证 UnLua IntelliSense stub 文件能被正确加载
- [ ] 验证 `self` 类型推断在 UnLua 模式下工作

### Phase 3：运行时类型擦除集成（3-5天）
- [ ] 将 tlua C transpiler 编译为静态库 (`libtlua_strip`)
- [ ] 实现 UnLua 加载层 hook（开发阶段自动 strip）
- [ ] 实现构建管线批量转译（发布阶段）
- [ ] 验证热重载在 strip 模式下正常工作

### Phase 4：UE5 工程集成测试（2-3天）
- [ ] 用真实 UE5 工程测试 hover / completion / go-to-def
- [ ] 测试 UE 类型（AActor, FVector, UWidget 等）的 inline 标注
- [ ] 测试 delegate 绑定的类型提示
- [ ] 性能基准测试（大工程文件数 > 1000）

---

## 四、总结

| 类别 | 发现数 | 阻塞接入？ |
|------|--------|-----------|
| 方案层 P0（文档缺失） | 1 | 否（实现已支持） |
| 方案层 P1-P6（方案缺口/建议） | 6 | P2/P3 需决策，其余不阻塞 |
| 实现层 🔴（需修复） | 2 | I2 需明确规则 |
| 实现层 🟡（建议改进） | 4 | 不阻塞 |

**核心结论**：当前 tlua 方案在**方案层**上与 UE5 Lua 集成没有根本性冲突。最大的决策点是 **P2（文件扩展名策略）** 和 **P3（运行时类型擦除）**。推荐选择 "`.lua` 文件 + 运行时 strip" 路线，最小化对现有 UE5 工程的侵入。
