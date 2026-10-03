# 独立 WordPress 开发站

## 已验证的环境

2026-10-03，已在当前云开发环境安装 WordPress 7.1.2（与学校页面标示版本相同）、PHP 8.3、MariaDB 11.4，启用 Twenty Twenty-Five。前台、后台登录、页面区块编辑器均通过功能检查。邮件服务未配置，不可依赖邮件通知或邮件重置密码。

这是当前云环境内的开发站，尚未申请独立托管账号，也没有固定公网网址。它不替代学校站点，不能将当前运行进程当作长期托管服务。用户从学校或家里直接登录需要另选可访问的托管环境。

## 启动与检查（云端助手）

使用现有 `/workspace/WordPress_DD` checkout，不另建 worktree。准备文件与随机开发凭据：

```sh
python3 /workspace/WordPress_DD/dev/wordpress/prepare.py
cd /workspace/wordpress-dev
docker compose pull
docker compose up -d --wait
python3 verify.py
```

已有站点只需启动并验证。如果原有数据丢失，应先按 [BACKUP_RESTORE.md](BACKUP_RESTORE.md) 恢复备份，不要自动初始化空站。`bootstrap.py` 仅用于明确要求创建全新空站的场景。`docker compose up -d --wait` 等待数据库健康。新站首次初始化时会创建随机命名的开发账号。用户名位于仓库外的 `admin-username.txt`。随机密码位于仓库外的 `/workspace/wordpress-dev/admin-password.txt`，不得输出到日志、复制到文档或提交到 GitHub。现有数据库和凭据会保留。学校账号不用于此站。

开发服务仅绑定本机端口 8080；通过当前执行环境内的浏览器或内部请求验证。正式托管前需要配置固定域名、HTTPS、备份和有效邮件服务；不能直接把此开发配置当作公网部署配置。

## 保存与恢复

- `/workspace/wordpress-dev/site`：WordPress 文件、主题和上传媒体。
- `/workspace/wordpress-dev/database`：MariaDB 数据。
- `/workspace/wordpress-dev/.env`：随机数据库凭据。
- GitHub 的 `dev/wordpress/`：可复用的配置与检查脚本，不含数据库、媒体或凭据。

仅推送 GitHub 不能保存网站的全部状态。云环境发布与文件恢复由平台管理，当前仅验证本实例运行与 WordPress 容器重启，未验证新云任务恢复。完整备份／恢复使用 [BACKUP_RESTORE.md](BACKUP_RESTORE.md) 的脚本。当前站点已在独立目录中做过恢复验证，但未验证平台自动跨任务恢复。下载并独立保管备份才是环境删除后的恢复依据。不要执行 `docker compose down -v` 或删除数据目录来处理问题。

## 后续迁移到学校站点

1. 优先使用原生区块和学校已有的 Twenty Twenty-Five，减少新增插件依赖；学校安装的 Stackable 功能需要另行确认开发站和目标站版本兼容性。
2. 制作期间把实际采用的原稿、设计决定和页面结构保存到 GitHub，同时保存开发站自身的数据备份。
3. 单个页面可在 WordPress 代码编辑器复制区块标记，再粘贴到学校站点的新草稿；图片仍需上传并替换引用，不能依赖开发站的本机媒体地址。
4. 多个页面／文章可通过 WordPress「工具 → 导出」生成内容文件，在学校站点使用允许的导入工具。主题模板、全局样式、导航、插件配置不一定随内容导出，需要单独迁移或重建。
5. 移植后先核对草稿、图片、手机端、菜单和链接，再按用户指示发布。不要覆盖学校已有页面或更改固定首页，除非该操作属于明确的当前任务。
