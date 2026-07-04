# CLAUDE.md

本文件为 Claude Code（claude.ai/code）在此仓库中工作时提供指引。

## 项目概况

CiGA2026 游戏开发大赛参赛作品，一款 **Godot 4.6 2D 解谜平台游戏**。核心机制是**通过时间锚点进行时间操控**：玩家按 Q 键切换时停光标，左键点击放置最多 3 个圆形"时间锚点"，区域内的敌人将被冻结（灰度化 + 蓝色边框）。玩家利用此机制绕开敌人——碰到未冻结的敌人即死亡。

- **引擎**：Godot 4.6，Forward+ 渲染器，Jolt Physics，Direct3D 12（Windows）
- **窗口**：720×480，`canvas_items` 拉伸模式（像素级精确，无视口缩放）
- **语言**：纯 GDScript——无 C#，无插件/扩展
- **仓库**：`https://github.com/jkzhangc/One-more-time-CiGA2026`

## 如何运行

在 Godot 4.6 编辑器中打开 `Game/project.godot`，按 **F5** 即可运行主场景（`Game/scene/test_scene.tscn`）。项目无构建步骤、无 CI、无导出预设。

```
# 命令行方式（前提是 godot 已加入 PATH）：
godot --path Game --editor  # 打开编辑器
godot --path Game            # 直接运行游戏
```

## 输入映射

| 操作     | 按键  | 用途       |
|----------|-------|------------|
| `left`   | A     | 左移       |
| `right`  | D     | 右移       |
| `jump`   | 空格  | 跳跃       |
| `act`    | E     | 交互       |
| `reset`  | R     | 重置       |
| 锚点切换 | Q     | （在 AnchorManager 中硬编码，不在输入映射中） |

## 架构

### 状态机系统（核心骨架）

所有角色——玩家和全部敌人——均使用同一套双类 FSM：

- **`Game/object/State.gd`**（`class_name State extends Node`）：状态基类，提供 `enter()`、`exit()`、`process_update(delta)`、`physics_update(delta)` 虚方法。持有 `character` 引用（所属的 `CharacterBody2D`），并发射 `transition_requested(nxtState: String)` 信号。
- **`Game/object/StateMachine.gd`**（`class_name StateMachine extends Node`）：在 `_ready()` 中扫描子级 `State` 节点，按名称注册到 `states` 字典中，并进入 `initial_state`。将 `_process`/`_physics_process` 委托给当前状态。`_on_transition_requested(nxtState)` 处理退出 → 进入的切换，并跟踪 `last_state`。

**使用模式**：将 `StateMachine` 节点作为任意 `CharacterBody2D` 的子节点。在 StateMachine 下添加具名的 `State` 子节点。状态通过发射 `transition_requested.emit("下一个状态名")` 来切换。父级角色脚本（如 `player.gd`、`enemy_instance.gd`）保持轻量——移动逻辑全部在状态中实现。

### 玩家

- **场景**：`Game/object/player.tscn`——`CharacterBody2D`，碰撞层 2（玩家），掩码 13（图块+敌人+杂项）。包含 `AnimatedSprite2D`、`Camera2D`（位置/旋转平滑）、`CollisionShape2D`（34×50）、`Area2D`（45×58，敌人检测）和一个 `StateMachine` 子节点。
- **脚本**：`Game/script/player.gd`——处理 `_on_area_2d_body_entered(body)`：检查重叠敌人的状态是否为 `"Freeze"`；若是，玩家安全；若否，玩家发射 `hit` 信号并 `hide()`（死亡）。`start(pos)` 重置位置并进入 `"Idle"`。
- **状态**（3 个）：
  - `Idle`（`Game/script/PlayerIdleState.gd`）——速度归零，施加重力，有输入时切换到 Walk/Jump
  - `Walk`（`Game/object/PlayerWalkState.gd`）——通过 `Input.get_axis` 实现 150 px/s 的水平移动
  - `Jump`（`Game/object/PlayerJumpState.gd`）——进入时 `velocity.y = -450`，空中可 150 px/s 水平控制，落地后返回 Walk/Idle

### 敌人

