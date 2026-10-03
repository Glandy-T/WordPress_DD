# WordPress 备份与恢复

当前数据库和 `wp-content` 在 `/workspace/wordpress-dev/` 的目录挂载中。容器重启可以保留数据；没有证据保证云机器重建或删除后仍保留最新数据。GitHub 仅保存脚本与文档。**只有把备份下载并另存到云环境之外，才能在当前机器丢失后恢复。**

## 备份

在仓库目录运行：

```sh
./scripts/backup.sh
```

脚本暂时停止 WordPress（数据库继续运行），以避免打包过程中页面或媒体发生变化；导出 MariaDB 中的 WordPress 数据库、打包 `wp-content`，完成或失败后恢复原先运行的网站服务。会产生：

```text
backups/wordpress-日期时间-随机后缀.tar.gz    ← 下载并保存这个完整文件
backups/wordpress-日期时间-随机后缀/        ← 本次备份的组成文件
  database.sql.gz
  wp-content.tar.gz
  manifest.json
  wordpress-version.txt
  SHA256SUMS
```

数据库包含页面、文章、菜单、设置、全局样式、用户等 WordPress 表；`wp-content` 包含媒体、主题和插件。清单记录版本、镜像摘要和当时的 Git 提交，校验和用于发现文件损坏。不包含 MariaDB 系统账号、`.env`、`wp-config.php` 或本地凭据文件。恢复时重建这些运行配置。

按本项目当前要求，备份**不加密**，数据库仍包含私人用户资料和密码哈希，插件数据也可能含敏感信息。把它作为私人文件保管，不上传 GitHub、公开网盘或聊天记录。此版本只恢复普通文件和目录；包含符号链接的 `wp-content` 会被恢复检查拒绝。

## 下载与保存

下载完整的 `backups/wordpress-….tar.gz`，不是只下载 SQL 或 `wp-content`。保存在你的电脑独立备份目录，建议另外保留一份在自己已有的私人存储或移动硬盘。无需注册或购买服务。

可从云任务的文件访问界面获取备份；若客户端不能直接下载云文件，需要使用客户端提供的文件导出方式。聊天中会提供实际文件路径，但路径本身不是云外副本。确认下载完成及文件大小一致后，才能依赖它应对云环境删除。

每次重要修改完成、离开工作环境或重建前运行一次。脚本不会自动执行，也不会自动上传。保留至少最近三份；目前未配置自动异地备份。

## 在全新云开发环境恢复

前提：现有 GitHub 项目 checkout、Docker / Docker Compose、Bash、Python 3、tar、gzip、sha256sum 可用，且能获取 Docker 官方镜像。无需旧数据库密码。

1. 获取 GitHub 仓库的最新脚本。参考备份清单中的版本信息，不要重置或覆盖未提交的项目工作。
2. 把自己保存的完整备份上传到新环境的仓库 `backups/` 目录。
3. 确保目标 `/workspace/wordpress-dev` 没有旧数据库、网站或凭据，同名 Compose 项目也不存在。
4. 在仓库目录执行：

```sh
./scripts/restore.sh backups/wordpress-日期时间-随机后缀.tar.gz
```

恢复脚本先校验包内路径、文件类型、完整性及格式，再使用备份记录的官方镜像摘要启动新数据库、导入数据、恢复 `wp-content`。原有管理员身份保留，但其密码会重置为新随机密码，旧登录会话失效。新的本地凭据保存在恢复目录的 `admin-username.txt` 和 `admin-password.txt`，不会输出到终端或 GitHub。其他数据库内用户资料按备份保留。

恢复后检查前台、管理员登录和页面区块编辑器；再人工核对关键页面、菜单、媒体与设置。默认复用本机端口 8080。若以后更换域名或端口，脚本只更新 `siteurl` / `home`，正文和插件配置中的历史绝对 URL 需另外正确替换，不能盲目 SQL 替换序列化值。

## 在已有环境做隔离恢复

为了保护当前站点，恢复脚本拒绝覆盖现有数据，也拒绝复用已有 Compose 项目。可指定新的目录、项目名和端口：

```sh
WP_DEV_DIR=/workspace/wordpress-restored \
WP_COMPOSE_PROJECT=wordpress-dd-restored \
WP_DEV_PORT=8081 \
./scripts/restore.sh backups/wordpress-日期时间-随机后缀.tar.gz
```

隔离站后续启动：

```sh
cd /workspace/wordpress-restored
docker compose up -d --wait
python3 verify.py
```

`WP_DEV_DIR` 和 `WP_COMPOSE_PROJECT` 也可用于备份指定的隔离站。恢复失败后的目标数据会保留供检查；不要覆盖它重试，应诊断后选择另一个空目标目录。

## GitHub 保存范围

提交脚本、Compose 配置、环境与恢复说明。不提交 `backups/`、数据库、媒体备份、`.env`、`wp-config.php`、账号和密码文件。`.gitignore` 只防止 Git 客户端误添加；网页上传仍需自行排除，已提交的敏感文件不能靠 ignore 删除历史。
