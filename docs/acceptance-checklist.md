# 验收复现清单

本清单对应项目验收要求，所有本地命令均在仓库根目录执行。

| 要求 | 仓库证据 | 复现方式 |
| --- | --- | --- |
| MoonBit 主实现语言 | `.mbt` 源码、`moon.mod` | `python tools/check_moonc_version.py --minimum 0.10.14` |
| 公开仓库与清晰提交 | GitHub `2200732518gjy/moonstix`、分阶段提交 | `git log --oneline --decorate` |
| 核心功能 | ID、时间戳、对象校验、关系、Sighting、模式解析 | `moon check --target wasm-gc --deny-warn` |
| README 与可复现说明 | `README.md`、`README.mbt.md` | 按 README 安装和运行示例 |
| 持续集成 | `.github/workflows/ci.yml` | GitHub Actions 自动执行格式、检查、构建、测试、示例 |
| 可运行样例 | `examples/parse_bundle`、`validate_indicator`、`sighting_graph` | `moon run examples/<name> --target wasm-gc` |
| 核心测试 | `*_test.mbt`、`*_wbtest.mbt` | `moon test --target wasm-gc` |
| MoonCakes 发布 | 由项目维护者在最终确认后手动执行 | 本次维护不自动发布 |
| 开源许可 | `LICENSE`、`moon.mod` | Apache-2.0，依赖为 MoonBit core |

## 一次性本地验收

```bash
python tools/check_moonc_version.py --minimum 0.10.14
python tools/count_effective_moonbit.py --check-core 2000
moon fmt --check
moon check --target wasm-gc --deny-warn
moon check --target wasm --deny-warn
moon check --target js --deny-warn
moon check --target native --deny-warn
moon build --target wasm-gc --deny-warn
moon test --target wasm-gc
moon test --target js
moon test --target native
moon run examples/parse_bundle --target wasm-gc
moon run examples/validate_indicator --target wasm-gc
moon run examples/sighting_graph --target wasm-gc
```
