# 隐私政策页面发布说明

当前目录可直接作为静态隐私政策页面发布。

## 推荐链接

如果你使用 GitHub Pages 部署本仓库的 `docs/` 目录，建议链接使用：

`https://bluedeer000.github.io/HarmonyCalendar/privacy-policy/`

## 注意

当前仓库是私有仓库。GitHub Pages 是否可直接用于私有仓库，取决于当前账号套餐与 Pages 权限设置。

如果你不想公开整个仓库，也可以把 `index.html` 部署到其他静态托管服务，并把对应 HTTPS 地址填到 AppGallery Connect。

## 当前结论

已尝试通过 GitHub API 为当前私有仓库启用 Pages，返回结果为：

- `Your current plan does not support GitHub Pages for this repository.`

这意味着当前最直接的可行方案有两个：

1. 将仓库改为公开仓库，然后使用 `release/appgallery` 分支的 `docs/` 目录启用 GitHub Pages。
2. 保持仓库私有，但把 `docs/privacy-policy/index.html` 部署到其他公开静态托管服务。