所有敌人都继承自 **`Game/object/enemy_instance.gd`**（`CharacterBody2D`），提供了 `anim_sprite` 引用、`mode`（int）、导出变量 `typename`（String）和 `random_direction()` 辅助方法。每种敌人都有一个 `StateMachine` 子节点，包含类型专属的状态以及共享的 `Freeze` 状态。

**Enemy1 — 移动平台**：`Game/object/移动平台.tscn` + `Game/object/enemy_1_base.gd`（Node2D 包装器）。可配置的运动模式：`Move_updown`（垂直振荡）、`Move_leftright`（水平振荡）、`Move_circumference`（圆周运动）。包装器在 `_ready()` 中将导出的速度/时间参数注入子状态。初始状态通过 `enemy_1_base.gd` 的导出变量设置。

**Enemy2 — 形态类怪物**：`Game/object/Enemy2.tscn` + `Game/object/enemy_2_base.gd`（占位脚本）。以 3 秒为周期在 3 种形态间循环：Normal → MiddleJump（中形态）→ HighJump（高形态）→ 返回 MiddleJump → Normal。拥有 12 帧美术资源，分布在 5 个动画轨道中；使用 `play_backwards()` 实现逆向变形过渡。

**Enemy3 — 冲锋类怪物**：`Game/object/Enemy3.tscn`（裸 Node2D，无包装脚本）。最简单的敌人——朝一个方向移动，每 3 秒反转 `velocity.x`。状态：`Enemy3_NormalState`、`Freeze`。

**共享的冻结状态**：`Game/object/EnemyFreezeState.gd`——基于计时器，计时结束后切回 `last_state`。⚠️ **已知 bug**：代码中发射 `transition_requested.emit(last_state)` 传递的是 `State` 对象，但 `StateMachine._on_transition_requested` 期望接收 `String`（状态名称）。

### 时间锚点系统（核心玩法）

**`Game/script/AnchorManager.gd`**——挂载在 `test_scene.tscn` 的根节点上。非 autoload。

- 按 **Q** 键（或 UI 按钮）切换：激活/停用一个跟随鼠标的指示器。
- **左键点击**放置固定锚点（最多 3 个）。每个锚点执行 Tween 驱动的生命周期：展开（0.2s）→ 保持 → 频闪（0.5s 预警）→ 收缩（0.2s）→ 移除。
- 放置时，执行 `_detect_and_modify_state()`——在锚点位置进行 `PhysicsShapeQueryParameters2D` 圆形查询。对检测到的敌人调用 `apply_gray_state(duration)`。

**`Game/shader/bw_mask.gdshader`**——应用于全屏 `ColorRect`（CanvasLayer #2）的 `canvas_item` 着色器。将鼠标圆形区域和固定锚点圆形区域内的像素去饱和（灰度化），并附带蓝色抗锯齿边框（`border_width=3px`）。Uniform 变量：`mouse_pos`、`mouse_radius`、`is_active`、`fixed_pos_1/2/3`、`fixed_scale_1/2/3`、`fixed_radius`。

⚠️ **已知缺陷**：`apply_gray_state()` / `apply_anchor_state()` 在任何敌人脚本中均未实现——AnchorManager 到敌人冻结状态的衔接管道尚未完成。

### 物理层与渲染层

| 层 | 物理层         | 渲染层       |
|----|---------------|-------------|
| 1  | 图块           | 背景         |
| 2  | 玩家           | 图块         |
| 3  | 敌人           | 玩家         |
| 4  | 杂项物体       | 敌人         |
| 5  | （未使用）      | UI           |

玩家：`collision_layer=2`，`collision_mask=13`（1+4+8 = 图块+敌人+杂项）。敌人的碰撞层各不相同——Enemy2 使用第 4 层（敌人），Enemy1 使用第 8 层（杂项）。

## 文件布局约定

脚本分散在两个目录中，存在一定的不一致：

- `Game/script/`——player.gd、玩家状态、AnchorManager、Enemy1 移动状态、enemy2 middle jump
- `Game/object/`——FSM 框架（State.gd、StateMachine.gd）、玩家 Walk/Jump 状态、所有敌人场景和基类脚本、冻结状态、Enemy2/Enemy3 普通状态

