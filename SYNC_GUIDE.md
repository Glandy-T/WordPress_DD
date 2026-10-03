# 学校与家里的电脑同步指南

GitHub 是共享保存位置；两台电脑各自保留一个克隆目录。一次只在一台电脑上修改，开始前拉取，结束后推送。不要把密码、验证码、API 密钥或数据库备份放进仓库。

## 第一次使用：GitHub Desktop（推荐）

1. 安装 GitHub Desktop，登录有权访问此仓库的 GitHub 账号。
2. 选择 **File → Clone repository → URL**，输入 `https://github.com/Glandy-T/WordPress_DD`。
3. 选择自己的本地保存位置。家里的电脑可以选择 `E:\GitHub`，得到 `E:\GitHub\WordPress_DD`。不要克隆到已经放有旧文件的 `E:\WordPress` 内。
4. 学校电脑也克隆同一仓库。若电脑重启会清除本地文件，每次上课重新克隆即可，前提是上次修改已经推送。
5. 之后从克隆目录打开文档并编辑。旧的 `E:\WordPress` 可作为本地备份，确认 GitHub 上的文件齐全后再决定如何处理。

## 每次工作

1. 打开 GitHub Desktop，选择 `WordPress_DD`。
2. 点击 **Fetch origin**，有更新时点击 **Pull origin**。
3. 编辑原稿或设计笔记；更新 `TASKS.md` 和 `LOG.md`，区分计划、已完成和未经确认的状态。
4. 回到 Desktop 的 **Changes**，逐个确认本次文件，不提交账号文件和临时文件。
5. 填写提交说明，例如“补充一年级科目原稿”，点击 **Commit to main**。
6. 点击 **Push origin**，等待成功；在 GitHub 页面确认最新提交已经出现，再离开电脑。

**Commit 只保存在当前电脑，Push 才会同步到 GitHub。** GitHub Desktop 的菜单随版本可能略有差异。学校公用电脑使用后退出账号，不保存密码。

## 命令行方式

首次克隆（在你选择的父目录执行）：

```sh
git clone https://github.com/Glandy-T/WordPress_DD.git
cd WordPress_DD
```

开始工作（在仓库目录）：

```sh
git status
git pull --ff-only origin main
```

结束工作：

```sh
git status
git diff
# 只添加本次准备提交的文件；下面是一个例子。
git add CONTENT/COURSE_CATALOG.md TASKS.md LOG.md
git diff --cached
git commit -m "更新课程原稿与进度记录"
git push origin main
```

如果 pull 提示本地修改或无法 fast-forward，先保留当前改动并查看双方差异，不要使用 `reset --hard` 或强制推送。发生冲突时按文件合并两边内容，确认没有丢失后再提交。

## WordPress 与资料仓库的关系

这里保存入稿前的内容与操作记录。WordPress 管理后台里的页面、主题配置、数据库和上传图片不会随 Git 自动同步；WordPress 内容导出和完整网站备份是另外的工作。发布页面后，应把最终原稿和实际操作记录同步到仓库。

`.gitignore` 防止指定文件被意外新增，但不能清除已经提交过的密码。误提交真实凭据时，应立即更换凭据并清理历史。

## 云端继续工作

使用 `/workspace/WordPress_DD` 的现有 checkout；云任务本身已隔离，不需要另建 Git worktree。先检查 `git status`，再阅读 README、TASKS、DESIGN_NOTES 和最新 LOG。这是文档仓库，当前不需要 npm、PHP、数据库或启动 Web 服务。历史日志中的网站状态需要另行核实，不能当作当前在线验证结果。