新增脚本时，建议：与具体对象相关的脚本放在 `Game/object/` 中靠近其 `.tscn` 的位置；管理/工具类脚本放在 `Game/script/` 中。

⚠️ `.uid` 文件是 Godot 的资源引用系统——如果重命名/移动 `.gd` 或 `.tscn` 文件，需同时重命名/移动其 `.uid` 文件，或者删除它，让 Godot 在下次打开时重新生成。

## 策划案摘要（来源：`CIGA GJ 策划案/CIGA GJ 策划案.md`）

### 一句话玩法
玩家在指定位置放置"时间锚点"，使圆形范围内的怪物暂时停止行动。玩家利用被冻结的怪物作为平台、弹跳机关或解谜工具，到达关卡终点。

### 世界观
玩家是"时律行者"，手持上古遗物「时间锚点」。在危机四伏的遗迹中，万物依循时间法则运转，而玩家是唯一能违背法则的存在。按下 Q 键以罗盘为中心张开"绝对静止域"，域内万物瞬间凝固。

### 玩家规则
- **操作**：A/D 左右移动，Space 跳跃，Q 时停，E 开宝箱，R 重置，Esc 暂停
- **不能二段跳**
- **不能踩怪物**——碰怪物掉血（初始 3 滴血）
- 碰到机关掉血
- 掉坑或死亡后从关卡初始位置复活
- 玩家死亡后，时停和怪物状态全部重置

### 时停规则
- 怪物在圆圈范围内即被冻结，冻结后仍有碰撞
- 允许同时冻结多个怪物
- 时停结束前有闪烁提示（已实现）
- ⚠️ **玩家站在被冻结怪物上，解冻后会掉 1 滴血**

### 各敌人交互规则（策划案）

| 敌人类型 | 交互规则 |
|----------|----------|
| **移动平台** | 暂未详述 |
| **形态类怪物** | ⚠️ **弹跳功能只有被冻结后才生效**（策划案原话） |
| **冲锋类怪物** | 冻结后不会造成伤害；释放后可利用惯性触碰机关开门 |
| **宝箱** | 靠近后按 E 打开 |
| **动态开关** | 只有玩家踩才触发 |
| **投掷物** | 锚定规则（未详述） |

### 危险机关
- **锯齿带**：参考 `图片和附件/image.png`
- **尖刺柱**：锚定范围比图中小，参考 `图片和附件/image 1.png`

### 关卡流程（策划案）
1. **基础**：冻结移动怪当踏板
2. **进阶**：冻结花怪（形态类怪物）全开状态当高台——引入状态判断
3. **拓展**：冻结冲锋兽，释放后利用其惯性触碰机关开门
4. 参考图：`图片和附件/6fb07c969a23d882375e4b4b1c4badbb.png`

### 美术方向
- **整体基调**：永恒黄昏、寂静废墟、微光魔法；情绪：孤独、神秘、唯美、略带忧伤
- **主色调**：深紫罗兰 + 灰蓝 + 墨绿（停滞的世界）
- **高亮色**：暖橙/落日黄（希望、光源）、荧光青/冰蓝（时停力量、水晶）
- **主角色**：炭黑/深灰（剪影感）+ 金属金/铜（罗盘发光处）
- **时停表现**：半透明青色光球，内部物体表面结满冰霜，周围静止尘埃粒子
- **光影**：强对比度体积光（丁达尔效应），主角周围有温暖光晕
- **角色**：黑色剪影小人，手持散发金色光芒的罗盘/沙漏，跳跃时有拉伸感

### ⚠️ 策划案与当前代码的差异
- 策划案说形态类怪物弹跳"只有被冻结后才生效"，但当前 `player.gd` 实现为：跳跃状态（MiddleJump/HighJump）下无论是否冻结都会弹跳。需与策划确认。
- 策划案提到玩家有 3 滴血（HP 系统），当前代码中玩家碰到未冻结敌人直接死亡（`hit` → `hide`），无血量系统。
- 策划案提到玩家站在冻结怪物上解冻后掉 1 滴血，当前未实现。
